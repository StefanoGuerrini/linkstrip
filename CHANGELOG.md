# Changelog

All notable changes to LinkStrip will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-08-07

### Added
- Optional "Clean links when clicked" mode. LinkStrip can register itself as the default browser, clean clicked http/https URLs, and forward them to the user's real browser.
- Default-browser intelligence: caches the previous default browser, shows a "Restore Previous Browser" button in Preferences, and displays a dot on the menu-bar icon while LinkStrip is the default browser.
- Built-in Share extension: right-click any link → Share → LinkStrip cleans the URL and copies it to the clipboard without changing the default browser.
- Custom monochrome menu-bar template icon based on the app logo.
- Landing page (`docs/index.html`) and `docs/llm.txt` for discoverability.
- `PUBLISHING.md` guide covering GitHub Releases, Mac App Store, Homebrew Cask, signing, and notarization.

## [1.1.0] - 2026-08-07

### Added
- Redirect-link unwrapping: extracts and cleans destination URLs from click-tracking services such as `link.fndrsp.net`.
- Separate toggles for "Clean copied links" and "Clean redirect links".
- In-app viewer for the default tracking parameter list in Preferences.
- `emailLog` added to the default tracking parameters.

## [1.0.0] - 2026-08-07

### Added
- Initial release of LinkStrip.
- Menu-bar clipboard monitor that strips tracking parameters from copied URLs.
- Bundled `tracking-params.json` rule engine with 28 default parameters.
- Editable custom tracking parameters with import/export support.
- Local history of the last 100 cleaned URLs.
- Native macOS notifications with a toggle in preferences.
- Launch at login support via `SMAppService`.
- Minimal app icon and logo.
- MIT license.
