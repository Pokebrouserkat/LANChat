import SwiftUI

struct MessageInputView: View {
    let onSend: (String?, Data?) -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Glass text field
            HStack(spacing: 8) {
                TextField("Message", text: $text)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit(sendMessage)
                    .submitLabel(.send)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                }
            }

            // Glass send button
            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: text.isEmpty
                                        ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                                        : [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Circle()
                                    .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                            }
                            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                    }
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func sendMessage() {
        guard !text.isEmpty else { return }
        onSend(text, nil)
        text = ""
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

        VStack {
            Spacer()
            MessageInputView(onSend: { _, _ in })
                .background(.ultraThinMaterial)
        }
    }
}
