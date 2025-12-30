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
