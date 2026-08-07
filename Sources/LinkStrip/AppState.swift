import AppKit
import Combine
import Foundation
import SwiftUI

/// Central application state that wires the cleaner, monitor, history,
/// notifications, and preferences together.
final class AppState: ObservableObject {
    static weak var shared: AppState?

    @Published var lastCleaned: String?
    @Published var cleaner: URLCleaner

    var preferences = PreferencesManager.shared
    var history = HistoryManager.shared
    var notifications = NotificationManager.shared

    private var monitor: ClipboardMonitor?
    private var cancellables = Set<AnyCancellable>()

    init() {
        let rulesURL = Self.bundledRulesURL()
        let cleaner = try! URLCleaner(
            rulesURL: rulesURL,
            customParameters: PreferencesManager.shared.customParameters
        )
        self.cleaner = cleaner
        AppState.shared = self

        NotificationManager.shared.requestAuthorization()
        bindPreferences()
        startMonitor()
    }

    /// Returns the URL of the bundled rules file, preferring the Resources
    /// directory of a packaged .app bundle and falling back to the SPM resource
    /// bundle used during development.
    private static func bundledRulesURL() -> URL {
        Bundle.main.url(forResource: "tracking-params", withExtension: "json")
            ?? Bundle.module.url(forResource: "tracking-params", withExtension: "json")!
    }

    /// Replaces the active cleaner with one that includes the latest custom
    /// parameters from preferences.
    func reloadRules() {
        let rulesURL = Self.bundledRulesURL()
        do {
            cleaner = try URLCleaner(
                rulesURL: rulesURL,
                customParameters: preferences.customParameters
            )
            restartMonitor()
        } catch {
            NSLog("Failed to reload tracking rules: \(error)")
        }
    }

    private func bindPreferences() {
        preferences.$customParameters
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadRules()
            }
            .store(in: &cancellables)

        preferences.$cleanCopiedLinks
            .dropFirst()
            .merge(with: preferences.$cleanRedirectLinks.dropFirst())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.restartMonitor()
            }
            .store(in: &cancellables)
    }

    private func startMonitor() {
        guard monitor == nil else { return }
        monitor = ClipboardMonitor(
            isEnabled: { [weak self] in
                guard let self = self else { return false }
                return self.preferences.cleanCopiedLinks || self.preferences.cleanRedirectLinks
            },
            clean: { [weak self] url in
                guard let self = self else { return nil }
                if self.preferences.cleanRedirectLinks, let unwrapped = self.cleaner.cleanRedirect(url) {
                    return unwrapped
                }
                if self.preferences.cleanCopiedLinks, let cleaned = self.cleaner.clean(url), cleaned != url {
                    return cleaned
                }
                return nil
            }
        ) { [weak self] original, cleaned in
            self?.handleCleaned(original: original, cleaned: cleaned)
        }
        monitor?.start()
    }

    private func stopMonitor() {
        monitor?.stop()
        monitor = nil
    }

    private func restartMonitor() {
        stopMonitor()
        startMonitor()
    }

    private func handleCleaned(original: String, cleaned: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastCleaned = cleaned
            self.history.add(original: original, cleaned: cleaned)
            if self.preferences.notificationsEnabled {
                self.notifications.notifyCleaned(original: original, cleaned: cleaned)
            }
        }
    }
}
