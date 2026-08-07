#!/usr/bin/env python3
"""Package the LinkStrip Firefox extension into a distributable .zip."""

import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = ROOT.parent.parent

ASSETS_DIR = PROJECT_ROOT / "assets"
RULES_SOURCE = PROJECT_ROOT / "Sources" / "LinkStrip" / "Resources" / "tracking-params.json"
ICONS = {
    16: ROOT / "icons" / "icon-16.png",
    32: ROOT / "icons" / "icon-32.png",
    48: ROOT / "icons" / "icon-48.png",
    128: ROOT / "icons" / "icon-128.png",
}


def generate_icons() -> None:
    try:
        from PIL import Image
    except ImportError as error:
        raise RuntimeError("Pillow is required to generate icons") from error

    logo = Image.open(ASSETS_DIR / "logo.png").convert("RGBA")
    for size, path in ICONS.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        resized = logo.resize((size, size), Image.LANCZOS)
        resized.save(path, "PNG")


def copy_rules() -> None:
    shutil.copy(RULES_SOURCE, ROOT / "tracking-params.json")


def package() -> list[Path]:
    manifest = json.loads((ROOT / "manifest.json").read_text())
    version = manifest["version"]
    PROJECT_ROOT.joinpath(".build").mkdir(parents=True, exist_ok=True)

    zip_output = PROJECT_ROOT / ".build" / f"linkstrip-firefox-{version}.zip"
    xpi_output = PROJECT_ROOT / ".build" / f"linkstrip-firefox-{version}.xpi"

    _write_archive(zip_output)
    _write_archive(xpi_output)

    return [zip_output, xpi_output]


def _write_archive(output: Path) -> None:
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in ROOT.rglob("*"):
            if path.is_file() and path.name not in ("build-extension.py",) and "__pycache__" not in path.parts:
                archive.write(path, path.relative_to(ROOT))


def main() -> None:
    generate_icons()
    copy_rules()
    outputs = package()
    for output in outputs:
        print(f"Packaged Firefox extension: {output}")


if __name__ == "__main__":
    main()
