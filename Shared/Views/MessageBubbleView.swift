import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name (for received messages)
                if !message.isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                // Message content
                VStack(alignment: .leading, spacing: 8) {
                    // Drawing placeholder (if any)
                    if message.drawingData != nil {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 120)
                            .overlay {
                                Image(systemName: "scribble")
                                    .foregroundStyle(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Text
                    if let text = message.text, !text.isEmpty {
                        Text(text)
                            .foregroundStyle(message.isFromCurrentUser ? .white : .primary)
                    }
                }
                .padding(12)
                #if os(macOS)
                .background(message.isFromCurrentUser ? Color.blue : Color(nsColor: .controlBackgroundColor))
                #else
                .background(message.isFromCurrentUser ? Color.blue : Color(.systemGray5))
                #endif
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    VStack {
        MessageBubbleView(message: Message(
            senderID: "1",
            senderName: "Alice",
            roomID: "A",
            text: "Hello there!",
            isFromCurrentUser: false
        ))

        MessageBubbleView(message: Message(
            senderID: "2",
            senderName: "Me",
            roomID: "A",
            text: "Hey! How are you?",
            isFromCurrentUser: true
        ))
    }
    .padding()
}
