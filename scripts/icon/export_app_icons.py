#!/usr/bin/env python3
"""Export the QuanClash app icon to every platform asset.

The source artwork lives in ``scripts/icon/source/icon-source.svg``: a white
cloud mark on a purple disc. ``render_svg_icon_test.dart`` rasterises it to
``icon-source.png`` with a real alpha channel. The legacy
``icon-source.webp`` (a glossy Q on a black backdrop) is still accepted as a
fallback. This script turns that one image into:

* the in-app icon and the Windows ``.ico`` files (rounded, transparent corners)
* the macOS appiconset (squircle body at Apple's 824/1024 grid)
* the Android legacy mipmaps, Play Store icon and adaptive-icon layers
* a full-bleed square variant with the corners filled in

Usage:
    python scripts/icon/export_app_icons.py
    python scripts/icon/export_app_icons.py --preview build/icon-preview.png
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from gold_arc import draw_gold_arc

ROOT = Path(__file__).resolve().parents[2]
SOURCE_PNG = ROOT / "scripts/icon/source/icon-source.png"
SOURCE_WEBP = ROOT / "scripts/icon/source/icon-source.webp"

ART = 1024
# The source canvas has a wide margin around the disc; scale the artwork up so
# it fills the icon like a regular app icon instead of a small dot.
COVERAGE = 0.92
# The legacy webp render sits on pure black, so it is effectively premultiplied:
# recover the shape's coverage from the brightest channel and divide the black
# back out.
ALPHA_FLOOR = 10.0
ALPHA_RANGE = 30.0
CORNER_SIGMA = 60.0


def _load_source() -> tuple[np.ndarray, np.ndarray]:
    if SOURCE_PNG.exists():
        rgba = np.asarray(Image.open(SOURCE_PNG).convert("RGBA"), dtype=np.float32)
        alpha = rgba[..., 3] / 255.0
        alpha[alpha < 0.02] = 0.0
        rgb = np.where(alpha[..., None] > 0.0, rgba[..., :3], 0.0)
        return np.clip(rgb, 0.0, 255.0), alpha

    rgb = np.asarray(Image.open(SOURCE_WEBP).convert("RGB"), dtype=np.float32)
    maxc = rgb.max(axis=2)
    alpha = np.clip((maxc - ALPHA_FLOOR) / ALPHA_RANGE, 0.0, 1.0)
    alpha[alpha < 0.02] = 0.0
    straight = np.where(alpha[..., None] > 0.0, rgb / np.maximum(alpha[..., None], 0.02), 0.0)
    return np.clip(straight, 0.0, 255.0), alpha


def _rgba(rgb: np.ndarray, alpha: np.ndarray) -> Image.Image:
    return Image.fromarray(
        np.dstack((rgb, np.clip(alpha * 255.0, 0, 255))).astype(np.uint8), "RGBA"
    )


def _with_gold_arc(image: Image.Image) -> Image.Image:
    """Add the brand's gold rim highlight along the top-right of the disc."""
    box = image.getchannel("A").getbbox()
    if box is None:
        return image
    center = ((box[0] + box[2]) / 2, (box[1] + box[3]) / 2)
    radius = (box[2] - box[0]) / 2
    return draw_gold_arc(
        image,
        center=center,
        radius=radius,
        width=radius * 0.075,
        inset=radius * 0.012,
    )


