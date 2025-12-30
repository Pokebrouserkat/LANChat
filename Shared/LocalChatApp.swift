import SwiftUI
import SwiftData

@main
struct LocalChatApp: App {
    let modelContainer: ModelContainer

    @State private var multipeerService = MultipeerService()
    @State private var pendingDeleteAction: DeleteAction?
    @State private var showDeleteConfirmation = false
    @State private var showNoMessagesAlert = false
    @State private var showSettings = false
    @State private var pendingRoomToOpen: ChatRoom?
    @State private var shouldShowRoomSelection = false

    enum DeleteAction {
        case all
        case room(ChatRoom)
    }

    init() {
        do {
            modelContainer = try ModelContainer(for: Message.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(showSettings: $showSettings, pendingRoomToOpen: $pendingRoomToOpen, shouldShowRoomSelection: $shouldShowRoomSelection)
                .environment(multipeerService)
                .onOpenURL { url in
                    handleURL(url)
                }
                .alert("Delete Messages", isPresented: $showDeleteConfirmation) {
                    Button("Delete", role: .destructive) {
                        if let action = pendingDeleteAction {
                            performDelete(action)
                        }
                        openSettings()
                    }
                    Button("Cancel", role: .cancel) {
                        openSettings()
                    }
                } message: {
                    Text(deleteConfirmationMessage)
                }
                .alert("No Messages", isPresented: $showNoMessagesAlert) {
                    Button("OK", role: .cancel) {
                        openSettings()
                    }
                } message: {
                    Text("There are no messages to delete.")
                }
                #if os(macOS)
                .containerBackground(.clear, for: .window)
                #elseif targetEnvironment(macCatalyst)
                .transparentWindow()
                #endif
        }
        .modelContainer(modelContainer)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 600)
        #endif
    }

    private var deleteConfirmationMessage: String {
        switch pendingDeleteAction {
        case .all:
            return "Are you sure you want to delete all messages? This cannot be undone."
        case .room(let room):
            return "Are you sure you want to delete all messages in Room \(room.rawValue)? This cannot be undone."
        case nil:
            return ""
        }
    }

    private func handleURL(_ url: URL) {
        guard url.scheme == "localchat" else { return }

        switch url.host {
        case "delete-all":
            // Show room selection screen behind the confirmation
            shouldShowRoomSelection = true
            if hasAnyMessages() {
                pendingDeleteAction = .all
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showDeleteConfirmation = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showNoMessagesAlert = true
                }
            }
        case "delete-room":
            if let roomID = url.pathComponents.dropFirst().first,
               let room = ChatRoom(rawValue: roomID) {
                // Navigate to the room first so user can see it behind the confirmation
                pendingRoomToOpen = room
                if hasMessages(in: room) {
                    pendingDeleteAction = .room(room)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showDeleteConfirmation = true
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showNoMessagesAlert = true
                    }
                }
            }
        default:
            // Handle localchat://a, localchat://b, etc. to open rooms
            if let host = url.host,
               let room = ChatRoom(rawValue: host.uppercased()) {
                pendingRoomToOpen = room
            }
        }
    }

    @MainActor
    private func hasAnyMessages() -> Bool {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Message>()
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    @MainActor
    private func hasMessages(in room: ChatRoom) -> Bool {
        let context = modelContainer.mainContext
        let roomID = room.rawValue
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.roomID == roomID }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    @MainActor
    private func performDelete(_ action: DeleteAction) {
        switch action {
        case .all:
            deleteAllMessages()
        case .room(let room):
            deleteMessages(for: room)
        }
    }

    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
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
            NotificationCenter.default.post(name: .messagesDeleted, object: nil)
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
            NotificationCenter.default.post(name: .messagesDeleted, object: room)
        } catch {
            print("Failed to delete messages for room \(room.rawValue): \(error)")
        }
    }
}

// MARK: - Transparent Window Support
#if os(macOS)
import AppKit

struct TransparentWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(TransparentWindowAccessor())
    }
}

class TransparentNSView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindow()
    }

    override func layout() {
        super.layout()
        configureWindow()
    }

    private func configureWindow() {
        guard let window = self.window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.hasShadow = true
    }
}

struct TransparentWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        return TransparentNSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func transparentWindow() -> some View {
        modifier(TransparentWindowModifier())
    }
}
#elseif targetEnvironment(macCatalyst)
import UIKit

struct TransparentWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(TransparentWindowAccessor())
            .onAppear {
                // Apply transparency after a short delay to ensure window is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    applyTransparencyToAllWindows()
                }
            }
    }
}

struct TransparentWindowAccessor: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = TransparentHostingView()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private func applyTransparencyToAllWindows() {
    for scene in UIApplication.shared.connectedScenes {
        guard let windowScene = scene as? UIWindowScene else { continue }

        // Configure titlebar
        if let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .hidden
            titlebar.toolbar = nil
        }

        for window in windowScene.windows {
            window.backgroundColor = .clear
            window.isOpaque = false
            window.rootViewController?.view.backgroundColor = .clear

            // Try to access NSWindow
            configureNSWindowForUIWindow(window)
        }
    }
}

private func configureNSWindowForUIWindow(_ window: UIWindow) {
    // Try to get the hosting window using private API
    // The selector name varies by macOS version
    let selectors = ["_bridgedWindow", "nsWindow", "_nsWindow"]

    for selectorName in selectors {
        let selector = NSSelectorFromString(selectorName)
        if window.responds(to: selector),
           let result = window.perform(selector),
           let nsWindow = result.takeUnretainedValue() as AnyObject? {
            applyTransparencyToNSWindow(nsWindow)
            return
        }
    }

    // Try via windowScene
    if let windowScene = window.windowScene {
        for selectorName in selectors {
            let selector = NSSelectorFromString(selectorName)
            if windowScene.responds(to: selector),
               let result = windowScene.perform(selector),
               let nsWindow = result.takeUnretainedValue() as AnyObject? {
                applyTransparencyToNSWindow(nsWindow)
                return
            }
        }
    }
}

private func applyTransparencyToNSWindow(_ nsWindow: AnyObject) {
    // Get NSColor.clearColor using perform selector
    guard let nsColorClass = NSClassFromString("NSColor") as? NSObject.Type,
          let clearColorResult = nsColorClass.perform(NSSelectorFromString("clearColor")),
          let clearColor = clearColorResult.takeUnretainedValue() as AnyObject? else {
        return
    }

    // setOpaque:NO - pass NSNumber(false) for BOOL parameter
    let setOpaqueSelector = NSSelectorFromString("setOpaque:")
    if nsWindow.responds(to: setOpaqueSelector) {
        _ = nsWindow.perform(setOpaqueSelector, with: NSNumber(value: false))
    }

    // setBackgroundColor:clearColor
    let setBackgroundColorSelector = NSSelectorFromString("setBackgroundColor:")
    if nsWindow.responds(to: setBackgroundColorSelector) {
        _ = nsWindow.perform(setBackgroundColorSelector, with: clearColor)
    }
}

class TransparentHostingView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window else { return }
        window.backgroundColor = .clear
        window.isOpaque = false
        window.rootViewController?.view.backgroundColor = .clear

        // Try to configure after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            applyTransparencyToAllWindows()
        }
    }
}

extension View {
    func transparentWindow() -> some View {
        modifier(TransparentWindowModifier())
    }
}
#endif

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
