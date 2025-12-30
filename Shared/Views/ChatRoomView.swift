import SwiftUI
import SwiftData

struct ChatRoomView: View {
    @Environment(MultipeerService.self) private var multipeerService
    @Environment(\.modelContext) private var modelContext
    let room: ChatRoom
    let onBack: () -> Void

    @State private var messageStore: MessageStore?
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showingUserList = false
    @State private var messageToDelete: Message?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ZStack {
            // Subtle gradient background - translucent on macOS/Mac Catalyst for window transparency
            #if os(macOS) || targetEnvironment(macCatalyst)
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.04),
                    Color.purple.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
            #else
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            #endif

            VStack(spacing: 0) {
                // Glass Header
                chatHeader
                    .background(.ultraThinMaterial)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if let store = messageStore {
                                ForEach(store.messages) { message in
                                    MessageBubbleView(
                                        message: message,
                                        roomColor: roomColor,
                                        onDelete: {
                                            messageToDelete = message
                                            showingDeleteConfirmation = true
                                        }
                                    )
                                    .id(message.id)
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                    #if os(iOS)
                    .scrollDismissesKeyboard(.interactively)
                    #endif
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: messageStore?.messages.count) { _, _ in
                        scrollToBottom()
                    }
                }

                // Glass Input area
                MessageInputView(onSend: { text, drawingData in
                    messageStore?.sendMessage(text: text, drawingData: drawingData)
                })
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            setupMessageStore()
        }
        .onDisappear {
            multipeerService.leaveCurrentRoom()
        }
        .sheet(isPresented: $showingUserList) {
            UserListView(peers: multipeerService.connectedPeers)
        }
        .alert("Delete Message", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                messageToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let message = messageToDelete {
                    messageStore?.deleteMessage(message)
                }
                messageToDelete = nil
            }
        } message: {
            Text("This message will only be deleted for you. Anyone else who saw it will still have it.")
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 500)
        #else
        .navigationBarHidden(true)
        #endif
    }

    private var roomColor: Color {
        switch room.color {
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

    private var chatHeader: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                    Text("Rooms")
                }
                .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 3) {
                HStack(spacing: 6) {
                    Text(room.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Room")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 5) {
                    Circle()
                        .fill(connectionColor)
                        .frame(width: 8, height: 8)
                    Text(connectionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Peer count - tappable to show user list
            Button(action: { showingUserList = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "person.2.fill")
                    Text("\(multipeerService.connectedPeers.count)")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