def _fit_canvas(image: Image.Image, coverage: float = COVERAGE) -> Image.Image:
    """Crop the artwork to its bounds and centre it at ``coverage`` of the canvas."""
    box = image.getchannel("A").getbbox()
    if box is None:
        return image
    art = image.crop(box)
    scale = (ART * coverage) / max(art.size)
    size = (round(art.width * scale), round(art.height * scale))
    art = art.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (ART, ART), (0, 0, 0, 0))
    canvas.paste(art, ((ART - size[0]) // 2, (ART - size[1]) // 2), art)
    return canvas


def _blur_rgb(rgb: np.ndarray, sigma: float) -> np.ndarray:
    channels = []
    for index in range(3):
        layer = Image.fromarray(np.clip(rgb[..., index], 0, 255).astype(np.uint8), "L")
        channels.append(np.asarray(layer.filter(ImageFilter.GaussianBlur(sigma)), dtype=np.float32))
    return np.stack(channels, axis=-1)


def _square(rgb: np.ndarray, alpha: np.ndarray) -> Image.Image:
    """Fill the transparent corners with the surrounding artwork."""
    premul = rgb * alpha[..., None]
    backdrop_rgb = _blur_rgb(premul, CORNER_SIGMA)
    backdrop_alpha = np.asarray(
        Image.fromarray((alpha * 255).astype(np.uint8), "L").filter(
            ImageFilter.GaussianBlur(CORNER_SIGMA)
        ),
        dtype=np.float32,
    ) / 255.0
    backdrop = backdrop_rgb / np.maximum(backdrop_alpha[..., None], 1e-3)
    backdrop = np.clip(backdrop, 0, 255)
    out = rgb * alpha[..., None] + backdrop * (1.0 - alpha[..., None])
    return _rgba(out, np.ones_like(alpha))


def _monochrome(rgb: np.ndarray) -> Image.Image:
    """Tinted-icon silhouette: the lit parts of the mark, transparent elsewhere."""
    luma = 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
    alpha = np.clip((luma - 140.0) / 80.0, 0.0, 1.0)
    white = np.full_like(rgb, 255.0)
    return _rgba(white, alpha)


def _adaptive_layer(art: Image.Image, layer: int = 432) -> Image.Image:
    """Place artwork in the visible 72/108 viewport of an adaptive-icon layer."""
    visible = round(layer * 72 / 108)
    out = Image.new("RGBA", (layer, layer), (0, 0, 0, 0))
    scaled = art.resize((visible, visible), Image.Resampling.LANCZOS)
    out.paste(scaled, ((layer - visible) // 2, (layer - visible) // 2), scaled)
    return out


def _circle(image: Image.Image) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, image.size[0] - 1, image.size[1] - 1), fill=255)
    out = image.copy()
    out.putalpha(Image.composite(image.getchannel("A"), Image.new("L", image.size, 0), mask))
    return out


def _save(image: Image.Image, path: Path, size: int, **kwargs) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path, **kwargs)
    print(f"{path.relative_to(ROOT)}  {size}x{size}")


def export(
    rounded: Image.Image, square: Image.Image, circle: Image.Image, monochrome: Image.Image
) -> None:
    # In-app icon (About dialog, window icon, Linux packaging)
    _save(rounded, ROOT / "assets/images/icon.png", 550, optimize=True)

    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    for relative in ("assets/images/icon.ico", "windows/runner/resources/app_icon.ico"):
        path = ROOT / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        rounded.resize((256, 256), Image.Resampling.LANCZOS).save(
            path, format="ICO", sizes=ico_sizes
        )
        print(f"{relative}  {len(ico_sizes)} sizes")

    # macOS draws no mask, so the squircle body sits at Apple's 824/1024 grid.
    body = rounded.resize((824, 824), Image.Resampling.LANCZOS)
    mac = Image.new("RGBA", (ART, ART), (0, 0, 0, 0))
    mac.paste(body, (100, 100), body)
    mac_dir = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for size in (16, 32, 64, 128, 256, 512, 1024):
        _save(mac, mac_dir / f"app_icon_{size}.png", size, optimize=True)

    # Android legacy launcher icons
    mipmaps = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in mipmaps.items():
        folder = ROOT / f"android/app/src/main/res/mipmap-{density}"
        _save(rounded, folder / "ic_launcher.webp", size, lossless=True, method=6)
        _save(circle, folder / "ic_launcher_round.webp", size, lossless=True, method=6)

    # Google Play listing: opaque 512 square, Play applies its own rounding.
    _save(square, ROOT / "android/app/src/main/ic_launcher-playstore.png", 512, optimize=True)

    # Adaptive icon foreground: only the central 72/108 of the 108dp layer is
    # visible, so the square artwork is scaled into that viewport and centred.
    foreground_path = ROOT / "android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png"
    _adaptive_layer(square).save(foreground_path, optimize=True)
    print(f"{foreground_path.relative_to(ROOT)}  432x432")

    monochrome_path = (
        ROOT / "android/app/src/main/res/drawable-xxxhdpi/ic_launcher_monochrome.png"
    )
    _adaptive_layer(monochrome).save(monochrome_path, optimize=True)
    print(f"{monochrome_path.relative_to(ROOT)}  432x432")


def preview(rounded: Image.Image, path: Path) -> None:
    sizes = (128, 64, 48, 32, 24, 16)
    row_height = 190
    sheet = Image.new("RGB", (1000, row_height * 2 + 20), (20, 20, 24))
    draw = ImageDraw.Draw(sheet)
    for index, background in enumerate(((28, 28, 30), (242, 242, 246))):
        top = 10 + index * row_height
        draw.rectangle((20, top, 980, top + row_height - 20), fill=background)
        x = 50
        for size in sizes:
            icon = rounded.resize((size, size), Image.Resampling.LANCZOS)
            sheet.paste(icon, (x, top + (row_height - 20 - size) // 2), icon)
            x += size + 40
        icon = rounded.resize((34, 34), Image.Resampling.LANCZOS)
        sheet.paste(icon, (850, top + (row_height - 20 - 34) // 2), icon)
    path = path.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    print(path.relative_to(ROOT))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", type=Path, help="write a size-ladder preview sheet here")
    args = parser.parse_args()

    rgb, alpha = _load_source()
    rounded = _fit_canvas(_with_gold_arc(_rgba(rgb, alpha)))
    fitted = np.asarray(rounded, dtype=np.float32)
    fitted_rgb = fitted[..., :3]
    fitted_alpha = fitted[..., 3] / 255.0

    if args.preview:
        preview(rounded, args.preview)
        return

    square = _square(fitted_rgb, fitted_alpha)
    circle = _circle(rounded)
    monochrome = _monochrome(fitted_rgb)
    export(rounded, square, circle, monochrome)


if __name__ == "__main__":
    main()
