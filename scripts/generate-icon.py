#!/usr/bin/env python3
"""Render raster assets from the SVG source files in assets/."""

from pathlib import Path

import cairosvg

ASSETS_DIR = Path(__file__).parent.parent / "assets"
ICONSET_DIR = ASSETS_DIR / "AppIcon.iconset"

LOGO_SVG = ASSETS_DIR / "logo.svg"
MENU_BAR_SVG = ASSETS_DIR / "menu-bar-icon.svg"
HEADER_SVG = ASSETS_DIR / "linkstrip-header.svg"

ICONSET_SIZES = [
    (16, "16x16"),
    (32, "16x16@2x"),
    (32, "32x32"),
    (64, "32x32@2x"),
    (128, "128x128"),
    (256, "128x128@2x"),
    (256, "256x256"),
    (512, "256x256@2x"),
    (512, "512x512"),
    (1024, "512x512@2x"),
]


def render_svg(svg_path: Path, output_path: Path, width: int, height: int) -> None:
    """Render an SVG to a PNG at the requested size."""
    cairosvg.svg2png(
        url=str(svg_path),
        write_to=str(output_path),
        output_width=width,
        output_height=height,
    )


def main():
    ASSETS_DIR.mkdir(exist_ok=True)
    ICONSET_DIR.mkdir(exist_ok=True)

    # Clean up stale outputs.
    for f in ICONSET_DIR.glob("*.png"):
        f.unlink()
    for name in ["logo.png", "header.png", "MenuBarIcon.png", "MenuBarIcon@2x.png"]:
        p = ASSETS_DIR / name
        if p.exists():
            p.unlink()

    print("Rendering app icon set...")
    for pixel_size, name in ICONSET_SIZES:
        render_svg(LOGO_SVG, ICONSET_DIR / f"icon_{name}.png", pixel_size, pixel_size)

    print("Rendering README logo...")
    render_svg(LOGO_SVG, ASSETS_DIR / "logo.png", 1024, 1024)

    print("Rendering README header...")
    render_svg(HEADER_SVG, ASSETS_DIR / "header.png", 800, 180)

    print("Rendering menu bar icons...")
    render_svg(MENU_BAR_SVG, ASSETS_DIR / "MenuBarIcon.png", 22, 22)
    render_svg(MENU_BAR_SVG, ASSETS_DIR / "MenuBarIcon@2x.png", 44, 44)

    print(f"Assets rendered in {ASSETS_DIR}")


if __name__ == "__main__":
    main()
