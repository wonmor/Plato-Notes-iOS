#!/usr/bin/env python3
"""Android icon set and Play graphics for Plato, from the wax-tablet render.

Inputs (in ~/Documents/sr-video/screens/plato/icon/):
  final-icon-1024.png            the shipped iOS icon (tablet on the honey ground)
  android-foreground-1024.png    the same scene re-rendered on a transparent film:
                                 blender -b -P android-foreground-scene.py -- a android-foreground-1024.png 1024
Outputs:
  app/src/main/res/mipmap-*/ic_launcher_{foreground,background,monochrome}.png  (108 dp layers)
  app/src/main/res/drawable-nodpi/brand_mark.png
  ~/Documents/sr-video/screens/plato/play/{play-icon-512.png, feature-graphic-1024x500.png}

The foreground is scaled so every opaque pixel sits inside the 66 dp safe circle of the 108 dp canvas.
Run: python3 tools/make_icons.py
"""
import glob, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "app", "src", "main", "res")
ICON = os.path.expanduser("~/Documents/sr-video/screens/plato/icon")
PLAY = os.path.expanduser("~/Documents/sr-video/screens/plato/play")
DENS = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
FONT = (glob.glob(os.path.expanduser("~/.gradle/caches/*/transforms/*/transformed/layoutlib-runtime-*/data/fonts/Roboto-Regular.ttf"))
        or [None])[0]


def clean_foreground():
    """The tablet alone: drop dust motes (small specks) by keeping the largest opaque component."""
    im = Image.open(os.path.join(ICON, "android-foreground-1024.png")).convert("RGBA")
    a = np.array(im)
    lab, n = ndimage.label(a[..., 3] > 8)
    sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    keep = 1 + int(np.argmax(sizes))
    body = ndimage.binary_dilation(lab == keep, iterations=3)
    a[..., 3] = np.where(body, a[..., 3], 0)
    return Image.fromarray(a)


def ground(w, h):
    """The honey-lit ground of the iOS icon: pale gold top left to deep honey bottom right, with a soft glow."""
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    t = np.clip((x / w * 0.45 + y / h * 0.55), 0, 1)[..., None]
    c0, c1 = np.array([0xE6, 0xC4, 0x84]), np.array([0x9E, 0x74, 0x3D])
    img = c0 * (1 - t) + c1 * t
    d = np.sqrt((x - w * 0.18) ** 2 + (y - h * 0.22) ** 2) / max(w, h)
    glow = np.clip(1 - d / 0.55, 0, 1)[..., None] ** 2
    img = img * (1 - 0.45 * glow) + np.array([0xF6, 0xE4, 0xB4]) * 0.45 * glow
    return Image.fromarray(img.clip(0, 255).astype(np.uint8), "RGB").convert("RGBA")


def with_shadow(fg, offset=(0.02, 0.035), blur=0.025, alpha=0.38):
    """A soft contact shadow under the tablet, so it sits on the ground in every launcher mask."""
    w, h = fg.size
    a = np.array(fg)[..., 3].astype(np.float32) * alpha
    sh = Image.fromarray(a.astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(blur * w))
    layer = Image.new("RGBA", fg.size, (60, 34, 12, 0))
    layer.putalpha(sh)
    out = Image.new("RGBA", fg.size, (0, 0, 0, 0))
    out.alpha_composite(layer, (int(offset[0] * w), int(offset[1] * h)))
    out.alpha_composite(fg)
    return out


def fit_safe(fg, canvas):
    """Scale and centre so the farthest opaque pixel lies within 33/108 of the canvas from its centre."""
    a = np.array(fg)[..., 3] > 4
    ys, xs = np.nonzero(a)
    cx, cy = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2
    r = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2).max()
    target = canvas * 32.5 / 108          # a hair inside the 33 dp safe radius
    s = target / r
    small = fg.resize((max(1, round(fg.width * s)), max(1, round(fg.height * s))), Image.LANCZOS)
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.alpha_composite(small, (round(canvas / 2 - cx * s), round(canvas / 2 - cy * s)))
    return out


