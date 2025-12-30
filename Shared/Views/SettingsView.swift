import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage("LocalChat.displayName") private var displayName = ""
    @State private var deleteConfirmation: DeleteConfirmation?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    struct DeleteConfirmation: Identifiable {
        let id = UUID()
        let room: ChatRoom?

        var title: String {
            if let room = room {
                return "Delete Room \(room.rawValue)?"
            }
            return "Delete All Messages?"
        }

        var message: String {
            if let room = room {
                return "All messages in Room \(room.rawValue) will be permanently deleted from your device."
            }
            return "All messages will be permanently deleted from your device."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Display Name section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        TextField("Enter your name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Delete by Room section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Delete Messages")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ChatRoom.allCases) { room in
                                DeleteRoomButton(room: room) {
                                    deleteConfirmation = DeleteConfirmation(room: room)
                                }
                            }
                        }

                        Button {
                            deleteConfirmation = DeleteConfirmation(room: nil)
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete All Messages")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Text("Messages are only deleted from your device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 400, height: 520)
        .background(.ultraThinMaterial)
        .alert(item: $deleteConfirmation) { confirmation in
            Alert(
                title: Text(confirmation.title),
                message: Text(confirmation.message),
                primaryButton: .destructive(Text("Delete")) {
                    if let room = confirmation.room {
                        deleteMessages(for: room)
                    } else {
                        deleteAllMessages()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func deleteMessages(for room: ChatRoom) {
        let roomID = room.rawValue
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.roomID == roomID }
        )

        do {
            let messages = try modelContext.fetch(descriptor)
            for message in messages {
                modelContext.delete(message)
            }
            try modelContext.save()
        } catch {
            print("Failed to delete messages for room \(room.rawValue): \(error)")
        }
    }

    private func deleteAllMessages() {
        let descriptor = FetchDescriptor<Message>()

        do {
            let messages = try modelContext.fetch(descriptor)
            for message in messages {
                modelContext.delete(message)
            }
            try modelContext.save()
        } catch {
            print("Failed to delete all messages: \(error)")
        }
    }
}

struct DeleteRoomButton: View {
    let room: ChatRoom
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(room.rawValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(isHovered ? 0.2 : 0.1))
                    }
            }
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
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
    SettingsView()
        .modelContainer(for: Message.self, inMemory: true)
}
