# LinkStrip for Firefox

A Firefox extension that removes tracking parameters from links, matching the behavior of the [macOS LinkStrip app](https://github.com/StefanoGuerrini/linkstrip).

## Features

- **Right-click any link → Copy cleaned LinkStrip URL** — strips tracking parameters and copies the clean URL to your clipboard.
- Uses the same `tracking-params.json` rule file as the macOS app.
- Fully offline — no network calls.

## Install from source

1. Build the extension:
   ```bash
   cd extensions/firefox
   python3 build-extension.py
   ```
2. Open Firefox and go to `about:debugging#/runtime/this-firefox`.
3. Click **Load Temporary Add-on…**.
4. Select `.build/linkstrip-firefox-1.3.2.zip`.

## Files

- `manifest.json` — extension manifest
- `cleaner.js` — URL cleaning engine (JavaScript port of the Swift `URLCleaner`)
- `background.js` — context-menu handler
- `tracking-params.json` — shared rule file, copied from the macOS app at build time

## Privacy

- No analytics, no telemetry, no outbound requests.
- Only the link you right-click is inspected locally.
