import Cocoa
import UserNotifications

/// Headless Share extension view controller.
///
/// Appears in the macOS Share menu as "LinkStrip" when the user right-clicks
/// a link. It receives the shared URL, strips tracking parameters using the
/// same rule engine as the host app, copies the cleaned URL to the clipboard,
/// and completes without showing any UI.
final class ShareViewController: NSViewController {

    /// Minimal in-extension cleaner so the extension does not depend on the
    /// host app runtime. The same bundled `tracking-params.json` is packaged
    /// inside the .appex Resources directory.
    private lazy var cleaner: URLCleaner? = {
        guard let rulesURL = Bundle.main.url(forResource: "tracking-params", withExtension: "json") else {
            return nil
        }
        return try? URLCleaner(rulesURL: rulesURL)
    }()

    override func loadView() {
        // Share extensions must provide a view controller; keep it empty.
        view = NSView()
    }

    override func beginRequest(with context: NSExtensionContext) {
        guard let item = context.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            context.completeRequest(returningItems: nil)
            return
        }

        // Extract the first URL attachment asynchronously, then process and
        // complete the extension request. Do not block the calling thread.
        loadFirstURL(from: attachments) { [weak self] url in
            guard let self = self, let url = url else {
                context.completeRequest(returningItems: nil)
                return
            }
            self.process(url: url)
            context.completeRequest(returningItems: nil)
        }
    }

    private func loadFirstURL(from attachments: [NSItemProvider], completion: @escaping (URL?) -> Void) {
        var foundURL: URL?
        let group = DispatchGroup()

        for provider in attachments where foundURL == nil {
            if provider.hasItemConformingToTypeIdentifier("public.url") {
                group.enter()
                provider.loadItem(forTypeIdentifier: "public.url") { value, _ in
                    defer { group.leave() }
                    if foundURL == nil, let url = value as? URL {
                        foundURL = url
                    }
                }
            }
        }

        group.notify(queue: .main) {
            completion(foundURL)
        }
    }

    private func process(url: URL) {
        let original = url.absoluteString
        let outgoing: String

        if let redirectCleaned = cleaner?.cleanRedirect(original) {
            outgoing = redirectCleaned
        } else if let cleaned = cleaner?.clean(original), cleaned != original {
            outgoing = cleaned
        } else {
            outgoing = original
        }

        guard outgoing != original else { return }

        DispatchQueue.main.async {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(outgoing, forType: .string)
            self.postNotification(original: original, cleaned: outgoing)
        }
    }

    private func postNotification(original: String, cleaned: String) {
        let content = UNMutableNotificationContent()
        content.title = "Link cleaned"
        content.body = "Tracking parameters removed; cleaned URL copied to clipboard."
        content.sound = .none

        let request = UNNotificationRequest(
            identifier: "com.linkstrip.share.cleaned",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
