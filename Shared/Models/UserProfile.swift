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
        if let storedName = UserDefaults.standard.string(forKey: Self.displayNameKey), !storedName.isEmpty {
            self.displayName = storedName
        } else {
            #if os(macOS)
            self.displayName = NSFullUserName().isEmpty ? "User" : NSFullUserName()
            #else
            self.displayName = UIDevice.current.name
            #endif
            UserDefaults.standard.set(self.displayName, forKey: Self.displayNameKey)
        }
    }
}
