#!/usr/bin/env python3
"""
Walk Up app icon generator (v3 · "Editorial Sunrise").

Outputs a master 1024x1024 PNG plus 6 sizes required by iOS AppIcon.appiconset:

  - Marketing 1024 (Store front)
  - iPhone @3x (180)
  - iPhone @2x (120)
  - iPad Pro @2x (167)
  - iPad @2x (152)
  - iPad notification @2x (76)
  - iOS @3x 87 / @2x 60 / @2x 40 / @2x 29 (Settings / Notification / Spotlight)

Design — after two prior attempts that tried to render human footprint
silhouettes via PIL primitives (and ended up looking like cows' udders):
  - Vertical sunrise gradient (deep purple → coral → gold bottom-up, like
    a dawn sky).
  - A large warm-gold sun disc in the upper third, with a wide soft halo
    suggesting light spilling over the horizon.
  - Three dark-purple step dots, receding in size, curving from lower-left
    up toward the sun — implies "the path just walked". Reads as a clean
    editorial motif, not a literal foot.

Re-run this script any time you want to refresh the icon — output is
deterministic and version-controlled under Resources/Assets.xcassets/.

Tuning colors: edit the SUNRISE_END / SUNRISE_MID / SUNRISE_START /
FOOTPRINT / SUN_DISC constants at the top.
"""

from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path

# ---------------------------------------------------------------------------
# Color tokens — mirror Theme.swift but as tuples for alpha blending.
# ---------------------------------------------------------------------------
SUNRISE_END   = (246, 192, 101, 255)   # F6C065 gold
SUNRISE_MID   = (226, 106,  77, 255)   # E26A4D coral
SUNRISE_START = ( 61,  42, 110, 255)   # 3D2A6E deep purple
FOOTPRINT     = ( 35,  24,  68, 255)   # slightly darker than gradient bottom
SUN_DISC      = (253, 224, 153, 245)   # slightly off-white core

W = H = 1024
CORNER_RADIUS = 226   # iOS continuous squircle for 1024 master
ICON_DIR = Path(__file__).parent.parent / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"


# ---------------------------------------------------------------------------
# Background helpers
# ---------------------------------------------------------------------------
def vertical_gradient(w: int, h: int, c_top, c_mid, c_bot) -> Image.Image:
    """Three-stop vertical gradient. .top is c_top, .bottom is c_bot."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        if y < h * 0.5:
            t = y / (h * 0.5)
            r = int(c_top[0] * (1 - t) + c_mid[0] * t)
            g = int(c_top[1] * (1 - t) + c_mid[1] * t)
            b = int(c_top[2] * (1 - t) + c_mid[2] * t)
        else:
            t = (y - h * 0.5) / (h * 0.5)
            r = int(c_mid[0] * (1 - t) + c_bot[0] * t)
            g = int(c_mid[1] * (1 - t) + c_bot[1] * t)
            b = int(c_mid[2] * (1 - t) + c_bot[2] * t)
        for x in range(w):
            px[x, y] = (r, g, b, 255)
    return img


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([(0, 0), (size - 1, size - 1)],
                         radius=radius, fill=255)
    return mask


def blurred_circle_layer(size: int, cx, cy, radius, color, blur=20) -> Image.Image:
    """Soft circular halo as a separate RGBA layer for compositing."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=color)
    return layer.filter(ImageFilter.GaussianBlur(blur))


