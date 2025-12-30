import Foundation
@preconcurrency import MultipeerConnectivity

struct Peer: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let mcPeerID: MCPeerID

    init(mcPeerID: MCPeerID) {
        // Use mcPeerID's hash as unique identifier to distinguish peers with same display name
        self.id = "\(mcPeerID.displayName)-\(mcPeerID.hash)"
        self.displayName = mcPeerID.displayName
        self.mcPeerID = mcPeerID
    }

    static func == (lhs: Peer, rhs: Peer) -> Bool {
        // Compare using mcPeerID directly for accurate equality
        lhs.mcPeerID == rhs.mcPeerID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(mcPeerID)
    }
}
