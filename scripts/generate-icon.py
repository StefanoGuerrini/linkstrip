#!/usr/bin/env python3
"""Generate a minimal LinkStrip app icon set from a vector-style drawing."""

import math
from pathlib import Path

from PIL import Image, ImageDraw

ASSETS_DIR = Path(__file__).parent.parent / "assets"
ICONSET_DIR = ASSETS_DIR / "AppIcon.iconset"
MASTER_SIZE = 4096

SIZES = [
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


def linear_gradient(size, top_color, bottom_color):
    """Create a vertical linear gradient image."""
    img = Image.new("RGB", size)
    width, height = size
    for y in range(height):
        ratio = y / max(height - 1, 1)
        r = int(top_color[0] * (1 - ratio) + bottom_color[0] * ratio)
        g = int(top_color[1] * (1 - ratio) + bottom_color[1] * ratio)
        b = int(top_color[2] * (1 - ratio) + bottom_color[2] * ratio)
        for x in range(width):
            img.putpixel((x, y), (r, g, b))
    return img


def draw_smooth_ellipse_ring(draw, center, rx, ry, thickness, color, steps=480):
    """Draw an anti-aliased elliptical ring by stroking a high-res polygon."""
    cx, cy = center
    outer = []
    inner = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        cos_t = math.cos(t)
        sin_t = math.sin(t)
        ox = cx + rx * cos_t
        oy = cy + ry * sin_t
        ix = cx + (rx - thickness) * cos_t
        iy = cy + (ry - thickness) * sin_t
        outer.append((ox, oy))
        inner.append((ix, iy))
    draw.polygon(outer + inner[::-1], fill=color)


def draw_chain_link(draw, center, radius, thickness, color):
    """Draw two interlocking elliptical links at 45 degrees."""
    cx, cy = center
    angle = math.radians(45)
    offset = radius * 0.42

    def rotated_center(dx, dy):
        return cx + dx * math.cos(angle) - dy * math.sin(angle), \
               cy + dx * math.sin(angle) + dy * math.cos(angle)

    rx = radius
    ry = radius * 0.34

    # Back link (drawn first).
    back_x, back_y = rotated_center(-offset, offset)
    draw_smooth_ellipse_ring(draw, (back_x, back_y), rx, ry, thickness, color)

    # Front link with a small gap to suggest "cutting" / stripping.
    front_x, front_y = rotated_center(offset, -offset)
    draw_smooth_ellipse_ring(draw, (front_x, front_y), rx, ry, thickness, color)

    # Small diagonal strike through the front link.
    gap = radius * 0.12
    strike_color = (255, 255, 255)
    draw.line(
        [(front_x - gap, front_y - gap), (front_x + gap, front_y + gap)],
        fill=strike_color,
        width=thickness,
    )


def generate_master_icon():
    """Render the app icon at a very high resolution for smooth downsampling."""
    size = MASTER_SIZE
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Background gradient.
    bg = linear_gradient((size, size), (59, 130, 246), (99, 102, 241))  # blue -> indigo
    bg.putalpha(255)
    img.paste(bg, (0, 0))

    draw = ImageDraw.Draw(img)

    # Rounded mask for the icon shape.
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner = size // 5
    mask_draw.rounded_rectangle((0, 0, size, size), radius=corner, fill=255)
    img.putalpha(mask)

    # Subtle inner highlight ring.
    pad = size // 64
    draw.rounded_rectangle(
        (pad, pad, size - pad, size - pad),
        radius=corner - pad,
        outline=(255, 255, 255, 50),
        width=size // 128,
    )

    # Chain-link symbol.
    center = (size // 2, size // 2)
    link_radius = size * 0.20
    thickness = size // 28
    draw_chain_link(draw, center, link_radius, thickness, (255, 255, 255, 255))

    return img


def draw_menu_bar_link(draw, center, size, color):
    """Draw a bold, simplified chain-link symbol suitable for the menu bar."""
    cx, cy = center
    stroke = max(3, size // 7)
    pad = size * 0.18
    w = size * 0.32
    h = size * 0.55

    # Two overlapping rounded rectangles rotated 45 degrees.
    for dx, dy in [(-pad, pad), (pad, -pad)]:
        rect = (
            cx + dx - w // 2,
            cy + dy - h // 2,
            cx + dx + w // 2,
            cy + dy + h // 2,
        )
        # Draw the outline as a thick polygon.
        points = [
            (rect[0] + stroke, rect[1]),
            (rect[2] - stroke, rect[1]),
            (rect[2], rect[1] + stroke),
            (rect[2], rect[3] - stroke),
            (rect[2] - stroke, rect[3]),
            (rect[0] + stroke, rect[3]),
            (rect[0], rect[3] - stroke),
            (rect[0], rect[1] + stroke),
        ]
        draw.polygon(points, fill=color)


def generate_menu_bar_icon(size):
    """Render a monochrome menu-bar template icon (bold chain link on transparent)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = (size // 2, size // 2)
    draw_menu_bar_link(draw, center, size, (255, 255, 255, 255))

    return img


def main():
    ASSETS_DIR.mkdir(exist_ok=True)
    ICONSET_DIR.mkdir(exist_ok=True)

    # Remove stale files.
    for f in ICONSET_DIR.glob("*.png"):
        f.unlink()
    for f in ASSETS_DIR.glob("logo.png"):
        f.unlink()
    for f in ASSETS_DIR.glob("MenuBarIcon*.png"):
        f.unlink()

    print("Rendering master icon...")
    master = generate_master_icon()

    for pixel_size, name in SIZES:
        icon = master.resize((pixel_size, pixel_size), Image.Resampling.LANCZOS)
        icon.save(ICONSET_DIR / f"icon_{name}.png", "PNG")

    logo = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    logo.save(ASSETS_DIR / "logo.png", "PNG")

    print("Rendering menu bar icon...")
    menu_bar_1x = generate_menu_bar_icon(22)
    menu_bar_1x.save(ASSETS_DIR / "MenuBarIcon.png", "PNG")
    menu_bar_2x = generate_menu_bar_icon(44)
    menu_bar_2x.save(ASSETS_DIR / "MenuBarIcon@2x.png", "PNG")

    print(f"Generated icon set in {ICONSET_DIR}")
    print(f"Generated README logo at {ASSETS_DIR / 'logo.png'}")
    print(f"Generated menu bar icons at {ASSETS_DIR / 'MenuBarIcon.png'}")


if __name__ == "__main__":
    main()
