<p align="center">
  <img src="assets/header.png" width="400" height="90" alt="LinkStrip">
</p>

<p align="center">
  A privacy-first, minimalistic macOS menu-bar app that automatically removes tracking parameters from URLs copied to the clipboard.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey" alt="macOS 13+">
  <img src="https://img.shields.io/badge/arch-arm64%20%7C%20x86_64-blue" alt="Apple Silicon & Intel">
</p>

---

## Features

- **Silent clipboard monitor** – sits in the menu bar and cleans links as soon as they are copied.
- **Redirect-link unwrapping** – extracts real destinations from click-tracking services like `link.fndrsp.net`.
- **Clean clicked links** *(optional)* – set LinkStrip as the default browser; clicked links are cleaned and forwarded to your real browser.
- **Three independent toggles** – enable or disable cleaning for copied links, redirect links, and clicked links separately.
- **Local rule engine** – bundled `tracking-params.json`; no network calls, ever.
- **Editable rules** – add custom parameters, view the bundled defaults, or import/export your own JSON rule sets.
- **History** – keeps the last 100 cleaned URLs locally in `~/Library/Application Support/LinkStrip/history.json`.
- **Native notifications** – brief banner when a link is cleaned (toggle in preferences).
- **Launch at login** – uses `SMAppService` (requires a code-signed app bundle).
- **Sandboxed & offline** – zero outbound network requests, no analytics, no telemetry.

## Supported platforms

- macOS 13 Ventura and later
- Apple Silicon & Intel

## Screenshot

*Screenshot placeholder – replace `screenshot.png` in the repo root with an actual capture.*

## Default tracking parameters

The bundled rule file removes the following query parameters:

- `affiliate`
- `cmpid`
- `dclid`
- `emailLog`
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

## Install

Download the latest release from [GitHub Releases](https://github.com/StefanoGuerrini/LinkStrip/releases), drag `LinkStrip.app` to `/Applications`, and launch it.

Because the release builds are code-signed but notarized releases may still trigger Gatekeeper on first run, right-click the app and choose **Open** if macOS warns you.

## Cleaning clicked links

By default LinkStrip only watches the clipboard. To clean links when you click them in Mail, Notes, or anywhere else:

1. Open **System Settings → Desktop & Dock → Default web browser** and select **LinkStrip**.
2. Open LinkStrip Preferences and enable **Clean links when clicked**.
3. LinkStrip intercepts every clicked `http`/`https` URL, cleans it, and forwards it to your previously selected browser.

To stop, set your previous browser back as the default in System Settings.

> **Note:** macOS does not allow apps to change the default browser automatically, so this step must be done manually in System Settings.

## Build from source

Requires Xcode 15+ or the Swift 5.9+ toolchain on macOS 13+.

```bash
# Clone the repository
git clone https://github.com/StefanoGuerrini/LinkStrip.git
cd LinkStrip

# Debug build
make build

# Run tests
make test

# Build and package a release .app bundle (also regenerates the icon set)
make app
```

The release app is created at `.build/LinkStrip.app`. You can drag it to `/Applications`.

### Manual Swift Package Manager commands

```bash
swift build
swift test
swift build -c release
```

## Tests

The test suite lives in `Tests/LinkStripTests/` and covers the core `URLCleaner` engine:

- Removing single and multiple tracking parameters
- Preserving non-tracking query parameters
- Handling URLs that contain only tracking parameters
- Returning the original URL unchanged when no tracking parameters are present
- Rejecting malformed input
- Extracting and cleaning destinations from redirect/click-tracking links

Run tests with:

```bash
make test
```

## Version history

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Credits

- Created by [Stefano Guerrini](https://github.com/StefanoGuerrini)
- Logo, menu-bar icon, and header by Stefano Guerrini
- MIT Licensed

## Privacy

- No network access is requested or performed.
- Clipboard contents are inspected locally and never transmitted.
- Only the original and cleaned URL are stored in the local history file.
- History is limited to the most recent 100 entries and can be cleared at any time.

## License

MIT License. See [LICENSE](LICENSE) for details.
