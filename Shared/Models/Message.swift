import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var senderID: String
    var senderName: String
    var roomID: String
    var text: String?
    var drawingData: Data?
    var isFromCurrentUser: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        senderID: String,
        senderName: String,
        roomID: String,
        text: String? = nil,
        drawingData: Data? = nil,
        isFromCurrentUser: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.senderID = senderID
        self.senderName = senderName
        self.roomID = roomID
        self.text = text
        self.drawingData = drawingData
        self.isFromCurrentUser = isFromCurrentUser
    }
}

// Network payload for sending messages over MultipeerConnectivity
struct MessagePayload: Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let senderID: String
    let senderName: String
    let roomID: String
    let text: String?
    let drawingData: Data?

    init(from message: Message) {
        self.id = message.id
        self.timestamp = message.timestamp
        self.senderID = message.senderID
        self.senderName = message.senderName
        self.roomID = message.roomID
        self.text = message.text
        self.drawingData = message.drawingData
    }

    func toMessage(isFromCurrentUser: Bool) -> Message {
        Message(
            id: id,
            timestamp: timestamp,
            senderID: senderID,
            senderName: senderName,
            roomID: roomID,
            text: text,
            drawingData: drawingData,
            isFromCurrentUser: isFromCurrentUser
        )
    }
}
