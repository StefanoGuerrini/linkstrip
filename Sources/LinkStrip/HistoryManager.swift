import Foundation

/// A single cleaned-link record.
struct CleanedLink: Codable, Identifiable, Equatable {
    let id: UUID
    let original: String
    let cleaned: String
    let timestamp: Date

    init(id: UUID = UUID(), original: String, cleaned: String, timestamp: Date = Date()) {
        self.id = id
        self.original = original
        self.cleaned = cleaned
        self.timestamp = timestamp
    }
}

/// Persists the most recent cleaned URLs to a local JSON file.
final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    static let maxEntries = 100

    @Published private(set) var entries: [CleanedLink] = []

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.linkstrip.history", qos: .utility)

    init(appSupportSubdirectory: String = "LinkStrip") {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent(appSupportSubdirectory, isDirectory: true)
        self.fileURL = directory.appendingPathComponent("history.json")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        load()
    }

    /// Adds a new record, trimming history to the most recent entries.
    func add(original: String, cleaned: String) {
        let link = CleanedLink(original: original, cleaned: cleaned)
        queue.async { [weak self] in
            guard let self = self else { return }
            var updated = self.entries
            updated.insert(link, at: 0)
            if updated.count > HistoryManager.maxEntries {
                updated = Array(updated.prefix(HistoryManager.maxEntries))
            }
            self.save(entries: updated)
            DispatchQueue.main.async {
                self.entries = updated
            }
        }
    }

    /// Removes all history entries.
    func clear() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.save(entries: [])
            DispatchQueue.main.async {
                self.entries = []
            }
        }
    }

    private func load() {
        queue.async { [weak self] in
            guard let self = self,
                  let data = try? Data(contentsOf: self.fileURL),
                  let loaded = try? JSONDecoder().decode([CleanedLink].self, from: data) else {
                return
            }
            DispatchQueue.main.async {
                self.entries = loaded
            }
        }
    }

    private func save(entries: [CleanedLink]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
