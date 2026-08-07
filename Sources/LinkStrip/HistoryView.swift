import SwiftUI

/// Window showing the last 100 cleaned links.
struct HistoryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            if appState.history.entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No cleaned links yet")
                        .font(.headline)
                    Text("Copy a URL with tracking parameters to see it here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(appState.history.entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.cleaned)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(entry.original)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(entry.timestamp, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                    .contextMenu {
                        Button("Copy cleaned URL") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(entry.cleaned, forType: .string)
                        }
                        Button("Copy original URL") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(entry.original, forType: .string)
                        }
                    }
                }
            }

            Divider()

            HStack {
                Text("\(appState.history.entries.count) of \(HistoryManager.maxEntries) saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear History") {
                    appState.history.clear()
                }
                .disabled(appState.history.entries.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 300)
    }
}
