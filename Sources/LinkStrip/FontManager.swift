import AppKit
import CoreText

/// Loads the bundled Space Grotesk fonts so they can be used in SwiftUI.
enum FontManager {
    static func registerBundledFonts() {
        let fontNames = ["SpaceGrotesk-Regular.ttf", "SpaceGrotesk-Bold.ttf"]
        for name in fontNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
                NSLog("Font \(name) not found in bundle")
                continue
            }
            var error: Unmanaged<CFError>?
            guard CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) else {
                if let error = error?.takeRetainedValue() {
                    NSLog("Failed to register font \(name): \(error)")
                }
                continue
            }
        }
    }
}
