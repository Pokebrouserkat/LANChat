import SwiftUI

struct MessageInputView: View {
    let onSend: (String?, Data?) -> Void

    @State private var text = ""

    var body: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("Message", text: $text)
                .textFieldStyle(.plain)
                .padding(10)
                #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.systemGray6))
                #endif
                .clipShape(RoundedRectangle(cornerRadius: 20))

            // Send button
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
        }
        .padding()
    }

    private func sendMessage() {
        guard !text.isEmpty else { return }
        onSend(text, nil)
        text = ""
    }
}

#Preview {
    MessageInputView(onSend: { _, _ in })
}
