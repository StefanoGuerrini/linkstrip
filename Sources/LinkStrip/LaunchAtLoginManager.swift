import Foundation
import ServiceManagement

/// Registers or unregisters the main app as a login item using SMAppService.
enum LaunchAtLoginManager {
    /// Returns whether the main app is currently registered to launch at login.
    static var isEnabled: Bool {
        let service = SMAppService.mainApp
        return service.status == .enabled
    }

    /// Attempts to enable or disable launch at login.
    /// - Returns: `true` if the requested state was successfully applied.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            return true
        } catch {
            NSLog("Failed to change launch-at-login state: \(error)")
            return false
        }
    }
}
