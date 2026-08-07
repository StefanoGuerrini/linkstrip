#!/usr/bin/env python3
"""Generate a 1280x640 GitHub social preview from the app logo."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LOGO_PATH = ROOT / "assets" / "logo.png"
OUTPUT_PATH = ROOT / "assets" / "social-preview.png"

# LinkStrip landing-page palette
BACKGROUND = (11, 17, 32)  # #0B1120
SIZE = (1280, 640)


def main() -> None:
    logo = Image.open(LOGO_PATH).convert("RGBA")

    # Resize logo to fit comfortably inside the 2:1 preview.
    max_height = int(SIZE[1] * 0.75)
    logo.thumbnail((max_height, max_height), Image.LANCZOS)

    canvas = Image.new("RGBA", SIZE, BACKGROUND)
    x = (SIZE[0] - logo.width) // 2
    y = (SIZE[1] - logo.height) // 2
    canvas.paste(logo, (x, y), logo)

    canvas.save(OUTPUT_PATH, "PNG")
    print(f"Saved {OUTPUT_PATH} ({SIZE[0]}x{SIZE[1]})")


if __name__ == "__main__":
    main()
