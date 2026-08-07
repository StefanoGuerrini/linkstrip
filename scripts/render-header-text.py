#!/usr/bin/env python3
"""Convert the <text> element in the header SVGs to outlined <path>s using Space Grotesk."""

import re
import xml.etree.ElementTree as ET
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

ASSETS_DIR = Path(__file__).parent.parent / "assets"
FONTS_DIR = ASSETS_DIR / "fonts"

# Space Grotesk files (will be copied here before running).
REGULAR_FONT = FONTS_DIR / "SpaceGrotesk-Regular.ttf"
BOLD_FONT = FONTS_DIR / "SpaceGrotesk-Bold.ttf"

DARK_SVG = ASSETS_DIR / "linkstrip-header.svg"
LIGHT_SVG = ASSETS_DIR / "linkstrip-header-light.svg"

FONT_SIZE = 40


def text_to_paths(text: str, font_path: Path, fill_color: str, start_x: float, baseline_y: float) -> list:
    """Return a list of SVG <path> elements for the given text."""
    font = TTFont(font_path)
    glyph_set = font.getGlyphSet()
    cmap = font['cmap'].getBestCmap()
    units_per_em = font['head'].unitsPerEm
    scale = FONT_SIZE / units_per_em

    # Ascent for baseline alignment.
    ascent = font['hhea'].ascent

    paths = []
    x_offset = 0.0

    for ch in text:
        glyph_name = cmap.get(ord(ch))
        if glyph_name is None:
            x_offset += units_per_em * scale
            continue

        glyph = glyph_set[glyph_name]
        pen = SVGPathPen(glyph_set)
        glyph.draw(pen)
        d = pen.getCommands()

        if d:
            # Translate and scale: flip y to convert font coords to SVG coords.
            transform = (
                f"translate({start_x + x_offset:.2f}, {baseline_y:.2f}) "
                f"scale({scale:.4f}, {-scale:.4f})"
            )
            path = ET.Element("path", {
                "d": d,
                "fill": fill_color,
                "transform": transform,
            })
            paths.append(path)

        x_offset += glyph.width * scale

    return paths


def update_header_svg(svg_path: Path, link_color: str, strip_color: str) -> None:
    """Replace the <text> element in a header SVG with outlined paths."""
    ET.register_namespace("", "http://www.w3.org/2000/svg")
    tree = ET.parse(svg_path)
    root = tree.getroot()

    text_elem = None
    for elem in root.iter():
        if elem.tag == "{http://www.w3.org/2000/svg}text":
            text_elem = elem
            break

    if text_elem is None:
        raise RuntimeError(f"No <text> element found in {svg_path}")

    x = float(text_elem.get("x", "0"))
    y = float(text_elem.get("y", "0"))

    # Insert outlined paths before the text element, then remove the text element.
    index = list(root).index(text_elem)
    link_paths = text_to_paths("Link", REGULAR_FONT, link_color, x, y)
    strip_paths = text_to_paths("Strip", BOLD_FONT, strip_color, x + measure_width("Link", REGULAR_FONT), y)

    for path in link_paths + strip_paths:
        root.insert(index, path)
        index += 1
    root.remove(text_elem)

    tree.write(svg_path, encoding="utf-8", xml_declaration=True)


def measure_width(text: str, font_path: Path) -> float:
    """Return the pixel width of text at FONT_SIZE using the given font."""
    font = TTFont(font_path)
    glyph_set = font.getGlyphSet()
    cmap = font['cmap'].getBestCmap()
    scale = FONT_SIZE / font['head'].unitsPerEm
    width = 0.0
    for ch in text:
        glyph_name = cmap.get(ord(ch))
        if glyph_name is None:
            width += font['head'].unitsPerEm * scale
        else:
            width += glyph_set[glyph_name].width * scale
    return width


def main():
    FONTS_DIR.mkdir(exist_ok=True)

    update_header_svg(DARK_SVG, link_color="#F8FAFC", strip_color="#06B6D4")
    update_header_svg(LIGHT_SVG, link_color="#0F172A", strip_color="#0284C7")

    print(f"Updated header SVGs in {ASSETS_DIR}")


if __name__ == "__main__":
    main()
