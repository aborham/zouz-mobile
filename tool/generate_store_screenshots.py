#!/usr/bin/env python3
"""Generate branded App Store and Google Play screenshots from real app captures."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


APPLE_PHONE = (1290, 2796)
APPLE_TABLET = (2048, 2732)
GOOGLE_PHONE = (1080, 1920)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def gradient(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    top = (245, 248, 255)
    bottom = (223, 237, 255)
    for y in range(height):
        ratio = y / max(height - 1, 1)
        color = tuple(round(top[i] * (1 - ratio) + bottom[i] * ratio) for i in range(3))
        for x in range(width):
            pixels[x, y] = color
    return image


def fit_inside(image: Image.Image, max_size: tuple[int, int]) -> Image.Image:
    copy = image.copy()
    copy.thumbnail(max_size, Image.Resampling.LANCZOS)
    return copy


def rounded(image: Image.Image, radius: int) -> Image.Image:
    result = Image.new("RGBA", image.size)
    mask = Image.new("L", image.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *image.size), radius=radius, fill=255)
    result.paste(image.convert("RGBA"), mask=mask)
    return result


def draw_centered(draw: ImageDraw.ImageDraw, text: str, y: int, width: int, size: int) -> int:
    selected = font(size, bold=True)
    box = draw.textbbox((0, 0), text, font=selected)
    draw.text(((width - (box[2] - box[0])) / 2, y), text, font=selected, fill=(15, 39, 87))
    return box[3] - box[1]


def render(source: Image.Image, title: str, size: tuple[int, int], output: Path) -> None:
    width, height = size
    canvas = gradient(size).convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    margin = round(width * 0.07)
    title_y = round(height * 0.055)
    draw_centered(draw, title, title_y, width, max(44, round(width * 0.055)))

    screen_top = round(height * 0.16)
    screen_bottom = round(height * 0.025)
    screen = fit_inside(source, (width - margin * 2, height - screen_top - screen_bottom))
    screen = rounded(screen, max(30, round(width * 0.045)))

    shadow = Image.new("RGBA", canvas.size)
    shadow_box = Image.new("RGBA", screen.size, (8, 38, 94, 100))
    shadow_box = rounded(shadow_box, max(30, round(width * 0.045))).filter(ImageFilter.GaussianBlur(round(width * 0.025)))
    x = (width - screen.width) // 2
    y = screen_top
    shadow.alpha_composite(shadow_box, (x, y + round(width * 0.02)))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(screen, (x, y))

    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output, quality=94, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default="store-assets/screenshots/manifest.json")
    parser.add_argument("--tablet", action="store_true", help="Generate iPad assets from real iPad captures")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    root = manifest_path.parent
    output_root = root / "generated"
    for index, item in enumerate(data["screenshots"], start=1):
        source = Image.open(root / item["file"]).convert("RGB")
        slug = item.get("slug", f"screen-{index}")
        render(source, item["title"], APPLE_PHONE, output_root / "app-store-iphone-6.9" / f"{index:02d}-{slug}.jpg")
        render(source, item["title"], GOOGLE_PHONE, output_root / "google-play-phone" / f"{index:02d}-{slug}.jpg")
        if args.tablet:
            render(source, item["title"], APPLE_TABLET, output_root / "app-store-ipad-13" / f"{index:02d}-{slug}.jpg")


if __name__ == "__main__":
    main()
