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
        guard var components = URLComponents(string: urlString),
              let queryItems = components.queryItems,
              !queryItems.isEmpty else {
            return nil
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
}
