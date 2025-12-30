import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RoomSelectionView: View {
    @Environment(MultipeerService.self) private var multipeerService
    let onRoomSelected: (ChatRoom) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.pink.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Glass Header
                ZStack {
                    VStack(spacing: 8) {
                        Text("LocalChat")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Select a Room")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Spacer()
                        Button {
                            openSettings()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 20)
                .background(.ultraThinMaterial)

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
                    .padding(.top, 20)
                    .padding(.bottom, 80)
                }

                // Glass Footer
                Text("Nearby users will appear automatically")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
            }
        }
        #if os(macOS)
        .frame(minWidth: 300, minHeight: 400)
        #else
        .navigationBarHidden(true)
        #endif
    }

    private func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

struct RoomButton: View {
    let room: ChatRoom
    let peerCount: Int
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(room.rawValue)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

                HStack(spacing: 4) {
                    if peerCount > 0 {
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 6, height: 6)
                        Text("\(peerCount) \(peerCount == 1 ? "user" : "users")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.95))
                    } else {
                        Text("Empty")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background {
                ZStack {
                    // Main gradient
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    roomColor(room.color),
                                    roomColor(room.color).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Glass overlay
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.15))
                        .blur(radius: 0.5)

                    // Inner highlight
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private func roomColor(_ color: RoomColor) -> Color {
        switch color {
        case .blue: return Color(red: 0.2, green: 0.5, blue: 1.0)
        case .green: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .orange: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .purple: return Color(red: 0.6, green: 0.3, blue: 0.9)
        case .red: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .teal: return Color(red: 0.2, green: 0.7, blue: 0.8)
        case .pink: return Color(red: 1.0, green: 0.4, blue: 0.6)
        case .yellow: return Color(red: 1.0, green: 0.8, blue: 0.2)
        }
    }
}

#Preview {
    RoomSelectionView(onRoomSelected: { _ in })
        .environment(MultipeerService())
}
