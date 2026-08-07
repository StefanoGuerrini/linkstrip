# Publishing LinkStrip

This document covers the official ways to distribute LinkStrip, the requirements for each channel, and the recommended release workflow.

## Distribution channels

### 1. GitHub Releases (recommended)

The simplest channel for an open-source, privacy-first utility.

**Pros**
- Full control over releases and release notes.
- Supports default-browser handling and the Share extension without extra App Store restrictions.
- No review process.

**Cons**
- Users must download and install manually (or via a package manager like Homebrew).
- macOS Gatekeeper requires the app to be signed and notarized for a smooth first launch on macOS 10.15+.

**Requirements**
- Apple Developer Program membership ($99/year).
- A Developer ID Application certificate.
- Notarization via `xcrun notarytool`.

### 2. Mac App Store

Possible, but restrictive for LinkStrip's use case.

**Pros**
- Discoverability and automatic updates for users.
- No notarization step (App Store review handles distribution).

**Cons**
- Default-browser handling is effectively impossible: Mac App Store apps cannot register as the default handler for `http`/`https` without special entitlements that Apple rarely grants to utilities.
- The Share extension can still work, so the app would be limited to clipboard cleaning and Share-extension cleaning.
- Strict sandboxing may complicate launching the user's preferred browser from the app.

**Recommendation**
Skip the Mac App Store unless you are willing to remove the default-browser click-cleaning feature.

### 3. Homebrew Cask

A convenient discoverability layer on top of GitHub Releases.

**Pros**
- Users can install with `brew install --cask linkstrip`.
- No extra signing or notarization burden beyond the GitHub Releases build.

**Cons**
- Requires submitting and maintaining a cask formula in `Homebrew/homebrew-cask` or a custom tap.

**Requirements**
- A stable, versioned download URL (e.g., `https://github.com/StefanoGuerrini/linkstrip/releases/download/v1.2.0/LinkStrip.app.zip`).
- A publicly accessible appcast or manual version bumps.

## Code signing and notarization

For distribution outside the Mac App Store, sign the release .app with a Developer ID Application certificate and submit it to Apple for notarization.

### 1. Export certificates

In Xcode or the Apple Developer portal, download and install:
- Developer ID Application certificate
- Developer ID Installer certificate (optional, for .pkg)

### 2. Sign the app bundle

```bash
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
         --options runtime \
         --deep \
         --force \
         --entitlements LinkStrip.entitlements \
         LinkStrip.app
```

The `--options runtime` flag enables the hardened runtime, which is required for notarization.

### 3. Notarize

Create a ZIP archive and submit it:

```bash
cd .build
zip -ry LinkStrip.app.zip LinkStrip.app

xcrun notarytool submit LinkStrip.app.zip \
    --keychain-profile "AC_PASSWORD" \
    --wait
```

`AC_PASSWORD` is a keychain profile storing your App Store Connect API key. Store the API key in Keychain Access first:

```bash
xcrun notarytool store-credentials "AC_PASSWORD" \
    --apple-id "your@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password"
```

### 4. Staple the ticket

After notarization succeeds, staple the ticket to the app bundle:

```bash
xcrun stapler staple .build/LinkStrip.app
```

Then re-zip the stapled bundle for upload to GitHub Releases.

## Release workflow

The repository includes a GitHub Actions workflow (`.github/workflows/release.yml`) that:

1. Builds the project with `swift build`.
2. Runs `swift test`.
3. Packages `.build/LinkStrip.app` with `make app`.
4. Zips the bundle.
5. Creates a GitHub Release and attaches the ZIP.

This workflow produces an ad-hoc signed build. For an official release, either:
- Add code-signing certificates and notarization steps to the workflow using GitHub Secrets, or
- Build and notarize locally, then upload the artifact manually.

## Entitlements

The current entitlements file (`LinkStrip.entitlements`) enables the app sandbox and user-selected file read/write access for importing/exporting rule files:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

No network entitlement is included because LinkStrip makes no outbound connections.

## Versioning

LinkStrip follows [Semantic Versioning](https://semver.org/):

- `MAJOR` – breaking changes or removal of supported macOS versions.
- `MINOR` – new features (e.g., Share extension, new cleaning rules).
- `PATCH` – bug fixes.

Update the version in:
- `Info.plist` (`CFBundleShortVersionString` and `CFBundleVersion`)
- `ShareExtension/Info.plist`
- `CHANGELOG.md`
- Git tag (e.g., `v1.2.0`)

## Summary recommendation

1. Use **GitHub Releases** as the primary distribution channel.
2. Sign and notarize every stable release with a Developer ID.
3. Add a **Homebrew Cask** formula once releases are stable.
4. Avoid the **Mac App Store** unless you are willing to drop default-browser click cleaning.
