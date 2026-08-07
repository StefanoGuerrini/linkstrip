<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/linkstrip-header.svg">
    <source media="(prefers-color-scheme: light)" srcset="assets/linkstrip-header-light.svg">
    <img alt="LinkStrip" src="assets/linkstrip-header-light.svg" width="400">
  </picture>
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
- **Share extension** – right-click any link → Share → LinkStrip to clean it without changing your default browser.
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

Unsigned development builds and ad-hoc signed releases may trigger Gatekeeper. Right-click the app and choose **Open** if macOS warns you. Official releases should be signed with a Developer ID and notarized before distribution. See [PUBLISHING.md](PUBLISHING.md) for details.

## Cleaning clicked links

By default LinkStrip only watches the clipboard. To clean links when you click them in Mail, Notes, or anywhere else:

1. Open **System Settings → Desktop & Dock → Default web browser** and select **LinkStrip**.
2. Open LinkStrip Preferences and enable **Clean links when clicked**.
3. LinkStrip intercepts every clicked `http`/`https` URL, cleans it, and forwards it to your previously selected browser.

When you enable click cleaning, LinkStrip remembers your previous default browser and shows a **Restore Previous Browser** button in Preferences. The menu-bar icon also displays a small dot while LinkStrip is the default browser, so you don't forget.

> **Note:** macOS does not allow apps to change the default browser automatically, so this step must be done manually in System Settings.

## Share extension

If you prefer not to change your default browser, use the built-in Share extension:

1. Right-click any link in Mail, Safari, Notes, or most other apps.
2. Choose **Share → LinkStrip**.
3. The cleaned URL is copied to your clipboard.

The Share extension is included in `LinkStrip.app/Contents/PlugIns/LinkStripShareExtension.appex` and is registered automatically when the app is first launched.

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

# Build and package a release .app bundle
make app

# If you changed the SVG sources and want to regenerate raster assets:
make app-with-icons
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

## Publishing

LinkStrip can be distributed through GitHub Releases, the Mac App Store, or Homebrew Cask. Each channel has different trade-offs. See [PUBLISHING.md](PUBLISHING.md) for a full guide.

## Version history

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Credits

- Created by [Stefano Guerrini](https://github.com/StefanoGuerrini)
- Logo, menu-bar icon, header, and light-mode variants by Stefano Guerrini
- MIT Licensed

## Privacy

- No network access is requested or performed.
- Clipboard contents are inspected locally and never transmitted.
- Only the original and cleaned URL are stored in the local history file.
- History is limited to the most recent 100 entries and can be cleared at any time.

## License

MIT License. See [LICENSE](LICENSE) for details.
