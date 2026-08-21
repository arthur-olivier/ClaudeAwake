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
            MenuBarIcon(state: monitor.state)
        }
        .menuBarExtraStyle(.window)

        /// Fenêtre About
        Window("À propos de ClaudeAwake", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        
    }
    

// MARK: - Icône
    
    ///On convertit le dessin SwiftUi en une image pour l'icône
    struct MenuBarIcon: View {

        let state: MonitorState

        var body: some View {
            if let image = rendered {
                Image(nsImage: image)
            }
        }

        private var rendered: NSImage? {
            let renderer = ImageRenderer(content: SignalIcon(state: state))
            renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
            let image = renderer.nsImage
            image?.isTemplate = true
            return image
        }
    }
}

// MARK: - Delegue

/// Lorsqu'on ferme l'app alors on veut que le verrou se relâche sinon le process cafein pourrait tourner indéfiniment
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        Power.allowSleep()
    }
}
