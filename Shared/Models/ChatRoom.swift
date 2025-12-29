import Foundation

enum ChatRoom: String, CaseIterable, Identifiable, Codable, Sendable {
    case A, B, C, D, E, F, G, H

    var id: String { rawValue }

    var displayName: String {
        "Room \(rawValue)"
    }

    var color: RoomColor {
        switch self {
        case .A: return .blue
        case .B: return .green
        case .C: return .orange
        case .D: return .purple
        case .E: return .red
        case .F: return .teal
        case .G: return .pink
        case .H: return .yellow
        }
    }
}

enum RoomColor: Sendable {
    case blue, green, orange, purple, red, teal, pink, yellow
}
