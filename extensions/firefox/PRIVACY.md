# LinkStrip Privacy Policy

**Last updated:** 2026-08-07

LinkStrip is a privacy-first browser extension that removes tracking parameters from web links. This privacy policy explains what data the extension accesses and how it is handled.

## Data collection

LinkStrip does **not** collect, transmit, or share any personal data.

The extension operates entirely on your local device:

- It inspects only the URL of the link you right-click.
- It removes known tracking query parameters using a bundled local rule file (`tracking-params.json`).
- The cleaned URL is copied to your clipboard.
- No analytics, telemetry, or network requests are made.

## Permissions

The extension requests the following permissions:

- **contextMenus**: to add the "Copy cleaned LinkStrip URL" item when you right-click a link.
- **clipboardWrite**: to copy the cleaned URL to your clipboard.
- **notifications**: to briefly confirm when a cleaned URL has been copied.

## Third parties

LinkStrip does not communicate with any third-party services.

## Contact

For questions about this privacy policy, open an issue on GitHub:
https://github.com/StefanoGuerrini/linkstrip/issues
