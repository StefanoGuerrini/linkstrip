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
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://"),
              var components = URLComponents(string: trimmed) else {
            return nil
        }
        guard let queryItems = components.queryItems, !queryItems.isEmpty else {
            // Valid URL with no query string; nothing to clean.
            return trimmed
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
    /// or click-tracking services. Returns the cleaned destination, the
    /// extracted destination if cleaning made no changes, or `nil` if no
    /// embedded URL is found.
    func cleanRedirect(_ urlString: String) -> String? {
        // Decode percent encoding first. Many redirect services embed the
        // destination as a URL-encoded path segment, e.g.:
        // link.fndrsp.net/CL0/https:%2F%2Fexample.com%3Ffoo%3Dbar
        let decoded = urlString.removingPercentEncoding ?? urlString

        guard let firstSchemeEnd = decoded.range(of: "://")?.upperBound else {
            return nil
        }

        // Look for a second http(s):// scheme after the first one. This handles
        // services like link.fndrsp.net/CL0/https://real-destination.com/...
        let afterFirstScheme = String(decoded[firstSchemeEnd...])
        guard let embeddedRange = afterFirstScheme.range(of: "https://")
            ?? afterFirstScheme.range(of: "http://") else {
            return cleanRedirectFromQuery(urlString)
        }

        var embedded = String(afterFirstScheme[embeddedRange.lowerBound...])

        // Some services append routing/tracking path segments after the
        // embedded URL (e.g. .../1/<id>/<signature>). Strip the first such
        // delimiter to obtain a valid destination URL.
        let trailingDelimiters = ["/1/", "/2/"]
        if let delimiterRange = trailingDelimiters.compactMap({ embedded.range(of: $0) }).first {
            embedded = String(embedded[..<delimiterRange.lowerBound])
        }

        // If stripping the delimiter made the URL invalid, fall back to the
        // raw embedded string and let the cleaner handle it.
        guard let cleaned = clean(embedded) else { return embedded }
        return cleaned
    }

    /// Fallback for redirect services that pass the destination in a query
    /// parameter rather than the path.
    private func cleanRedirectFromQuery(_ urlString: String) -> String? {
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
