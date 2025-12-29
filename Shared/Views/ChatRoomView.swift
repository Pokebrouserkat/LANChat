import SwiftUI
import SwiftData

struct ChatRoomView: View {
    @Environment(MultipeerService.self) private var multipeerService
    @Environment(\.modelContext) private var modelContext
    let room: ChatRoom
    let onBack: () -> Void

    @State private var messageStore: MessageStore?
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let store = messageStore {
                            ForEach(store.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollProxy = proxy
                }
                .onChange(of: messageStore?.messages.count) { _, _ in
                    scrollToBottom()
                }
            }

            Divider()

            // Input area
            MessageInputView(onSend: { text, drawingData in
                messageStore?.sendMessage(text: text, drawingData: drawingData)
            })
        }
        .onAppear {
            setupMessageStore()
        }
        .onDisappear {
            multipeerService.leaveCurrentRoom()
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 500)
        #endif
    }

    private var chatHeader: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Rooms")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)

            Spacer()

            VStack(spacing: 2) {
                Text("Room \(room.rawValue)")
                    .font(.headline)
                HStack(spacing: 4) {
                    Circle()
                        .fill(connectionColor)
                        .frame(width: 8, height: 8)
                    Text(connectionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Peer count
            HStack(spacing: 4) {
                Image(systemName: "person.2")
                Text("\(multipeerService.connectedPeers.count)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var connectionColor: Color {
        switch multipeerService.connectionState {
        case .connected: return .green
        case .connecting: return .orange
        case .waiting: return .blue
        case .disconnected: return .red
        }
    }

    private var connectionText: String {
        switch multipeerService.connectionState {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .waiting: return "Waiting for others"
        case .disconnected: return "Disconnected"
        }
    }

    private func setupMessageStore() {
        let userProfile = UserProfile()
        messageStore = MessageStore(
            modelContext: modelContext,
            userProfile: userProfile,
            multipeerService: multipeerService
        )
        messageStore?.loadMessages(for: room)
    }

    private func scrollToBottom() {
        guard let lastMessage = messageStore?.messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

#Preview {
    ChatRoomView(room: .A, onBack: {})
        .environment(MultipeerService())
        .modelContainer(for: Message.self, inMemory: true)
}
