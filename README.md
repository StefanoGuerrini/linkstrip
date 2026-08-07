# LinkStrip

A privacy-first, minimalistic macOS menu-bar app that automatically removes tracking parameters from URLs copied to the clipboard. It is a drop-in, open-source replacement for TrackerZapper.

![Screenshot placeholder](screenshot.png)

## Features

- **Silent clipboard monitor** – sits in the menu bar and cleans links as soon as they are copied.
- **Local rule engine** – bundled `tracking-params.json`; no network calls, ever.
- **Editable rules** – add custom parameters or import/export your own JSON rule sets.
- **History** – keeps the last 100 cleaned URLs locally in `~/Library/Application Support/LinkStrip/history.json`.
- **Native notifications** – brief banner when a link is cleaned (toggle in preferences).
- **Launch at login** – uses `SMAppService` (requires a code-signed app bundle).
- **Sandboxed & offline** – zero outbound network requests, no analytics, no telemetry.

## Supported platforms

- macOS 13 Ventura and later
- Apple Silicon & Intel (Universal build via `swift build`)

## Default tracking parameters

The bundled rule file removes the following query parameters:

- `affiliate`
- `cmpid`
- `dclid`
- `fbclid`
- `feature`
- `gbraid`
- `gclid`
- `irclickid`
- `itm_campaign`, `itm_content`, `itm_medium`, `itm_source`, `itm_term`
- `mc_cid`
- `ocid`
- `ref_src`, `ref_url`
- `si`
- `trackingId`
- `trk`
- `ttclid`
- `utm_campaign`, `utm_content`, `utm_medium`, `utm_source`, `utm_term`
- `wbraid`
- `wickedid`

Add your own in **Preferences → Custom Tracking Parameters**.

## Build from source

Requires Xcode 15+ or the Swift 5.9+ toolchain on macOS 13+.

```bash
# Debug build
make build

# Run tests
make test

# Build and package a release .app bundle
make app
```

The release app will be created at `.build/LinkStrip.app`. You can drag it to `/Applications`.

### Manual Swift Package Manager commands

```bash
swift build
swift test
swift build -c release
```

## Distribution signing

The project builds and runs unsigned for local development. For distribution:

1. Replace the `CFBundleIdentifier` in `Info.plist` with your own identifier.
2. Sign and notarize with your Apple Developer ID:

```bash
codesign --sign "Developer ID Application: Your Name" \
  --force --deep --options runtime \
  --entitlements LinkStrip.entitlements \
  .build/LinkStrip.app
```

## Privacy

- No network access is requested or performed.
- Clipboard contents are inspected locally and never transmitted.
- Only the original and cleaned URL are stored in the local history file.
- History is limited to the most recent 100 entries and can be cleared at any time.

## Architecture

The code is organized into focused types:

- `AppDelegate` – app lifecycle, menu-bar-only activation.
- `AppState` – wires preferences, cleaner, monitor, history, and notifications.
- `ClipboardMonitor` – lightweight pasteboard polling via `changeCount`.
- `URLCleaner` – strips tracking query parameters using bundled JSON rules.
- `PreferencesManager` – `UserDefaults` wrapper for toggles and custom rules.
- `HistoryManager` – local JSON persistence of cleaned links.
- `NotificationManager` – local UserNotifications.
- `LaunchAtLoginManager` – `SMAppService` registration.
- `MenuBarController` – `NSStatusItem` and dropdown menu.
- `PreferencesView` / `HistoryView` – SwiftUI windows.

## License

MIT License. See [LICENSE](LICENSE) for details.
