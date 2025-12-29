import SwiftUI
import SwiftData

@main
struct LocalChatApp: App {
    let modelContainer: ModelContainer

    @State private var multipeerService = MultipeerService()

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
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 600)
        #endif
    }
}
