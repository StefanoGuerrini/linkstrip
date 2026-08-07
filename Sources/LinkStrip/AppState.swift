import AppKit
import Combine
import Foundation
import SwiftUI

/// Central application state that wires the cleaner, monitor, history,
/// notifications, and preferences together.
final class AppState: ObservableObject {
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

        preferences.$monitorEnabled
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                enabled ? self?.startMonitor() : self?.stopMonitor()
            }
            .store(in: &cancellables)
    }

    private func startMonitor() {
        guard monitor == nil else { return }
        monitor = ClipboardMonitor(
            cleaner: cleaner,
            isEnabled: { [weak self] in self?.preferences.monitorEnabled ?? true }
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
