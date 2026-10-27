"""Resize all images in a source folder to a given percentage of their original size
or to a fixed size of the longer side.

Usage:
    python resize.py <percent|%> [source_folder]   e.g. 50 or 50%
    python resize.py <sizexp> [source_folder]      e.g. 800px

- percent: scale factor (e.g. 50 for half size). A bare number or "%"-suffixed number.
- size: target length of the longer image side in px, suffixed with "px" (e.g. 800px).
  The other side keeps the aspect ratio.
- source_folder: folder with images to resize, default "original"
  (relative to this script's directory).
- Resized files are written to this script's directory, keeping the original filenames.
"""
import sys
from pathlib import Path

from PIL import Image, ImageOps, UnidentifiedImageError

SCRIPT_DIR = Path(__file__).resolve().parent
JPEG_FORMATS = {"JPEG", "MPO"}


def parse_target(value: str) -> tuple[str, float]:
    """Return (mode, amount) where mode is "percent" or "long_side"."""
    if value.lower().endswith("px"):
        try:
            size = float(value[:-2])
        except ValueError:
            sys.exit(f"Invalid size: {value}")
        if size <= 0:
            sys.exit("Size must be greater than 0.")
        return "long_side", size
    try:
        percent = float(value.rstrip("%"))
    except ValueError:
        sys.exit(f"Invalid percent: {value}")
    if percent <= 0:
        sys.exit("Percent must be greater than 0.")
    if percent > 100:
        sys.exit("Percent must be less than or equal to 100.")
    return "percent", percent / 100


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("Usage: python resize.py <percent | percent% | longest-sidepx> [source_folder]")
    mode, amount = parse_target(sys.argv[1])

    source = Path(sys.argv[2]) if len(sys.argv) > 2 else SCRIPT_DIR / "original"
    if not source.is_absolute():
        source = SCRIPT_DIR / source
    if not source.is_dir():
        sys.exit(f"Source folder not found: {source}")

    resized = skipped = 0
    for path in sorted(source.iterdir()):
        if not path.is_file():
            continue
        output = SCRIPT_DIR / path.name
        if output == path:
            print(f"Skip (output would overwrite source): {path.name}")
            skipped += 1
            continue
        try:
            with Image.open(path) as img:
                img = ImageOps.exif_transpose(img)
                if mode == "long_side":
                    scale = amount / max(img.width, img.height)
                    size = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
                else:
                    size = (max(1, round(img.width * amount)), max(1, round(img.height * amount)))
                resized_img = img.resize(size, Image.LANCZOS)
                if img.format in JPEG_FORMATS:
                    resized_img.save(output, quality=90)
                else:
                    resized_img.save(output)
        except UnidentifiedImageError:
            print(f"Skip (not an image): {path.name}")
            skipped += 1
            continue
        resized += 1
        print(f"Resized: {path.name} -> {size[0]}x{size[1]}")

    print(f"Done. Resized: {resized}, skipped: {skipped}")


if __name__ == "__main__":
    main()
