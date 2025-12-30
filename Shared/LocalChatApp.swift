import SwiftUI
import SwiftData

@main
struct LocalChatApp: App {
    let modelContainer: ModelContainer

    @State private var multipeerService = MultipeerService()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            modelContainer = try ModelContainer(for: Message.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(multipeerService)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        processDeleteSettings()
                    }
                }
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 600)
        #endif
    }

    @MainActor
    private func processDeleteSettings() {
        let defaults = UserDefaults.standard

        // Check if delete all is requested
        if defaults.bool(forKey: "LocalChat.deleteAllMessages") {
            deleteAllMessages()
            defaults.set(false, forKey: "LocalChat.deleteAllMessages")
        }

        // Check individual room deletions
        for room in ChatRoom.allCases {
            let key = "LocalChat.deleteRoom.\(room.rawValue)"
            if defaults.bool(forKey: key) {
                deleteMessages(for: room)
                defaults.set(false, forKey: key)
            }
        }
    }

    @MainActor
    private func deleteAllMessages() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Message>()

        do {
            let messages = try context.fetch(descriptor)
            for message in messages {
                context.delete(message)
            }
            try context.save()
        } catch {
            print("Failed to delete all messages: \(error)")
        }
    }

    @MainActor
    private func deleteMessages(for room: ChatRoom) {
        let context = modelContainer.mainContext
        let roomID = room.rawValue
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.roomID == roomID }
        )

        do {
            let messages = try context.fetch(descriptor)
            for message in messages {
                context.delete(message)
            }
            try context.save()
        } catch {
            print("Failed to delete messages for room \(room.rawValue): \(error)")
        }
    }
}

// MARK: - Glass Design System for iOS 26 / macOS 26
extension View {
    func glassBackground(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            }
    }

    func floatingGlass(cornerRadius: CGFloat = 28) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            }
    }
}