# ---------------------------------------------------------------------------
# Master composite — sun + ascending step dots
# ---------------------------------------------------------------------------
def make_master() -> Image.Image:
    bg = vertical_gradient(W, H, SUNRISE_END, SUNRISE_MID, SUNRISE_START)

    # Sun position — upper third, slightly off-center to the right so the
    # first step dot (bottom-left) and the sun balance the composition.
    sun_cx = int(W * 0.62)
    sun_cy = int(H * 0.30)
    sun_r  = int(H * 0.13)

    # 1. Big soft halo around sun — gives the "light spilling over" feel.
    halo = blurred_circle_layer(
        W, sun_cx, sun_cy,
        radius=int(sun_r * 2.4),
        color=(252, 222, 158, 165),
        blur=70,
    )
    bg.alpha_composite(halo)

    # 2. Mid halo — sharper, anchor for the eye.
    halo2 = blurred_circle_layer(
        W, sun_cx, sun_cy,
        radius=int(sun_r * 1.6),
        color=(253, 224, 153, 200),
        blur=30,
    )
    bg.alpha_composite(halo2)

    # 3. Sun disc itself.
    sun_disc = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sun_disc)
    sd.ellipse(
        [sun_cx - sun_r, sun_cy - sun_r,
         sun_cx + sun_r, sun_cy + sun_r],
        fill=SUN_DISC,
    )
    bg.alpha_composite(sun_disc)

    # 4. Three step dots, receding in size, curving lower-left to sun.
    # Each dot has its own halo for the same "light" feel.
    steps = [
        # (cx_frac, cy_frac, radius_frac, halo_alpha, halo_blur)
        (0.22, 0.74, 0.105, 105, 18),  # biggest, closest to viewer
        (0.40, 0.66, 0.075,  85, 14),
        (0.54, 0.55, 0.050,  70, 12),  # smallest, closest to sun
    ]
    for xf, yf, rf, ha, hb in steps:
        sx = int(W * xf)
        sy = int(H * yf)
        sr = int(W * rf)

        # Soft halo on each step
        halo_step = blurred_circle_layer(
            W, sx, sy,
            radius=int(sr * 1.6),
            color=(252, 222, 158, ha),
            blur=hb,
        )
        bg.alpha_composite(halo_step)

        # Dot itself
        dot_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        dd = ImageDraw.Draw(dot_layer)
        dd.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=FOOTPRINT)
        bg.alpha_composite(dot_layer)

    # 5. Rounded-corner mask (iOS continuous squircle).
    mask = rounded_mask(W, CORNER_RADIUS)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.paste(bg, mask=mask)
    return out


# ---------------------------------------------------------------------------
# Multi-size export + Contents.json
# ---------------------------------------------------------------------------
SIZES = [
    # (filename,                          pixel_size, idiom,            scale, role)
    ("AppIcon-marketing-1024.png",        1024,        "ios-marketing",  "1x",  "marketing"),
    ("AppIcon-iphone-180@3x.png",          180,        "iphone",         "3x",  "primary"),
    ("AppIcon-iphone-120@2x.png",          120,        "iphone",         "2x",  "primary"),
    ("AppIcon-ipad-167@2x.png",            167,        "ipad",           "2x",  "primary"),
    ("AppIcon-ipad-152@2x.png",            152,        "ipad",           "2x",  ""),
    ("AppIcon-ios-76@2x.png",               76,        "ios",            "2x",  ""),
    ("AppIcon-ios-87@3x.png",               87,        "ios",            "3x",  ""),
    ("AppIcon-ios-60@2x.png",               60,        "ios",            "2x",  ""),
    ("AppIcon-ios-40@2x.png",               40,        "ios",            "2x",  ""),
    ("AppIcon-ios-29@2x.png",               29,        "ios",            "2x",  ""),
]


def write_contents_json(images):
    image_entries = []
    for i, img in enumerate(images):
        if img["idiom"] == "ios-marketing":
            entry = (
                f'    {{\n'
                f'      "filename" : "{img["filename"]}",\n'
                f'      "idiom" : "{img["idiom"]}",\n'
                f'      "size" : "1024x1024"\n'
                f'    }}'
            )
        else:
            entry = (
                f'    {{\n'
                f'      "filename" : "{img["filename"]}",\n'
                f'      "idiom" : "{img["idiom"]}",\n'
                f'      "scale" : "{img["scale"]}",\n'
                f'      "size" : "{img["size_str"]}"'
            )
            if img["role"]:
                entry += f',\n      "role" : "{img["role"]}"'
            entry += "\n    }"
        image_entries.append(entry)
    return (
        '{ "images" : [\n'
        + ",\n".join(image_entries)
        + '\n  ],\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n'
    )


def main():
    out_dir = ICON_DIR
    out_dir.mkdir(parents=True, exist_ok=True)

    master = make_master()
    master_path = out_dir / "AppIcon-master-1024.png"
    master.save(master_path, "PNG")
    print(f"master  : {master_path}  ({master.size[0]}x{master.size[1]})")

    images_meta = []
    for fname, px_size, idiom, scale, role in SIZES:
        out_path = out_dir / fname
        if px_size == 1024:
            resized = master
        else:
            resized = master.resize((px_size, px_size), Image.LANCZOS)
        resized.save(out_path, "PNG")
        size_str = f"{px_size}x{px_size}"
        images_meta.append({
            "filename": fname,
            "size": px_size,
            "size_str": size_str,
            "idiom": idiom,
            "scale": scale,
            "role": role,
        })
        print(f"  -> {fname}  ({px_size}x{px_size})")

    contents = write_contents_json(images_meta)
    contents_path = out_dir / "Contents.json"
    contents_path.write_text(contents)
    print(f"\nContents.json -> {contents_path}")
    print(f"Total: {len(images_meta)} assets exported.")


if __name__ == "__main__":
    main()
