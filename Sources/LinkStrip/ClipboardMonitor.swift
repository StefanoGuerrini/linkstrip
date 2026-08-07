import AppKit
import Foundation

/// Monitors the general pasteboard for URL strings and rewrites the
/// clipboard when a known tracking parameter is detected.
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    private let interval: TimeInterval

    private let cleaner: URLCleaner
    private let isEnabled: () -> Bool
    private let onClean: ((_ original: String, _ cleaned: String) -> Void)?

    /// - Parameters:
    ///   - cleaner: The `URLCleaner` used to strip tracking parameters.
    ///   - interval: Polling interval in seconds. Defaults to 0.5 s.
    ///   - isEnabled: Closure returning the current monitoring preference.
    ///   - onClean: Optional callback invoked after a successful clean.
    init(
        cleaner: URLCleaner,
        interval: TimeInterval = 0.5,
        isEnabled: @escaping () -> Bool,
        onClean: ((_ original: String, _ cleaned: String) -> Void)? = nil
    ) {
        self.cleaner = cleaner
        self.interval = interval
        self.isEnabled = isEnabled
        self.onClean = onClean
    }

    deinit {
        stop()
    }

    /// Starts polling the pasteboard on the current run loop.
    func start() {
        guard timer == nil else { return }
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    /// Stops polling.
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        guard isEnabled() else {
            lastChangeCount = pasteboard.changeCount
            return
        }

        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let original = pasteboard.string(forType: .string),
              let cleaned = cleaner.clean(original),
              cleaned != original else {
            return
        }

        pasteboard.clearContents()
        pasteboard.setString(cleaned, forType: .string)
        // Update our tracked count because clearing/writing changes it again.
        lastChangeCount = pasteboard.changeCount

        onClean?(original, cleaned)
    }
}
