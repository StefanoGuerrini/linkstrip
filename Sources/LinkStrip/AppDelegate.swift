import AppKit
import SwiftUI

/// Application delegate that bootstraps the accessory-only menu-bar app.
@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState!
    private var menuBarController: MenuBarController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        BrowserRouter.shared.recordCurrentBrowser()
        appState = AppState()
        menuBarController = MenuBarController(appState: appState)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in the menu bar when the user closes a settings/history window.
        false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            BrowserRouter.shared.handle(url)
        }
    }
}
