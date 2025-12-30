import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class MessageStore {
    private let modelContext: ModelContext
    private let userProfile: UserProfile
    private let multipeerService: MultipeerService

    var messages: [Message] = []
    var currentRoom: ChatRoom?

    init(modelContext: ModelContext, userProfile: UserProfile, multipeerService: MultipeerService) {
        self.modelContext = modelContext
        self.userProfile = userProfile
        self.multipeerService = multipeerService

        // Set up message receiving
        multipeerService.onMessageReceived = { [weak self] payload in
            Task { @MainActor in
                self?.handleReceivedMessage(payload)
            }
        }
    }

    func loadMessages(for room: ChatRoom) {
        currentRoom = room
        let roomID = room.rawValue

        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.roomID == roomID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        do {
            messages = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch messages: \(error)")
            messages = []
        }
    }

    func sendMessage(text: String?, drawingData: Data?) {
        guard let room = currentRoom else { return }
        guard text != nil || drawingData != nil else { return }

        let message = Message(
            senderID: userProfile.userID,
            senderName: userProfile.displayName,
            roomID: room.rawValue,
            text: text,
            drawingData: drawingData,
            isFromCurrentUser: true
        )

        // Save locally
        modelContext.insert(message)
        messages.append(message)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save message: \(error)")
        }

        // Send to peers
        let payload = MessagePayload(from: message)
        do {
            try multipeerService.sendMessage(payload)
        } catch {
            print("Failed to send message: \(error)")
        }
    }

    private func handleReceivedMessage(_ payload: MessagePayload) {
        // Only process if we're in the same room
        guard let currentRoom = currentRoom, payload.roomID == currentRoom.rawValue else {
            // Still save it even if we're not viewing that room
            saveReceivedMessage(payload)
            return
        }

        let message = payload.toMessage(isFromCurrentUser: false)
        modelContext.insert(message)
        messages.append(message)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save received message: \(error)")
        }
    }

    private func saveReceivedMessage(_ payload: MessagePayload) {
        let message = payload.toMessage(isFromCurrentUser: false)
        modelContext.insert(message)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save received message: \(error)")
        }
    }

    // MARK: - Delete Methods

    func deleteMessage(_ message: Message) {
        modelContext.delete(message)
        messages.removeAll { $0.id == message.id }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete message: \(error)")
        }
    }

    func deleteAllMessages(for room: ChatRoom) {
        let roomID = room.rawValue
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.roomID == roomID }
        )

        do {
            let roomMessages = try modelContext.fetch(descriptor)
            for message in roomMessages {
                modelContext.delete(message)
            }
            try modelContext.save()

            // If we're currently viewing this room, clear the messages array
            if currentRoom == room {
                messages = []
            }
        } catch {
            print("Failed to delete messages for room \(room.rawValue): \(error)")
        }
    }

    func deleteAllMessages() {
        let descriptor = FetchDescriptor<Message>()

        do {
            let allMessages = try modelContext.fetch(descriptor)
            for message in allMessages {
                modelContext.delete(message)
            }
            try modelContext.save()
            messages = []
        } catch {
            print("Failed to delete all messages: \(error)")
        }
    }
}
