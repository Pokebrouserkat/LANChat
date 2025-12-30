import SwiftUI

struct ContentView: View {
    @Environment(MultipeerService.self) private var multipeerService
    @State private var selectedRoom: ChatRoom?
    @Binding var showSettings: Bool
    @Binding var pendingRoomToOpen: ChatRoom?

    var body: some View {
        NavigationStack {
            if let room = selectedRoom {
                ChatRoomView(room: room, onBack: { selectedRoom = nil })
            } else {
                RoomSelectionView(onRoomSelected: { room in
                    selectedRoom = room
                    multipeerService.joinRoom(room)
                }, showSettings: $showSettings)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: pendingRoomToOpen) { _, newRoom in
            if let room = newRoom {
                selectedRoom = room
                multipeerService.joinRoom(room)
                pendingRoomToOpen = nil
            }
        }
    }
}

#Preview {
    ContentView(showSettings: .constant(false), pendingRoomToOpen: .constant(nil))
        .environment(MultipeerService())
}
