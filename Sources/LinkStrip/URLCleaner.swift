import Foundation

/// Represents the tracking-rules JSON bundled with the app.
struct TrackingRules: Codable {
    let version: Int
    let parameters: [String]
}

/// Cleans URLs by stripping known tracking query parameters.
final class URLCleaner {
    private let parameters: Set<String>

    /// Loads bundled rules from a local JSON file and appends any
    /// user-defined custom parameters.
    init(rulesURL: URL, customParameters: [String] = []) throws {
        let data = try Data(contentsOf: rulesURL)
        let rules = try JSONDecoder().decode(TrackingRules.self, from: data)
        self.parameters = Set(rules.parameters).union(customParameters)
    }

    /// Used for testing or for a user-supplied override list.
    init(parameters: [String]) {
        self.parameters = Set(parameters)
    }

    /// Returns a new cleaner that merges the bundled rules with a fresh set
    /// of custom parameters.
    func cleaner(adding customParameters: [String], rulesURL: URL) throws -> URLCleaner {
        return try URLCleaner(rulesURL: rulesURL, customParameters: customParameters)
    }

    /// Returns the cleaned URL string, the original string if no parameters
    /// matched, or `nil` when the input is not a valid URL.
    func clean(_ urlString: String) -> String? {
        guard var components = URLComponents(string: urlString) else {
            return nil
        }
        guard let queryItems = components.queryItems, !queryItems.isEmpty else {
            // Valid URL with no query string; nothing to clean.
            return urlString
        }

        let cleanedItems = queryItems.filter { item in
            !parameters.contains(item.name)
        }

        if cleanedItems.count == queryItems.count {
            // Nothing removed; avoid rewriting the clipboard.
            return urlString
        }

        components.queryItems = cleanedItems.isEmpty ? nil : cleanedItems
        return components.string
    }

    /// Returns the currently active parameter names, sorted.
    var trackedParameters: [String] {
        Array(parameters).sorted()
    }

    /// Attempts to extract and clean a destination URL from common redirect
    /// or click-tracking services. Returns the cleaned destination, `nil` if
    /// no embedded URL is found, or the original string if the destination
    /// contains no tracking parameters.
    func cleanRedirect(_ urlString: String) -> String? {
        guard let firstSchemeEnd = urlString.range(of: "://")?.upperBound else {
            return nil
        }

        // Look for a second http(s):// scheme after the first one. This handles
        // services like link.fndrsp.net/CL0/https://real-destination.com/...
        let afterFirstScheme = String(urlString[firstSchemeEnd...])
        if let embeddedRange = afterFirstScheme.range(of: "https://")
            ?? afterFirstScheme.range(of: "http://") {
            var embedded = String(afterFirstScheme[embeddedRange.lowerBound...])
            if let decoded = embedded.removingPercentEncoding {
                embedded = decoded
            }
            guard let cleaned = clean(embedded) else { return embedded }
            return cleaned
        }

        // Fallback: some redirect services put the destination in a query param.
        guard let components = URLComponents(string: urlString),
              let queryItems = components.queryItems else {
            return nil
        }

        let redirectParamNames: Set<String> = ["url", "u", "link", "destination", "target", "redirect", "to"]
        for item in queryItems where redirectParamNames.contains(item.name.lowercased()) {
            guard let value = item.value else { continue }
            let decoded = value.removingPercentEncoding ?? value
            guard decoded.hasPrefix("http://") || decoded.hasPrefix("https://") else { continue }
            guard let cleaned = clean(decoded), cleaned != decoded else { continue }
            return cleaned
        }

        return nil
    }
}
