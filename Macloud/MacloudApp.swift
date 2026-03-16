import SwiftUI

@main
struct MacloudApp: App {
    var body: some Scene {
        MenuBarExtra("Macloud", systemImage: "cloud") {
            MenuBarMenu()
        }
    }
}
