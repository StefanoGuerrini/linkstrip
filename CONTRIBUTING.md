# Contributing to LinkStrip

Thank you for your interest in contributing! This is a small, focused project, so keeping changes minimal and well-scoped helps everyone.

## How to contribute

1. Fork the repository and create a feature branch.
2. Make your changes.
3. Add or update tests in `Tests/LinkStripTests/` if the core engine changes.
4. Run `make build` and `make test` locally.
5. Submit a pull request with a clear description.

## Project conventions

- **Language**: Swift 5.9+ with SwiftUI for UI and AppKit for the menu bar.
- **macOS target**: 13.0+ (Ventura and later).
- **No network**: Do not add code that makes outbound network requests.
- **No telemetry**: Do not add analytics or crash reporters that phone home.
- **Minimal dependencies**: Prefer built-in Apple frameworks.
- **Privacy first**: Clipboard data must never leave the device.

## Building

```bash
make build   # debug build
make test    # run unit tests
make app     # package a release .app bundle
```

## Reporting bugs

When reporting a bug, please include:

- macOS version
- Mac architecture (Apple Silicon or Intel)
- Steps to reproduce
- Example URL that was not cleaned correctly (if applicable)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
