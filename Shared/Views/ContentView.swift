import SwiftUI

struct ContentView: View {
    @Environment(MultipeerService.self) private var multipeerService
    @State private var selectedRoom: ChatRoom?

    var body: some View {
        NavigationStack {
            if let room = selectedRoom {
                ChatRoomView(room: room, onBack: { selectedRoom = nil })
            } else {
                RoomSelectionView(onRoomSelected: { room in
                    selectedRoom = room
                    multipeerService.joinRoom(room)
                })
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(MultipeerService())
}
