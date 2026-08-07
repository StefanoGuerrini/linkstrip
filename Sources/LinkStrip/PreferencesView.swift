import SwiftUI

/// Preferences window for toggles, rule editing, and import/export.
struct PreferencesView: View {
    @EnvironmentObject var appState: AppState

    @State private var customParameterInput = ""

    var body: some View {
        Form {
            Section("General") {
                Toggle("Monitor clipboard", isOn: $appState.preferences.monitorEnabled)
                Toggle("Show notifications", isOn: $appState.preferences.notificationsEnabled)
                Toggle("Launch at login", isOn: $appState.preferences.launchAtLoginEnabled)
                    .help("Requires a bundled, code-signed app for macOS to honor the login item.")
            }

            Section("Custom Tracking Parameters") {
                Text("These are combined with the bundled defaults.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                List {
                    ForEach(appState.preferences.customParameters, id: \.self) { param in
                        HStack {
                            Text(param)
                            Spacer()
                            Button("Remove", systemImage: "minus.circle") {
                                removeParameter(param)
                            }
                            .buttonStyle(.borderless)
                            .labelStyle(.iconOnly)
                        }
                    }
                }
                .frame(minHeight: 120)

                HStack {
                    TextField("New parameter", text: $customParameterInput)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        addParameter()
                    }
                    .disabled(customParameterInput.isEmpty)
                }

                HStack {
                    Button("Import…") {
                        importRules()
                    }
                    Button("Export…") {
                        exportRules()
                    }
                    Spacer()
                    Button("Reset Defaults") {
                        appState.preferences.restoreDefaults()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 420, minHeight: 360)
    }

    private func addParameter() {
        let trimmed = customParameterInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !appState.preferences.customParameters.contains(trimmed) else { return }
        appState.preferences.customParameters.append(trimmed)
        customParameterInput = ""
    }

    private func removeParameter(_ param: String) {
        appState.preferences.customParameters.removeAll { $0 == param }
    }

    private func importRules() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { result in
            guard result == .OK, let url = panel.url,
                  let data = try? Data(contentsOf: url),
                  let rules = try? JSONDecoder().decode(TrackingRules.self, from: data) else {
                return
            }
            DispatchQueue.main.async {
                self.appState.preferences.customParameters = rules.parameters
            }
        }
    }

    private func exportRules() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "tracking-params.json"
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            let rules = TrackingRules(
                version: 1,
                parameters: self.appState.cleaner.trackedParameters
            )
            guard let data = try? JSONEncoder().encode(rules) else { return }
            try? data.write(to: url)
        }
    }
}
