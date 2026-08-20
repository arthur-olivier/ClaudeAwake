import SwiftUI
import AppKit

// MARK: - Point d'entree

@main
struct ClaudeAwakeApp: App {

    /// Intercepte la fermeture pour relacher le verrou
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var monitor = ChromeMonitor()

    var body: some Scene {
        /// MenuBar
        MenuBarExtra {
            PanelView(monitor: monitor)
        } label: {
            //Image dans le MenuBar
            let renderer = ImageRenderer(content: SignalIcon(state: monitor.state))
            if let nsImage = renderer.nsImage {
                Image(nsImage: nsImage)
            }
        }
        .menuBarExtraStyle(.window)

        /// Fenêtre About
        Window("A propos de ClaudeAwake", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        
    }
}

// MARK: - Delegue

/// Lorsqu'on ferme l'app alors on veut que le verrou se relâche sinon le process cafein pourrait tourner indéfiniment
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        Power.allowSleep()
    }
}
