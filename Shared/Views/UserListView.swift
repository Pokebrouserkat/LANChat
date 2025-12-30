import SwiftUI

struct UserListView: View {
    @Environment(\.dismiss) private var dismiss
    let peers: [Peer]

    var body: some View {
        NavigationStack {
            List {
                if peers.isEmpty {
                    ContentUnavailableView(
                        "No Users Connected",
                        systemImage: "person.slash",
                        description: Text("Waiting for others to join this room")
                    )
                } else {
                    ForEach(peers) { peer in
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text(peer.displayName)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Connected Users")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 300, minHeight: 400)
        #endif
    }
}

#Preview {
    UserListView(peers: [])
}
