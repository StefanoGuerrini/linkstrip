import Foundation
import UserNotifications

/// Posts lightweight native notifications when a link is cleaned.
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    /// Requests notification authorization if not already determined.
    func requestAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            switch settings.authorizationStatus {
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        self.isAuthorized = granted
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async { self.isAuthorized = true }
            case .denied:
                DispatchQueue.main.async { self.isAuthorized = false }
            @unknown default:
                DispatchQueue.main.async { self.isAuthorized = false }
            }
        }
    }

    /// Posts a single, replacement notification for a cleaned link.
    func notifyCleaned(original: String, cleaned: String) {
        let content = UNMutableNotificationContent()
        content.title = "Link cleaned"
        content.body = "Tracking parameters removed from copied link."
        content.sound = .none

        // Use a fixed identifier so repeated cleans replace the previous
        // notification instead of flooding Notification Center.
        let request = UNNotificationRequest(
            identifier: "com.linkstrip.cleaned",
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Show the notification even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
