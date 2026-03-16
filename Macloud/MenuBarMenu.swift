import SwiftUI

struct MenuBarMenu: View {
    @Bindable var store: Store

    var body: some View {
        Group {
            if store.container == nil {
                Button(action: store.start) {
                    Label("Start", systemImage: "play.fill")
                }
            } else {
                Button(action: store.dispatchStop) {
                    Label("Stop", systemImage: "stop.fill")
                }

                Divider()

                Button(action: store.openInBrowser) {
                    Label("Open in Browser", systemImage: "globe")
                }

                Button(action: store.terminal) {
                    Label("Terminal", systemImage: "apple.terminal")
                }
            }

            Divider()

            Button(action: store.quit) {
                Label("Quit", systemImage: "xmark.rectangle")
            }
        }
        .disabled(store.activity)
    }
}
