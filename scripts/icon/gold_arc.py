"""Draw the soft gold arc used by the app and tray icons.

The arc hugs the top-right of the disc: it tapers to nothing at both ends, runs
through a warm gradient and carries a soft glow, so it reads as a highlight on
the rim rather than a flat stroke.
"""

from __future__ import annotations

import math

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

Color = tuple[int, int, int]

# Light gold -> warm gold -> deep amber.
DEFAULT_COLORS: tuple[Color, Color, Color] = (
    (255, 232, 176),
    (255, 188, 82),
    (232, 146, 36),
)


def _gradient(size: tuple[int, int], colors: tuple[Color, Color, Color]) -> Image.Image:
    width, height = size
    yy, xx = np.mgrid[0:height, 0:width].astype(np.float32)
    t = np.clip(0.55 * (xx / max(width - 1, 1)) + 0.45 * (yy / max(height - 1, 1)), 0.0, 1.0)
    stops = np.asarray(colors, dtype=np.float32)
    scaled = t * (len(stops) - 1)
    low = np.floor(scaled).astype(np.int32)
    high = np.minimum(low + 1, len(stops) - 1)
    frac = (scaled - low)[..., None]
    rgb = stops[low] * (1.0 - frac) + stops[high] * frac
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")


def draw_gold_arc(
    image: Image.Image,
    *,
    center: tuple[float, float],
    radius: float,
    start_deg: float = -78.0,
    end_deg: float = -14.0,
    width: float = 28.0,
    inset: float = 5.0,
    glow: float = 0.55,
    colors: tuple[Color, Color, Color] = DEFAULT_COLORS,
    supersample: int = 2,
) -> Image.Image:
    """Composite a tapered, glowing gold arc onto ``image`` (RGBA)."""
    size = image.size
    mask = Image.new("L", (size[0] * supersample, size[1] * supersample), 0)
    draw = ImageDraw.Draw(mask)

    cx, cy = center[0] * supersample, center[1] * supersample
    arc_radius = (radius - inset) * supersample
    steps = 240
    for step in range(steps + 1):
        u = step / steps
        angle = math.radians(start_deg + (end_deg - start_deg) * u)
        thickness = width * supersample * math.sin(math.pi * u) ** 0.7
        if thickness < 0.8:
            continue
        x = cx + math.cos(angle) * arc_radius
        y = cy + math.sin(angle) * arc_radius
        half = thickness / 2
        draw.ellipse((x - half, y - half, x + half, y + half), fill=255)

    mask = mask.resize(size, Image.Resampling.LANCZOS)
    coverage = image.getchannel("A")
    gradient = _gradient(size, colors)

    out = image.copy()

    if glow > 0:
        halo = mask.filter(ImageFilter.GaussianBlur(width * 0.8)).point(
            lambda value: round(value * glow)
        )
        halo = ImageChops.multiply(halo, coverage)
        out.alpha_composite(Image.merge("RGBA", (*gradient.split(), halo)))

    core = ImageChops.multiply(mask, coverage)
    out.alpha_composite(Image.merge("RGBA", (*gradient.split(), core)))
    return out
