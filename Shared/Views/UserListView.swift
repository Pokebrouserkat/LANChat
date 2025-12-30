import SwiftUI

struct UserListView: View {
    @Environment(\.dismiss) private var dismiss
    let peers: [Peer]

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.15),
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if peers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .padding()
                            .background(.ultraThinMaterial, in: Circle())

                        Text("No Users Connected")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Waiting for others to join this room")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(peers) { peer in
                                HStack(spacing: 14) {
                                    // Avatar
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.blue, .blue.opacity(0.7)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)

                                        Text(String(peer.displayName.prefix(1)).uppercased())
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    .shadow(color: .black.opacity(0.1), radius: 3, y: 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(peer.displayName)
                                            .font(.body)
                                            .fontWeight(.medium)

                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(.green)
                                                .frame(width: 6, height: 6)
                                            Text("Connected")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Connected Users")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        #if os(iOS)
        .presentationBackground(.ultraThinMaterial)
        .presentationCornerRadius(32)
        #endif
        #if os(macOS)
        .frame(minWidth: 300, minHeight: 400)
        #endif
    }
}

#Preview {
    UserListView(peers: [])
}
