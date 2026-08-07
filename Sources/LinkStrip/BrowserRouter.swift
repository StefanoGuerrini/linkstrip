import AppKit
import Foundation

/// Routes http/https links through LinkStrip when the user has manually set
/// LinkStrip as the default web browser in System Settings.
///
/// Because macOS does not allow apps to silently change the default https
/// handler, the user must enable this manually:
///   System Settings → Desktop & Dock → Default web browser → LinkStrip
///
/// When LinkStrip receives a clicked URL, it cleans it and forwards the
/// cleaned URL to the previously detected real browser.
final class BrowserRouter {
    static let shared = BrowserRouter()

    private let savedBrowserKey = "defaultBrowserBundleID"

    /// Returns the bundle identifier of the browser saved as the real default
    /// browser, or nil if none has been recorded.
    var savedBrowserBundleID: String? {
        get { UserDefaults.standard.string(forKey: savedBrowserKey) }
        set { UserDefaults.standard.set(newValue, forKey: savedBrowserKey) }
    }

    /// Returns the bundle identifier of the app currently set as the default
    /// handler for https URLs.
    var currentDefaultBrowserBundleID: String? {
        guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) else {
            return nil
        }
        return Bundle(url: appURL)?.bundleIdentifier
    }

    /// True when LinkStrip itself is the current default https handler.
    var isLinkStripDefaultBrowser: Bool {
        currentDefaultBrowserBundleID == Bundle.main.bundleIdentifier
    }

    /// Records the current default browser so clicked links can be forwarded
    /// to it. Call this once at launch.
    func recordCurrentBrowser() {
        guard let browserID = currentDefaultBrowserBundleID,
              browserID != Bundle.main.bundleIdentifier else {
            return
        }
        savedBrowserBundleID = browserID
    }

    /// Cleans the clicked URL (if the preference is enabled) and opens it in
    /// the saved real browser.
    func handle(_ url: URL) {
        let urlString = url.absoluteString
        let outgoing: String

        if PreferencesManager.shared.cleanLinksOnOpen {
            if let redirectCleaned = AppState.shared?.cleaner.cleanRedirect(urlString) {
                outgoing = redirectCleaned
            } else if let paramCleaned = AppState.shared?.cleaner.clean(urlString) {
                outgoing = paramCleaned
            } else {
                outgoing = urlString
            }
        } else {
            outgoing = urlString
        }

        guard let outgoingURL = URL(string: outgoing) else {
            open(url, with: savedBrowserBundleID)
            return
        }
        open(outgoingURL, with: savedBrowserBundleID)
    }

    private func open(_ url: URL, with bundleID: String?) {
        guard let bundleID = bundleID,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            NSWorkspace.shared.open(url)
            return
        }
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
    }
}
