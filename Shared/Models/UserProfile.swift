import Foundation
import SwiftUI

@Observable
final class UserProfile: @unchecked Sendable {
    private static let displayNameKey = "LocalChat.displayName"
    private static let userIDKey = "LocalChat.userID"

    var displayName: String {
        didSet {
            UserDefaults.standard.set(displayName, forKey: Self.displayNameKey)
        }
    }

    let userID: String

    init() {
        // Load or generate user ID
        if let storedID = UserDefaults.standard.string(forKey: Self.userIDKey) {
            self.userID = storedID
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: Self.userIDKey)
            self.userID = newID
        }

        // Load or generate display name
        self.displayName = Self.loadDisplayName()

        // Observe app becoming active to reload settings from iOS Settings app
        #if !os(macOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadDisplayName()
        }
        #endif
    }

    private static func loadDisplayName() -> String {
        if let storedName = UserDefaults.standard.string(forKey: displayNameKey), !storedName.isEmpty {
            return storedName
        } else {
            #if os(macOS)
            let name = NSFullUserName().isEmpty ? "User" : NSFullUserName()
            #else
            let name = UIDevice.current.name
            #endif
            UserDefaults.standard.set(name, forKey: displayNameKey)
            return name
        }
    }

    private func reloadDisplayName() {
        if let storedName = UserDefaults.standard.string(forKey: Self.displayNameKey), !storedName.isEmpty {
            if displayName != storedName {
                displayName = storedName
            }
        }
    }
}
