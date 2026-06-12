"""Trim outer white canvas from app icon and save transparent PNG."""
from collections import deque
from pathlib import Path

from PIL import Image

SRC = Path(
    r"C:\Users\Eliezer\.cursor\projects\c-Users-Eliezer-Desktop-toofty\assets"
    r"\c__Users_Eliezer_AppData_Roaming_Cursor_User_workspaceStorage_eaf759bb4e260cce753b501042b38092_images"
    r"_ChatGPT_Image_Jun_11__2026__02_38_48_PM-fe7b3e9d-2c8c-4f3b-9920-4e689b2128be.png"
)
OUT = Path(__file__).resolve().parents[1] / "assets" / "images" / "app_icon.png"


def is_outer_background(r: int, g: int, b: int, a: int) -> bool:
    if a < 10:
        return True
    brightness = (r + g + b) / 3
    # White canvas and soft drop shadow connected to the edges.
    return brightness >= 205 and max(r, g, b) - min(r, g, b) < 45


def flood_remove_background(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    seen: set[tuple[int, int]] = set()
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or x < 0 or y < 0 or x >= width or y >= height:
            continue
        seen.add((x, y))
        r, g, b, a = pixels[x, y]
        if not is_outer_background(r, g, b, a):
            continue
        pixels[x, y] = (0, 0, 0, 0)
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    return rgba


def main() -> None:
    source = Image.open(SRC)
    trimmed = flood_remove_background(source)
    bbox = trimmed.getbbox()
    if not bbox:
        raise RuntimeError("Icon trim removed all pixels")

    cropped = trimmed.crop(bbox)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(OUT, optimize=True)
    print(f"Saved trimmed icon: {OUT} ({cropped.size[0]}x{cropped.size[1]})")


if __name__ == "__main__":
    main()
