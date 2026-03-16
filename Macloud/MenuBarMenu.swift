import NextcloudContainerManager
import SwiftUI
import os
import UserNotifications

struct MenuBarMenu: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "MenuBarMenu")

    @State var activity = false
    @State var container: NextcloudContainer?

    var body: some View {
        Group {
            if container == nil {
                Button(action: start) {
                    Label("Start", systemImage: "play.fill")
                }
            } else {
                Button(action: dispatchStop) {
                    Label("Stop", systemImage: "stop.fill")
                }
            }

            if container != nil {
                Divider()

                Button(action: openInBrowser) {
                    Label("Open in Browser", systemImage: "globe")
                }

                Button(action: terminal) {
                    Label("Terminal", systemImage: "apple.terminal")
                }
            }

            Divider()

            Button(action: quit) {
                Label("Quit", systemImage: "xmark.rectangle")
            }
        }
        .disabled(activity)
    }

    func start() {
        logger.info("Starting...")
        activity = true

        Task {
            do {
                container = try await NextcloudContainerManager.deploy()
                activity = false
                logger.info("Started.")
                await showNotification(title: "Nextcloud Started", body: "Your Nextcloud container is now running.")
            } catch {
                activity = false
                logger.error("Failed to start: \(error.localizedDescription)")
                await showNotification(title: "Nextcloud Start Failed", body: error.localizedDescription)
            }
        }
    }

    ///
    /// Dispatch a task for the asynchronous container stop.
    ///
    func dispatchStop() {
        Task {
            await stop()
        }
    }
    
    func stop() async {
        guard let container else {
            logger.error("Attempt to stop without container.")
            return
        }

        logger.info("Stopping...")
        activity = true

        do {
            try await container.delete()
            logger.info("Stopped.")
            self.container = nil
            await showNotification(title: "Nextcloud Stopped", body: "Your Nextcloud container has been stopped.")
        } catch {
            logger.error("Failed to delete container: \(error.localizedDescription)")
            await showNotification(title: "Nextcloud Stop Failed", body: error.localizedDescription)
        }
        
        activity = false
    }

    func openInBrowser() {
        guard let container else {
            logger.error("Attempt to open browser without container.")
            return
        }

        logger.info("Opening in browser...")
        let urlString = "http://localhost:\(container.port)"
        
        guard let url = URL(string: urlString) else {
            logger.error("Failed to create URL from string: \(urlString)")
            return
        }
        
        NSWorkspace.shared.open(url)
    }

    func terminal() {
        guard let container else {
            logger.error("Attempt to open Terminal without container.")
            return
        }

        logger.info("Opening Terminal...")
        let command = "docker exec --interactive --tty --user=www-data \(container.id) /bin/bash"
        
        // Create a temporary shell script that Terminal can execute
        // Using .command extension makes it open directly in Terminal without permissions
        let scriptContent = """
        #!/bin/bash
        \(command)
        """
        
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("nextcloud-terminal-\(UUID().uuidString).command")
        
        do {
            try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
            
            // Make the script executable
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: scriptURL.path
            )
            
            // Open the .command file in Terminal (no special permissions needed)
            NSWorkspace.shared.open(scriptURL)
        } catch {
            logger.error("Failed to create and open Terminal script: \(error.localizedDescription)")
        }
    }

    func quit() {
        activity = true
        logger.info("Quitting...")

        Task {
            await stop()
            NSApplication.shared.terminate(nil)
        }
    }
    
    /// Request notification authorization and show a notification
    private func showNotification(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        
        // Request authorization (this will only prompt once)
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            
            if granted {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil // Deliver immediately
                )
                
                try await center.add(request)
                logger.debug("Notification shown: \(title)")
            } else {
                logger.warning("Notification permission denied")
            }
        } catch {
            logger.error("Failed to show notification: \(error.localizedDescription)")
        }
    }
}
