import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct MessageBubbleView: View {
    let message: Message
    var roomColor: Color = .blue
    var onDelete: (() -> Void)?

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name (for received messages)
                if !message.isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }

                // Message content
                VStack(alignment: .leading, spacing: 8) {
                    // Image attachment (if any)
                    if let imageData = message.drawingData {
                        #if canImport(UIKit)
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 240, maxHeight: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        #elseif canImport(AppKit)
                        if let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 240, maxHeight: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        #endif
                    }

                    // Text
                    if let text = message.text, !text.isEmpty {
                        Text(text)
                            .foregroundStyle(message.isFromCurrentUser ? .white : .primary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    if message.isFromCurrentUser {
                        // Sent message: colored glass bubble
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [roomColor, roomColor.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    } else {
                        // Received message: glass material bubble
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                        }
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
        .contextMenu {
            if let text = message.text, !text.isEmpty {
                Button {
                    copyTextToClipboard(text)
                } label: {
                    Label("Copy Text", systemImage: "doc.on.doc")
                }
            }

            if let imageData = message.drawingData {
                Button {
                    copyImageToClipboard(imageData)
                } label: {
                    Label("Copy Image", systemImage: "photo.on.rectangle")
                }
            }

            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func copyTextToClipboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private func copyImageToClipboard(_ imageData: Data) {
        #if canImport(UIKit)
        if let image = UIImage(data: imageData) {
            UIPasteboard.general.image = image
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: imageData) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
        }
        #endif
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 16) {
            MessageBubbleView(
                message: Message(
                    senderID: "1",
                    senderName: "Alice",
                    roomID: "A",
                    text: "Hello there!",
                    isFromCurrentUser: false
                ),
                roomColor: Color(red: 0.2, green: 0.5, blue: 1.0)
            )

            MessageBubbleView(
                message: Message(
                    senderID: "2",
                    senderName: "Me",
                    roomID: "A",
                    text: "Hey! How are you?",
                    isFromCurrentUser: true
                ),
                roomColor: Color(red: 0.2, green: 0.5, blue: 1.0)
            )
        }
        .padding()
    }
}
