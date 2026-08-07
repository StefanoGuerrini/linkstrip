# Publishing LinkStrip on addons.mozilla.org (AMO)

This guide covers submitting the LinkStrip Firefox extension to the Mozilla Add-ons marketplace.

## Before you submit

1. Make sure the extension builds cleanly:
   ```bash
   make firefox-extension
   ```
   This produces:
   - `.build/linkstrip-firefox-1.4.0.zip`
   - `.build/linkstrip-firefox-1.4.0.xpi`

2. Review the generated files:
   ```bash
   unzip -l .build/linkstrip-firefox-1.4.0.xpi
   ```

## AMO submission steps

1. **Create or log in to a Firefox Account** at https://accounts.firefox.com
2. Go to the Firefox Developer Hub: https://addons.mozilla.org/developers/
3. Click **Submit or Manage Extensions** → **Submit a New Add-on**
4. Upload `.build/linkstrip-firefox-1.4.0.xpi`
5. Choose distribution:
   - **Listed on AMO** — public listing in the Firefox Add-ons store.
   - **On your own** — AMO signs the `.xpi` but does not list it publicly. Use this if you want to host the signed file on GitHub Releases only.
6. Fill in the listing details:
   - **Name:** LinkStrip
   - **Summary:** Remove tracking parameters from links. Privacy-first and offline.
   - **Description:** Explain the right-click workflow, offline rule engine, and link to the macOS app.
   - **Categories:** Privacy & Security, Productivity
   - **Support email/URL:** https://github.com/StefanoGuerrini/linkstrip/issues
   - **Privacy policy:** Link to `extensions/firefox/PRIVACY.md` on GitHub, e.g. `https://github.com/StefanoGuerrini/linkstrip/blob/main/extensions/firefox/PRIVACY.md`
   - **Icon:** already included in the package
   - **Screenshots:** upload at least one screenshot showing the right-click context menu with "Copy cleaned LinkStrip URL"
7. Submit for review.

## Review

AMO review usually takes from a few hours to a couple of days. Because LinkStrip:
- Uses no remote code
- Makes no network requests
- Has no analytics or telemetry
- Uses a clear, readable background script

the review should be straightforward.

## After approval

### Listed on AMO
Users can install directly from the AMO page.

### Self-distributed
1. Download the signed `.xpi` from AMO.
2. Attach it to the GitHub Release alongside `LinkStrip.app.zip`.
3. Update the release notes with the Firefox extension install link.

## Updating the extension

1. Bump the version in `extensions/firefox/manifest.json`.
2. Rebuild with `make firefox-extension`.
3. Submit the new `.xpi` to AMO as an update.
