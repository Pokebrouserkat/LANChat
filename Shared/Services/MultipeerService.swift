import Foundation
import SwiftUI
@preconcurrency import MultipeerConnectivity

@MainActor
@Observable
final class MultipeerService: NSObject, @unchecked Sendable {
    // MARK: - Public Properties

    private(set) var discoveredPeers: [ChatRoom: [Peer]] = [:]
    private(set) var connectedPeers: [Peer] = []
    private(set) var currentRoom: ChatRoom?
    private(set) var connectionState: ConnectionState = .disconnected

    var onMessageReceived: ((MessagePayload) -> Void)?

    enum ConnectionState: Sendable {
        case disconnected
        case waiting      // In room, but alone
        case connecting   // Actively connecting to peers
        case connected    // Connected to at least one peer
    }

    // MARK: - Private Properties

    private let serviceType = "local-chat"
    private let peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private let userProfile: UserProfile

    // Thread-safe session reference for delegate callbacks
    private let sessionLock = NSLock()
    private nonisolated(unsafe) var _threadSafeSession: MCSession?

    private nonisolated func getThreadSafeSession() -> MCSession? {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        return _threadSafeSession
    }

    private func setThreadSafeSession(_ session: MCSession?) {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        _threadSafeSession = session
    }

    // MARK: - Initialization

    override init() {
        self.userProfile = UserProfile()
        self.peerID = MCPeerID(displayName: userProfile.displayName)
        super.init()
        startBrowsing()
    }

    // MARK: - Public Methods

    func joinRoom(_ room: ChatRoom) {
        leaveCurrentRoom()
        currentRoom = room

        // Create session
        let newSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        newSession.delegate = self
        session = newSession
        setThreadSafeSession(newSession)

        // Start advertising for this room
        let discoveryInfo = ["room": room.rawValue]
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        // Connect to existing peers in this room
        let peersInRoom = discoveredPeers[room] ?? []
        if peersInRoom.isEmpty {
            connectionState = .waiting
        } else {
            connectionState = .connecting
            connectToPeersInRoom(room)
        }
    }

    func leaveCurrentRoom() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        session?.disconnect()
        session = nil
        setThreadSafeSession(nil)
        currentRoom = nil
        connectedPeers = []
        connectionState = .disconnected
    }

    func sendMessage(_ payload: MessagePayload) throws {
        guard let session = session, !session.connectedPeers.isEmpty else {
            return
        }

        let data = try JSONEncoder().encode(payload)
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    func getPeerCount(for room: ChatRoom) -> Int {
        discoveredPeers[room]?.count ?? 0
    }

    // MARK: - Private Methods

    private func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    private func connectToPeersInRoom(_ room: ChatRoom) {
        guard let session = session else { return }

        if let peers = discoveredPeers[room] {
            for peer in peers {
                browser?.invitePeer(peer.mcPeerID, to: session, withContext: nil, timeout: 30)
            }
        }
    }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                let peer = Peer(mcPeerID: peerID)
                if !self.connectedPeers.contains(peer) {
                    self.connectedPeers.append(peer)
                }
                self.connectionState = .connected
            case .connecting:
                if self.connectionState != .connected {
                    self.connectionState = .connecting
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0.mcPeerID == peerID }
                if self.connectedPeers.isEmpty && self.currentRoom != nil {
                    self.connectionState = .waiting
                }
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                let payload = try JSONDecoder().decode(MessagePayload.self, from: data)
                self.onMessageReceived?(payload)
            } catch {
                print("Failed to decode message: \(error)")
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used
    }

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used
    }

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Access session synchronously to avoid data race
        let session = getThreadSafeSession()
        invitationHandler(true, session)
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            guard let roomString = info?["room"],
                  let room = ChatRoom(rawValue: roomString) else {
                return
            }

            let peer = Peer(mcPeerID: peerID)

            if self.discoveredPeers[room] == nil {
                self.discoveredPeers[room] = []
            }

            if !self.discoveredPeers[room]!.contains(peer) {
                self.discoveredPeers[room]!.append(peer)
            }

            // If this is our current room, invite the peer
            if room == self.currentRoom, let session = self.session {
                if self.connectionState == .waiting {
                    self.connectionState = .connecting
                }
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            for room in ChatRoom.allCases {
                self.discoveredPeers[room]?.removeAll { $0.mcPeerID == peerID }
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error)")
    }
}
