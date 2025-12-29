import Foundation
@preconcurrency import MultipeerConnectivity

struct Peer: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let mcPeerID: MCPeerID

    init(mcPeerID: MCPeerID) {
        self.id = mcPeerID.displayName
        self.displayName = mcPeerID.displayName
        self.mcPeerID = mcPeerID
    }

    static func == (lhs: Peer, rhs: Peer) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
