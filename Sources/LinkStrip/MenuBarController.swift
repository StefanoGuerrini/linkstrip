import AppKit
import Combine
import SwiftUI

/// Owns the menu-bar status item and its dropdown menu.
final class MenuBarController: NSObject {
    private let appState: AppState
    private var statusItem: NSStatusItem?
    private var historyWindowController: NSWindowController?
    private var preferencesWindowController: NSWindowController?
    private var aboutWindowController: NSWindowController?
    private var cancellables = Set<AnyCancellable>()

    private let lastCleanedItem = NSMenuItem(title: "No link cleaned yet", action: nil, keyEquivalent: "")
    private let historyMenuItem = NSMenuItem(title: "Open History", action: #selector(openHistory), keyEquivalent: "")
    private let preferencesMenuItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
    private let aboutMenuItem = NSMenuItem(title: "About LinkStrip", action: #selector(openAbout), keyEquivalent: "")
    private let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")

    init(appState: AppState) {
        self.appState = appState
        super.init()
        setupStatusItem()
        bindAppState()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "link",
            accessibilityDescription: "LinkStrip"
        )
        item.button?.imageScaling = .scaleProportionallyDown

        let menu = NSMenu()
        lastCleanedItem.isEnabled = false
        menu.addItem(lastCleanedItem)
        menu.addItem(.separator())

        historyMenuItem.target = self
        menu.addItem(historyMenuItem)

        preferencesMenuItem.target = self
        menu.addItem(preferencesMenuItem)

        menu.addItem(.separator())

        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)

        quitMenuItem.target = self
        menu.addItem(quitMenuItem)

        item.menu = menu
        statusItem = item
    }

    private func bindAppState() {
        appState.$lastCleaned
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cleaned in
                guard let self = self else { return }
                if let cleaned = cleaned {
                    // Truncate for display but keep the full URL in the tooltip.
                    let display = cleaned.count > 60 ? String(cleaned.prefix(57)) + "…" : cleaned
                    self.lastCleanedItem.title = display
                    self.lastCleanedItem.toolTip = cleaned
                } else {
                    self.lastCleanedItem.title = "No link cleaned yet"
                    self.lastCleanedItem.toolTip = nil
                }
            }
            .store(in: &cancellables)
    }

    @objc private func openHistory() {
        if historyWindowController == nil {
            let hostingController = NSHostingController(
                rootView: HistoryView().environmentObject(appState)
            )
            let window = NSWindow(contentViewController: hostingController)
            window.title = "History"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.minSize = NSSize(width: 500, height: 300)
            historyWindowController = NSWindowController(window: window)
        }
        historyWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            let hostingController = NSHostingController(
                rootView: PreferencesView().environmentObject(appState)
            )
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Preferences"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.minSize = NSSize(width: 420, height: 360)
            preferencesWindowController = NSWindowController(window: window)
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openAbout() {
        if aboutWindowController == nil {
            let hostingController = NSHostingController(rootView: AboutView())
            let window = NSWindow(contentViewController: hostingController)
            window.title = "About LinkStrip"
            window.styleMask = [.titled, .closable]
            aboutWindowController = NSWindowController(window: window)
        }
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
