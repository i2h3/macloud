import SwiftUI

@main
struct Macloud: App {
    @State private var store = Store()

    var body: some Scene {
        MenuBarExtra("Macloud", systemImage: store.systemImageName) {
            MenuBarMenu(store: store)
        }
    }
}
