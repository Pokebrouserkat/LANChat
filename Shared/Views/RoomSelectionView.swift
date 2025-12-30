import SwiftUI

struct RoomSelectionView: View {
    @Environment(MultipeerService.self) private var multipeerService
    let onRoomSelected: (ChatRoom) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("LocalChat")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Select a Room")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 24)

            // Room Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(ChatRoom.allCases) { room in
                        RoomButton(
                            room: room,
                            peerCount: multipeerService.getPeerCount(for: room),
                            action: { onRoomSelected(room) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }

            // Footer
            Text("Nearby users will appear automatically")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 20)
        }
        #if os(macOS)
        .frame(minWidth: 300, minHeight: 400)
        #else
        .navigationBarHidden(true)
        #endif
    }
}

struct RoomButton: View {
    let room: ChatRoom
    let peerCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(room.rawValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if peerCount > 0 {
                    Text("\(peerCount) \(peerCount == 1 ? "user" : "users")")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text("Empty")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(roomColor(room.color))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: roomColor(room.color).opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func roomColor(_ color: RoomColor) -> Color {
        switch color {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .red: return .red
        case .teal: return .teal
        case .pink: return .pink
        case .yellow: return .yellow
        }
    }
}

#Preview {
    RoomSelectionView(onRoomSelected: { _ in })
        .environment(MultipeerService())
}