def monochrome(_fg):
    """Themed-icon layer: a flat glyph of the same tablet, drawn from the camera-projected geometry
    (android-tablet-projection.json, from android-projection-scene.py): the frame, a few lines of writing
    that get shorter as they fade, and the stylus resting across the corner."""
    import json
    P = json.load(open(os.path.join(ICON, "android-tablet-projection.json")))
    S = 1024
    img = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(img)
    pt = lambda q: (q[0] * S, q[1] * S)
    d.polygon([pt(q) for q in P["outer"]], fill=255)
    d.polygon([pt(q) for q in P["inner"]], fill=0)
    tl, tr, br, bl = [np.array(pt(q)) for q in P["inner"]]
    uv = lambda u, v: tuple((tl * (1 - u) + tr * u) * (1 - v) + (bl * (1 - u) + br * u) * v)
    for i, end in enumerate([0.86, 0.78, 0.66, 0.5, 0.32]):
        v = 0.17 + i * 0.13
        d.line([uv(0.12, v), uv(end, v)], fill=255, width=22)
        for u in (0.12, end):
            x, y = uv(u, v)
            d.ellipse((x - 11, y - 11, x + 11, y + 11), fill=255)
    a, b = np.array(pt(P["stylus"][0])), np.array(pt(P["stylus"][1]))
    n = (b - a) / np.linalg.norm(b - a)
    perp = np.array([-n[1], n[0]])
    # knock a gap around the stylus so it reads over the frame, then draw it with a sharp point
    d.polygon([tuple(a - perp * 26 - n * 20), tuple(b - perp * 26 + n * 20), tuple(b + perp * 26 + n * 20), tuple(a + perp * 26 - n * 20)], fill=0)
    tip = a + n * 70
    d.polygon([tuple(a), tuple(tip + perp * 12), tuple(b + perp * 12), tuple(b - perp * 12), tuple(tip - perp * 12)], fill=255)
    m = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    m.putalpha(img.filter(ImageFilter.GaussianBlur(0.8)))
    return m


def main():
    fg = with_shadow(clean_foreground())
    mono_src = monochrome(None)
    for d, k in DENS.items():
        px = round(108 * k)
        folder = os.path.join(RES, f"mipmap-{d}")
        os.makedirs(folder, exist_ok=True)
        fit_safe(fg, px * 4).resize((px, px), Image.LANCZOS).save(os.path.join(folder, "ic_launcher_foreground.png"))
        ground(px, px).convert("RGB").save(os.path.join(folder, "ic_launcher_background.png"))
        fit_safe(mono_src, px * 4).resize((px, px), Image.LANCZOS).save(os.path.join(folder, "ic_launcher_monochrome.png"))

    ios = Image.open(os.path.join(ICON, "final-icon-1024.png")).convert("RGB")
    os.makedirs(os.path.join(RES, "drawable-nodpi"), exist_ok=True)
    ios.resize((288, 288), Image.LANCZOS).save(os.path.join(RES, "drawable-nodpi", "brand_mark.png"))

    # Play icon: 512 px full-bleed square (Play applies its own mask), the same art as the App Store icon.
    os.makedirs(PLAY, exist_ok=True)
    ios.resize((512, 512), Image.LANCZOS).save(os.path.join(PLAY, "play-icon-512.png"))

    # Feature graphic 1024 x 500: the ground, the tablet on the right, the name and line on the left.
    W, H = 1024, 500
    fgx = ground(W, H)
    tab = clean_foreground()
    bb = tab.getbbox()
    tab = tab.crop(bb)
    s = 430 / tab.height
    tab = tab.resize((round(tab.width * s), round(tab.height * s)), Image.LANCZOS)
    pad = Image.new("RGBA", (tab.width + 80, tab.height + 80), (0, 0, 0, 0))
    pad.alpha_composite(tab, (20, 20))          # room for the shadow, so it is never clipped
    tab = with_shadow(pad, offset=(0.02, 0.03), blur=0.02)
    fgx.alpha_composite(tab, (W - tab.width - 10, (H - tab.height) // 2 + 16))
    dr = ImageDraw.Draw(fgx)
    ink, sub = (38, 22, 10), (82, 48, 22)
    big = ImageFont.truetype(FONT, 104)
    small = ImageFont.truetype(FONT, 38)
    try:
        big.set_variation_by_axes([700])
        small.set_variation_by_axes([500])
    except Exception:
        pass
    dr.text((72, 148), "Plato", font=big, fill=ink)
    dr.text((76, 276), "Notes that vanish.", font=small, fill=sub)
    fgx.convert("RGB").save(os.path.join(PLAY, "feature-graphic-1024x500.png"))
    print("icons and Play graphics written")


if __name__ == "__main__":
    main()
