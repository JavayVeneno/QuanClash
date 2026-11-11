#!/usr/bin/env python3
"""Draw the QuanClash tray icons from the app icon's cloud mark.

The cloud silhouette is taken straight from
``scripts/icon/source/icon-source.svg`` so the tray stays in sync with the app
icon. Three states, matching ``Tray.getTryIcon``:

* ``status_1`` - stopped (dimmed brand disc)
* ``status_2`` - running, TUN off (brand purple disc)
* ``status_3`` - running, TUN on (brand purple disc + gold dot)

Every state keeps the gold rim arc at the top right so the mark still reads as
the app icon at tray size.

Usage:
    python scripts/icon/export_tray_icons.py
"""

from __future__ import annotations

import re
from pathlib import Path

from PIL import Image, ImageDraw

from gold_arc import draw_gold_arc

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "scripts/icon/source/icon-source.svg"
OUT_DIR = ROOT / "assets/images/icon"

CANVAS = 96
SS = 4
S = CANVAS * SS

DISC_MARGIN = 4.0
CLOUD_WIDTH = 54.0
DOT = (78.0, 18.0, 9.0)
ARC_WIDTH = 7.0
ARC_INSET = 1.2
OFF_ALPHA = 0.72

DISC_COLOR = (101, 22, 228, 255)   # #6516E4, matches the app icon disc
CLOUD_COLOR = (255, 255, 255, 255)
GOLD_COLOR = (255, 196, 74, 255)   # #FFC24A

CURVE_STEPS = 24


def _cloud_points() -> list[tuple[float, float]]:
    """Flatten the white cloud path (M/C/Z) into a polygon."""
    text = SOURCE.read_text(encoding="utf-8")
    path = re.search(r'<path fill="white" d="([^"]+)"', text)
    if path is None:
        raise ValueError(f"cloud path not found in {SOURCE}")
    tokens = re.findall(r"[MCZ]|-?\d+(?:\.\d+)?", path.group(1))

    points: list[tuple[float, float]] = []
    current = (0.0, 0.0)
    index = 0
    while index < len(tokens):
        command = tokens[index]
        index += 1
        if command == "M":
            current = (float(tokens[index]), float(tokens[index + 1]))
            index += 2
            points.append(current)
        elif command == "C":
            x1, y1, x2, y2, x, y = (float(value) for value in tokens[index:index + 6])
            index += 6
            x0, y0 = current
            for step in range(1, CURVE_STEPS + 1):
                t = step / CURVE_STEPS
                mt = 1.0 - t
                points.append(
                    (
                        mt**3 * x0 + 3 * mt**2 * t * x1 + 3 * mt * t**2 * x2 + t**3 * x,
                        mt**3 * y0 + 3 * mt**2 * t * y1 + 3 * mt * t**2 * y2 + t**3 * y,
                    )
                )
            current = (x, y)
        elif command == "Z":
            continue
        else:
            raise ValueError(f"unsupported path command: {command}")
    return points


def _icon(dot: bool = False, dim: bool = False) -> Image.Image:
    points = _cloud_points()
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    center_x, center_y = (min_x + max_x) / 2, (min_y + max_y) / 2
    scale = CLOUD_WIDTH / (max_x - min_x)

    polygon = [
        (
            ((x - center_x) * scale + CANVAS / 2) * SS,
            ((y - center_y) * scale + CANVAS / 2) * SS,
        )
        for x, y in points
    ]

    image = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    disc = (
        DISC_MARGIN * SS,
        DISC_MARGIN * SS,
        S - DISC_MARGIN * SS,
        S - DISC_MARGIN * SS,
    )
    draw.ellipse(disc, fill=DISC_COLOR)
    draw.polygon(polygon, fill=CLOUD_COLOR)

    image = draw_gold_arc(
        image,
        center=(S / 2, S / 2),
        radius=(CANVAS / 2 - DISC_MARGIN) * SS,
        width=ARC_WIDTH * SS,
        inset=ARC_INSET * SS,
        supersample=1,
    )
    draw = ImageDraw.Draw(image)

    if dot:
        dx, dy, radius = DOT
        draw.ellipse(
            (
                (dx - radius) * SS,
                (dy - radius) * SS,
                (dx + radius) * SS,
                (dy + radius) * SS,
            ),
            fill=GOLD_COLOR,
        )

    if dim:
        image.putalpha(
            image.getchannel("A").point(lambda value: round(value * OFF_ALPHA))
        )

    return image.resize((CANVAS, CANVAS), Image.Resampling.LANCZOS)


def main() -> None:
    states = {
        "status_1": _icon(dim=True),
        "status_2": _icon(),
        "status_3": _icon(dot=True),
    }
    ico_sizes = [(16, 16), (20, 20), (24, 24), (32, 32), (48, 48), (64, 64), (96, 96)]

    for name, image in states.items():
        png = OUT_DIR / f"{name}.png"
        image.save(png, optimize=True)
        print(f"{png.relative_to(ROOT)}  {CANVAS}x{CANVAS}")

        ico = OUT_DIR / f"{name}.ico"
        image.save(ico, format="ICO", sizes=ico_sizes)
        print(f"{ico.relative_to(ROOT)}  {len(ico_sizes)} sizes")


if __name__ == "__main__":
    main()
