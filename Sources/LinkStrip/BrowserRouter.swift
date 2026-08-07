import AppKit
import CoreServices
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
    /// to it. Call this once at launch and whenever the user enables click cleaning.
    func recordCurrentBrowser() {
        guard let browserID = currentDefaultBrowserBundleID,
              browserID != Bundle.main.bundleIdentifier else {
            return
        }
        savedBrowserBundleID = browserID
    }

    /// Attempts to restore the previously saved default browser. Because modern
    /// macOS protects the https handler, this may fail silently; if so, System
    /// Settings is opened so the user can change it manually.
    func restorePreviousBrowser() {
        guard let browserID = savedBrowserBundleID,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browserID) else {
            openDefaultBrowserSettings()
            return
        }

        var restored = true
        let group = DispatchGroup()
        for scheme in ["http", "https"] {
            group.enter()
            NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenURLsWithScheme: scheme) { error in
                if let error = error {
                    NSLog("Failed to restore \(scheme) default: \(error)")
                    restored = false
                }
                group.leave()
            }
        }
        group.wait()

        if !restored {
            openDefaultBrowserSettings()
        }
    }

    private func openDefaultBrowserSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension?DefaultBrowser") else {
            return
        }
        NSWorkspace.shared.open(url)
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
