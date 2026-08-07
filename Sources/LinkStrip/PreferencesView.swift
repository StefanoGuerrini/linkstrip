import SwiftUI

/// Preferences window for toggles, rule editing, and import/export.
struct PreferencesView: View {
    @EnvironmentObject var appState: AppState

    @State private var customParameterInput = ""

    var body: some View {
        Form {
            Section("Clipboard") {
                Toggle("Clean copied links", isOn: $appState.preferences.cleanCopiedLinks)
                    .help("Strip tracking parameters from URLs copied to the clipboard.")
                Toggle("Clean redirect links", isOn: $appState.preferences.cleanRedirectLinks)
                    .help("Extract and clean destination URLs from click-tracking/redirect services.")
                Toggle("Show notifications", isOn: $appState.preferences.notificationsEnabled)
            }

            Section("Clicks") {
                Toggle("Clean links when clicked", isOn: $appState.preferences.cleanLinksOnOpen)
                    .help("Requires setting LinkStrip as the default browser in System Settings.")

                Text("To clean clicked links, set LinkStrip as the default web browser in System Settings → Desktop & Dock. LinkStrip will intercept the click, clean the URL, and forward it to your previously selected browser.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    if BrowserRouter.shared.isLinkStripDefaultBrowser {
                        Text("LinkStrip is currently the default browser")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if let browser = BrowserRouter.shared.savedBrowserBundleID {
                        Text("Default browser will be restored to \(browser)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Restore Previous Browser") {
                        BrowserRouter.shared.restorePreviousBrowser()
                    }
                    .disabled(BrowserRouter.shared.savedBrowserBundleID == nil)
                }
            }

            Section("General") {
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
                .frame(minHeight: 80)

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

            Section("Default Tracking Parameters") {
                Text("Parameters removed automatically from every copied link.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                List(appState.cleaner.trackedParameters, id: \.self) { param in
                    Text(param)
                }
                .frame(minHeight: 160)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 460, minHeight: 620)
    }

    private func addParameter() {
        let trimmed = customParameterInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !appState.preferences.customParameters.contains(trimmed),
              !appState.cleaner.trackedParameters.contains(trimmed) else { return }
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
