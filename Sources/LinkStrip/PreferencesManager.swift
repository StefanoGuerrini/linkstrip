import Foundation

/// Keys and defaults for user preferences.
enum PreferenceKey: String {
    case cleanCopiedLinks
    case cleanRedirectLinks
    case cleanLinksOnOpen
    case notificationsEnabled
    case launchAtLoginEnabled
    case customParameters
}

/// Manages user defaults for the app.
final class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()

    private let defaults: UserDefaults

    @Published var cleanCopiedLinks: Bool {
        didSet { defaults.set(cleanCopiedLinks, forKey: PreferenceKey.cleanCopiedLinks.rawValue) }
    }

    @Published var cleanRedirectLinks: Bool {
        didSet { defaults.set(cleanRedirectLinks, forKey: PreferenceKey.cleanRedirectLinks.rawValue) }
    }

    @Published var cleanLinksOnOpen: Bool {
        didSet { defaults.set(cleanLinksOnOpen, forKey: PreferenceKey.cleanLinksOnOpen.rawValue) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: PreferenceKey.notificationsEnabled.rawValue) }
    }

    @Published var launchAtLoginEnabled: Bool {
        didSet {
            defaults.set(launchAtLoginEnabled, forKey: PreferenceKey.launchAtLoginEnabled.rawValue)
            // Best-effort registration with SMAppService. This only fully works
            // when the app is bundled and code-signed, but it builds and runs
            // without signing for development.
            _ = LaunchAtLoginManager.setEnabled(launchAtLoginEnabled)
        }
    }

    /// User-defined tracking parameter names appended to the bundled rules.
    @Published var customParameters: [String] {
        didSet { defaults.set(customParameters, forKey: PreferenceKey.customParameters.rawValue) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.cleanCopiedLinks = defaults.object(forKey: PreferenceKey.cleanCopiedLinks.rawValue) as? Bool ?? true
        self.cleanRedirectLinks = defaults.object(forKey: PreferenceKey.cleanRedirectLinks.rawValue) as? Bool ?? true
        self.cleanLinksOnOpen = defaults.object(forKey: PreferenceKey.cleanLinksOnOpen.rawValue) as? Bool ?? false
        self.notificationsEnabled = defaults.object(forKey: PreferenceKey.notificationsEnabled.rawValue) as? Bool ?? true
        self.launchAtLoginEnabled = defaults.object(forKey: PreferenceKey.launchAtLoginEnabled.rawValue) as? Bool ?? false
        self.customParameters = defaults.object(forKey: PreferenceKey.customParameters.rawValue) as? [String] ?? []

        // Make sure the SMAppService state matches the saved preference.
        _ = LaunchAtLoginManager.setEnabled(self.launchAtLoginEnabled)
    }

    /// Resets all preferences to factory defaults.
    func restoreDefaults() {
        cleanCopiedLinks = true
        cleanRedirectLinks = true
        cleanLinksOnOpen = false
        notificationsEnabled = true
        launchAtLoginEnabled = false
        customParameters = []
    }
}
