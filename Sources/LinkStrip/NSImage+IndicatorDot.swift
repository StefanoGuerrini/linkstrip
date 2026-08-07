import AppKit

extension NSImage {
    /// Returns a new template image with a small indicator dot in the bottom-right
    /// corner. Used to signal that LinkStrip is currently the default browser.
    func withIndicatorDot() -> NSImage {
        let size = self.size
        let indicatorRadius = min(size.width, size.height) * 0.18
        let indicatorCenter = NSPoint(
            x: size.width - indicatorRadius * 0.8,
            y: indicatorRadius * 0.8
        )

        let newImage = NSImage(size: size)
        newImage.isTemplate = true

        newImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: size))

        let dotPath = NSBezierPath(ovalIn: NSRect(
            x: indicatorCenter.x - indicatorRadius,
            y: indicatorCenter.y - indicatorRadius,
            width: indicatorRadius * 2,
            height: indicatorRadius * 2
        ))
        dotPath.fill()

        newImage.unlockFocus()
        return newImage
    }
}
