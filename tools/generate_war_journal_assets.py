#!/usr/bin/env python3
"""
War-Journal Asset Generator for Operation Storm.
Generates hand-inked, cross-hatched, watercolor-washed sprite library using Pillow.
Output includes characters, vehicles, terrain maps, props, combat VFX, and UI frames.
"""

import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

# Set deterministic random seed for reproducible hand-drawn strokes
random.seed(19950805)

# ---------------------------------------------------------------------------
# Core Palette & Styling Constants
# ---------------------------------------------------------------------------
INK_DARK = (28, 24, 20, 255)
INK_MID = (45, 38, 32, 230)
INK_LIGHT = (45, 38, 32, 120)
INK_FAINT = (45, 38, 32, 50)

COLOR_SKIN = (212, 176, 142, 255)
COLOR_SKIN_SHADOW = (175, 138, 106, 255)

COLOR_OLIVE_DRAB = (76, 92, 58, 255)
COLOR_OLIVE_DARK = (52, 65, 41, 255)
COLOR_OLIVE_LIGHT = (102, 120, 80, 255)

COLOR_KHAKI = (145, 133, 98, 255)
COLOR_CAMO_BROWN = (90, 68, 48, 255)
COLOR_LEATHER = (82, 56, 36, 255)
COLOR_LEATHER_DARK = (55, 37, 24, 255)

COLOR_STEEL = (60, 64, 68, 255)
COLOR_STEEL_DARK = (36, 38, 42, 255)
COLOR_STEEL_LIGHT = (100, 108, 114, 255)

COLOR_WOOD = (118, 76, 42, 255)
COLOR_WOOD_DARK = (78, 48, 26, 255)

COLOR_BLOOD = (128, 16, 16, 220)
COLOR_BLOOD_DARK = (80, 8, 8, 240)
COLOR_BLOOD_FRESH = (160, 22, 22, 200)

COLOR_FIRE_WHITE = (255, 255, 230, 255)
COLOR_FIRE_YELLOW = (255, 210, 50, 240)
COLOR_FIRE_ORANGE = (240, 110, 25, 220)

COLOR_CRO_RED = (196, 34, 28, 255)
COLOR_CRO_WHITE = (240, 240, 235, 255)
COLOR_CRO_BLUE = (28, 64, 142, 255)

COLOR_SVK_RED = (198, 40, 40, 255)
COLOR_SVK_BLUE = (28, 56, 140, 255)
COLOR_SVK_WHITE = (236, 236, 232, 255)
COLOR_SVK_OLIVE = (58, 62, 48, 255)
COLOR_SVK_OLIVE_DARK = (42, 46, 36, 255)
COLOR_BEARD = (52, 40, 28, 255)


def save_image(img: Image.Image, output_path: str, target_size: tuple = None) -> None:
    """Resamples down with Lanczos if target_size provided, and saves as RGBA PNG."""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    if target_size and img.size != target_size:
        img = img.resize(target_size, Image.Resampling.LANCZOS)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    img.save(output_path, format="PNG")
    print(f"Generated: {output_path} ({img.size[0]}x{img.size[1]})")


def draw_crosshatch(img: Image.Image, x0: int, y0: int, x1: int, y1: int,
                    spacing: int = 6, angle: float = 45.0, color: tuple = INK_LIGHT, width: int = 1,
                    mask_to_base: bool = True) -> Image.Image:
    """Draws fine hand-drawn crosshatch lines on an overlay and alpha composites onto img.
    When mask_to_base is True, cross-hatching is constrained strictly to non-zero alpha pixels
    of the underlying shape, preventing low-alpha holes and silhouette spillover."""
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    rad = math.radians(angle)
    dx = math.cos(rad)
    dy = math.sin(rad)
    length = math.hypot(x1 - x0, y1 - y0) * 1.5
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    
    steps = int(length / spacing)
    for i in range(-steps, steps + 1):
        offset = i * spacing
        sx = cx + offset * (-dy) - length * dx * 0.5
        sy = cy + offset * dx - length * dy * 0.5
        ex = cx + offset * (-dy) + length * dx * 0.5
        ey = cy + offset * dx + length * dy * 0.5
        draw_ov.line([(sx, sy), (ex, ey)], fill=color, width=width)
        
    if mask_to_base:
        base_a = img.getchannel("A")
        over_a = overlay.getchannel("A")
        masked_a = ImageChops.multiply(over_a, base_a)
        overlay.putalpha(masked_a)
        
    return Image.alpha_composite(img, overlay)


# ---------------------------------------------------------------------------
# 1. Characters Generator
# ---------------------------------------------------------------------------

def generate_torso(soldier_type: str, output_path: str) -> None:
    """Generates a 48x48 character torso facing right (+X). Drawn at 4x (192x192)."""
    S = 4  # Scale factor
    W, H = 48 * S, 48 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = 20 * S, 24 * S

    # Torso Base Colors
    torso_color = COLOR_OLIVE_DRAB
    helmet_color = COLOR_OLIVE_DARK
    vest_color = COLOR_OLIVE_DARK

    if soldier_type == "player":
        torso_color = (68, 86, 52, 255)
        helmet_color = (82, 102, 64, 255)
        vest_color = (55, 45, 35, 255)
    elif soldier_type == "rifleman":
        torso_color = COLOR_SVK_OLIVE
        helmet_color = COLOR_SVK_OLIVE_DARK
        vest_color = (48, 42, 34, 255)
    elif soldier_type == "shotgunner":
        torso_color = (62, 66, 52, 255)
        helmet_color = (46, 50, 38, 255)
        vest_color = (50, 35, 25, 255)
    elif soldier_type == "mg":
        torso_color = (54, 58, 46, 255)
        helmet_color = (40, 44, 34, 255)
        vest_color = (44, 38, 30, 255)
    elif soldier_type == "sniper":
        torso_color = (60, 68, 50, 255)
        helmet_color = (48, 56, 40, 255)
        vest_color = (50, 35, 25, 255)
    elif soldier_type == "officer":
        torso_color = COLOR_SVK_OLIVE_DARK
        helmet_color = (38, 42, 34, 255)
        vest_color = (50, 35, 25, 255)
    elif soldier_type == "grenadier":
        torso_color = (58, 62, 50, 255)
        helmet_color = (44, 48, 38, 255)
        vest_color = (40, 44, 34, 255)

    # 1. Torso body oval (shoulders and chest)
    # Shoulders span Y from (cy - 14*S) to (cy + 14*S)
    body_bbox = [cx - 10 * S, cy - 13 * S, cx + 10 * S, cy + 13 * S]
    draw.ellipse(body_bbox, fill=torso_color, outline=INK_DARK, width=2 * S)

    # Crosshatch rear shadow with alpha-composite
    img = draw_crosshatch(img, cx - 10 * S, cy - 12 * S, cx - 2 * S, cy + 12 * S,
                          spacing=3 * S, angle=60, color=INK_LIGHT, width=int(1.5 * S))
    draw = ImageDraw.Draw(img)

    # 2. Tactical Vest / Harness straps
    draw.rectangle([cx - 4 * S, cy - 10 * S, cx + 6 * S, cy + 10 * S],
                   fill=vest_color, outline=INK_DARK, width=int(1.5 * S))
    # Chest straps
    draw.line([(cx - 4 * S, cy - 6 * S), (cx + 6 * S, cy - 6 * S)], fill=INK_MID, width=int(1.5 * S))
    draw.line([(cx - 4 * S, cy + 6 * S), (cx + 6 * S, cy + 6 * S)], fill=INK_MID, width=int(1.5 * S))

    # 3. Soldier Type Specific Gear
    if soldier_type == "player":
        # Croatian 5x5 šahovnica shoulder patch + small HV brigade patch
        pw, ph = int(1.2 * S), int(1.2 * S)
        px0, py0 = cx - 5 * S, cy - 13 * S
        colors = [COLOR_CRO_RED, COLOR_CRO_WHITE]
        for row in range(5):
            for col in range(5):
                c = colors[(row + col) % 2]
                draw.rectangle([px0 + col * pw, py0 + row * ph,
                                px0 + (col + 1) * pw, py0 + (row + 1) * ph], fill=c)
        draw.rectangle([px0, py0, px0 + 5 * pw, py0 + 5 * ph], outline=INK_DARK, width=S)
        # 9th Guards "Vukovi" wolf-motif badge (simplified)
        draw.ellipse([cx + 2 * S, cy - 12 * S, cx + 7 * S, cy - 7 * S],
                     fill=(30, 30, 28, 255), outline=COLOR_CRO_RED, width=S)

    elif soldier_type != "player":
        # SVK Serbian tricolor armband on upper arm (bold enough to read at zoom)
        band_y0 = cy - 6 * S
        band_x0, band_x1 = cx - 12 * S, cx - 5 * S
        draw.rectangle([band_x0, band_y0, band_x1, band_y0 + 2 * S], fill=COLOR_SVK_RED, outline=INK_DARK, width=1)
        draw.rectangle([band_x0, band_y0 + 2 * S, band_x1, band_y0 + 4 * S], fill=COLOR_SVK_BLUE, outline=INK_DARK, width=1)
        draw.rectangle([band_x0, band_y0 + 4 * S, band_x1, band_y0 + 6 * S], fill=COLOR_SVK_WHITE, outline=INK_DARK, width=1)

    if soldier_type == "shotgunner":
        # Red shotgun shell bandolier across chest
        for bi in range(4):
            by = cy - 7 * S + bi * 4 * S
            draw.rectangle([cx - 2 * S, by, cx + 4 * S, by + 2 * S], fill=(180, 30, 25, 255), outline=INK_DARK, width=S)
            draw.ellipse([cx + 3 * S, by, cx + 5 * S, by + 2 * S], fill=(220, 180, 50, 255))

    elif soldier_type == "mg":
        # Brass ammunition belt draped across chest
        for bi in range(5):
            by = cy - 8 * S + bi * 4 * S
            draw.rectangle([cx - 3 * S, by, cx + 5 * S, by + 2 * S], fill=(210, 175, 45, 255), outline=INK_DARK, width=S)

    elif soldier_type == "officer":
        # Officer diagonal leather cross-belt & gold rank epaulets
        draw.line([(cx - 6 * S, cy - 10 * S), (cx + 4 * S, cy + 10 * S)], fill=COLOR_LEATHER_DARK, width=2 * S)
        draw.rectangle([cx - 2 * S, cy - 13 * S, cx + 2 * S, cy - 10 * S], fill=(220, 190, 50, 255), outline=INK_DARK, width=S)
        draw.rectangle([cx - 2 * S, cy + 10 * S, cx + 2 * S, cy + 13 * S], fill=(220, 190, 50, 255), outline=INK_DARK, width=S)

    elif soldier_type == "grenadier":
        # Heavy grenade pouches on chest
        for gi in range(3):
            gy = cy - 6 * S + gi * 5 * S
            draw.rounded_rectangle([cx - 2 * S, gy, cx + 4 * S, gy + 3 * S], radius=S, fill=(50, 55, 42, 255), outline=INK_DARK, width=S)

    # 4. Head & Helmet (Centered top-down circle)
    head_r = 7.5 * S
    head_bbox = [cx - head_r, cy - head_r, cx + head_r, cy + head_r]
    draw.ellipse(head_bbox, fill=helmet_color, outline=INK_DARK, width=2 * S)

    if soldier_type == "officer":
        # Officer service cap visor (black curved bill facing +X)
        draw.chord([cx + 3 * S, cy - 6 * S, cx + 9 * S, cy + 6 * S], -90, 90, fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)
        # Gold cap emblem
        draw.ellipse([cx + 2 * S, cy - 2 * S, cx + 5 * S, cy + 2 * S], fill=(230, 200, 50, 255))
        # Bearded militia cheek shadow
        draw.arc([cx - 5 * S, cy - 1 * S, cx + 5 * S, cy + 7 * S], 20, 160, fill=COLOR_BEARD, width=2 * S)
    elif soldier_type == "grenadier":
        # Bearded Chetnik-style militia cheek fringe
        draw.arc([cx - 6 * S, cy, cx + 6 * S, cy + 8 * S], 15, 165, fill=COLOR_BEARD, width=int(2.5 * S))
        draw.arc([cx - 6 * S, cy - 6 * S, cx + 6 * S, cy + 6 * S], -90, 90, fill=INK_DARK, width=int(1.5 * S))
    elif soldier_type == "sniper":
        # Ghillie camo foliage frills around helmet
        for fi in range(8):
            fa = fi * (math.pi / 4.0)
            fx = cx + (head_r - 1 * S) * math.cos(fa)
            fy = cy + (head_r - 1 * S) * math.sin(fa)
            draw.ellipse([fx - 2 * S, fy - 2 * S, fx + 2 * S, fy + 2 * S], fill=COLOR_OLIVE_LIGHT, outline=INK_DARK, width=S)
    else:
        # Standard combat helmet brim line and dome cross-hatch
        draw.arc([cx - 6 * S, cy - 6 * S, cx + 6 * S, cy + 6 * S], -90, 90, fill=INK_DARK, width=int(1.5 * S))
        img = draw_crosshatch(img, cx - 6 * S, cy - 5 * S, cx - 1 * S, cy + 5 * S, spacing=2 * S, angle=45, color=INK_LIGHT, width=S)
        draw = ImageDraw.Draw(img)

    # 5. Arms & Hands holding weapon forward (+X)
    # Left arm
    draw.line([(cx + 4 * S, cy - 10 * S), (cx + 14 * S, cy - 4 * S)], fill=torso_color, width=3 * S)
    draw.line([(cx + 4 * S, cy - 10 * S), (cx + 14 * S, cy - 4 * S)], fill=INK_DARK, width=int(1.5 * S))
    # Right arm
    draw.line([(cx + 2 * S, cy + 10 * S), (cx + 11 * S, cy + 4 * S)], fill=torso_color, width=3 * S)
    draw.line([(cx + 2 * S, cy + 10 * S), (cx + 11 * S, cy + 4 * S)], fill=INK_DARK, width=int(1.5 * S))

    # Hands (Skin tone) — kept small so they don't read as pink blobs at zoom
    draw.ellipse([cx + 13 * S, cy - 4 * S, cx + 16 * S, cy - 1 * S], fill=COLOR_SKIN, outline=INK_DARK, width=1)
    draw.ellipse([cx + 10 * S, cy + 3 * S, cx + 13 * S, cy + 6 * S], fill=COLOR_SKIN, outline=INK_DARK, width=1)

    # 6. Weapon Barrel & Receiver extending to the right (+X) — slim, dark, never a "log"
    if soldier_type == "player":
        # Minimal barrel stub only; the real per-weapon art rides on the WeaponSprite node
        draw.rectangle([cx + 10 * S, cy - 1 * S, cx + 20 * S, cy + 1 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
    elif soldier_type == "officer":
        draw.rectangle([cx + 12 * S, cy + 2 * S, cx + 22 * S, cy + 3 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
    elif soldier_type == "shotgunner":
        draw.rectangle([cx + 10 * S, cy - 1 * S, cx + 24 * S, cy + 2 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
        draw.rectangle([cx + 14 * S, cy, cx + 19 * S, cy + 2 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=1)
    elif soldier_type == "mg":
        draw.rectangle([cx + 10 * S, cy - 2 * S, cx + 26 * S, cy + 2 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
        draw.line([(cx + 18 * S, cy - 3 * S), (cx + 25 * S, cy - 3 * S)], fill=COLOR_STEEL_LIGHT, width=1)
    elif soldier_type == "sniper":
        draw.rectangle([cx + 8 * S, cy - 1 * S, cx + 27 * S, cy + 1 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
        draw.rectangle([cx + 12 * S, cy - 3 * S, cx + 18 * S, cy - 2 * S], fill=COLOR_STEEL_LIGHT, outline=INK_DARK, width=1)
    elif soldier_type == "grenadier":
        draw.rectangle([cx + 10 * S, cy - 1 * S, cx + 23 * S, cy + 1 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
        draw.rectangle([cx + 15 * S, cy + 1 * S, cx + 21 * S, cy + 3 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=1)
    else:
        # Rifleman: slim barrel + small wood furniture (kept dark so it reads as steel, not a log)
        draw.rectangle([cx + 8 * S, cy - 1 * S, cx + 24 * S, cy + 1 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
        draw.rectangle([cx + 12 * S, cy, cx + 17 * S, cy + 1 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=1)
        draw.arc([cx + 10 * S, cy + 1 * S, cx + 16 * S, cy + 6 * S], 0, 90, fill=INK_DARK, width=1)

    save_image(img, output_path, target_size=(48, 48))


def generate_soldier_legs(output_path: str) -> None:
    """Generates 128x32 soldier legs walk spritesheet (4 frames of 32x32) facing right."""
    S = 4
    FW, FH = 32 * S, 32 * S
    sheet = Image.new("RGBA", (128 * S, 32 * S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    foot_offsets = [
        ((3, -5), (-3, 5)),    # Frame 0: Left slightly fwd, Right slightly back
        ((7, -5), (-7, 5)),    # Frame 1: Full stride
        ((-3, -5), (3, 5)),    # Frame 2: Left slightly back, Right slightly fwd
        ((-7, -5), (7, 5)),    # Frame 3: Full stride
    ]

    for frame_idx, (l_off, r_off) in enumerate(foot_offsets):
        fx = frame_idx * FW
        cx, cy = fx + 16 * S, 16 * S

        for (ox, oy), is_left in [(l_off, True), (r_off, False)]:
            bx = cx + ox * S
            by = cy + oy * S

            # Trouser cuff (Olive drab)
            draw.ellipse([bx - 4 * S, by - 3 * S, bx + 1 * S, by + 3 * S],
                         fill=COLOR_OLIVE_DRAB, outline=INK_DARK, width=int(1.5 * S))
            sheet = draw_crosshatch(sheet, bx - 4 * S, by - 3 * S, bx, by + 3 * S, spacing=2 * S, angle=45, color=INK_LIGHT, width=S)
            draw = ImageDraw.Draw(sheet)

            # Combat Boot (Black/Dark Leather) pointing right (+X)
            boot_pts = [
                (bx - 3 * S, by - 2 * S),
                (bx + 4 * S, by - 2 * S),
                (bx + 6 * S, by),
                (bx + 4 * S, by + 2 * S),
                (bx - 3 * S, by + 2 * S)
            ]
            draw.polygon(boot_pts, fill=COLOR_LEATHER_DARK, outline=INK_DARK)
            draw.line([(bx - 3 * S, by + 2 * S), (bx + 5 * S, by + 2 * S)], fill=INK_DARK, width=int(1.5 * S))
            draw.line([(bx + 1 * S, by - 2 * S), (bx + 1 * S, by + 1 * S)], fill=INK_MID, width=S)
            draw.line([(bx + 3 * S, by - 1 * S), (bx + 3 * S, by + 1 * S)], fill=INK_MID, width=S)

    save_image(sheet, output_path, target_size=(128, 32))


def generate_soldier_shadow(output_path: str) -> None:
    """Generates 32x16 soft oval ink drop shadow for characters."""
    S = 4
    W, H = 32 * S, 16 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = W // 2, H // 2
    rx, ry = 12 * S, 5 * S
    draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(24, 20, 18, 120))
    img = img.filter(ImageFilter.GaussianBlur(radius=2 * S))

    save_image(img, output_path, target_size=(32, 16))


def generate_casualty_decals(output_path: str) -> None:
    """Generates 64x64 inked casualty ground chalk/ink stamp with blood pool."""
    S = 4
    W, H = 64 * S, 64 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = W // 2, H // 2

    # 1. Dark crimson blood puddle
    puddle_pts = []
    num_pts = 16
    for i in range(num_pts):
        angle = i * (2 * math.pi / num_pts)
        r = (14 + random.uniform(-4, 6)) * S
        puddle_pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle) * 0.7))
    draw.polygon(puddle_pts, fill=(110, 14, 14, 200))
    draw.polygon(puddle_pts, outline=(70, 8, 8, 240), width=int(1.5 * S))

    for _ in range(8):
        dx = random.uniform(-24, 24) * S
        dy = random.uniform(-18, 18) * S
        dr = random.uniform(1.5, 3.5) * S
        draw.ellipse([cx + dx - dr, cy + dy - dr, cx + dx + dr, cy + dy + dr], fill=COLOR_BLOOD)

    # 2. Inked soldier silhouette crumpled on the ground
    draw.ellipse([cx - 8 * S, cy - 6 * S, cx + 8 * S, cy + 6 * S], fill=(52, 60, 44, 220), outline=INK_DARK, width=2 * S)
    draw.ellipse([cx + 7 * S, cy - 9 * S, cx + 16 * S, cy - 1 * S], fill=(42, 50, 36, 220), outline=INK_DARK, width=2 * S)
    draw.line([(cx - 7 * S, cy + 2 * S), (cx - 18 * S, cy + 10 * S)], fill=INK_DARK, width=3 * S)
    draw.line([(cx - 7 * S, cy - 2 * S), (cx - 15 * S, cy - 8 * S)], fill=INK_DARK, width=3 * S)
    draw.line([(cx + 2 * S, cy - 6 * S), (cx + 4 * S, cy - 16 * S)], fill=INK_DARK, width=2 * S)
    draw.line([(cx + 2 * S, cy + 6 * S), (cx + 8 * S, cy + 15 * S)], fill=INK_DARK, width=2 * S)

    img = draw_crosshatch(img, cx - 6 * S, cy - 4 * S, cx + 6 * S, cy + 4 * S, spacing=3 * S, angle=45, color=INK_MID, width=S)

    save_image(img, output_path, target_size=(64, 64))


# ---------------------------------------------------------------------------
# 2. Armored Vehicles Generator
# ---------------------------------------------------------------------------

def generate_apc_hull(output_path: str) -> None:
    """Generates 128x64 B-80 / OT-60 8-wheeled APC hull facing right (+X)."""
    S = 4
    W, H = 128 * S, 64 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. 8 Heavy Rubber Tires (4 along top flank, 4 along bottom flank)
    tire_x_offsets = [28 * S, 52 * S, 76 * S, 100 * S]
    tire_w, tire_h = 16 * S, 10 * S

    for tx in tire_x_offsets:
        draw.rounded_rectangle([tx - tire_w // 2, 3 * S, tx + tire_w // 2, 3 * S + tire_h],
                               radius=3 * S, fill=COLOR_STEEL_DARK, outline=INK_DARK, width=2 * S)
        img = draw_crosshatch(img, tx - tire_w // 2, 3 * S, tx + tire_w // 2, 3 * S + tire_h,
                              spacing=3 * S, angle=90, color=INK_LIGHT, width=S)
        draw = ImageDraw.Draw(img)

        draw.rounded_rectangle([tx - tire_w // 2, H - 3 * S - tire_h, tx + tire_w // 2, H - 3 * S],
                               radius=3 * S, fill=COLOR_STEEL_DARK, outline=INK_DARK, width=2 * S)
        img = draw_crosshatch(img, tx - tire_w // 2, H - 3 * S - tire_h, tx + tire_w // 2, H - 3 * S,
                              spacing=3 * S, angle=90, color=INK_LIGHT, width=S)
        draw = ImageDraw.Draw(img)

    # 2. Sloped Armored Hull Body
    hull_pts = [
        (12 * S, 12 * S),
        (96 * S, 12 * S),
        (122 * S, 28 * S),
        (124 * S, 32 * S),
        (122 * S, 36 * S),
        (96 * S, 52 * S),
        (12 * S, 52 * S),
        (10 * S, 48 * S),
        (10 * S, 16 * S)
    ]
    draw.polygon(hull_pts, fill=COLOR_OLIVE_DRAB, outline=INK_DARK)
    draw.line(hull_pts + [hull_pts[0]], fill=INK_DARK, width=int(2.5 * S))

    # 3. Sloped Glacis Armor & Panel lines
    draw.line([(96 * S, 12 * S), (96 * S, 52 * S)], fill=INK_DARK, width=2 * S)
    draw.line([(96 * S, 32 * S), (122 * S, 32 * S)], fill=INK_MID, width=int(1.5 * S))
    draw.rectangle([102 * S, 20 * S, 114 * S, 44 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))

    # 4. Roof Hatches & Turret Mount Ring
    tcx, tcy = 64 * S, 32 * S
    tr = 14 * S
    draw.ellipse([tcx - tr, tcy - tr, tcx + tr, tcy + tr], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=2 * S)

    draw.rectangle([80 * S, 16 * S, 90 * S, 26 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
    draw.rectangle([80 * S, 38 * S, 90 * S, 48 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
    draw.rectangle([22 * S, 18 * S, 44 * S, 30 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
    draw.rectangle([22 * S, 34 * S, 44 * S, 46 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))

    for li in range(5):
        lx = 30 * S + li * 4 * S
        draw.line([(lx, 15 * S), (lx, 17 * S)], fill=INK_DARK, width=int(1.5 * S))
        draw.line([(lx, 47 * S), (lx, 49 * S)], fill=INK_DARK, width=int(1.5 * S))

    # Cross-hatching for armor shade
    img = draw_crosshatch(img, 14 * S, 14 * S, 60 * S, 50 * S, spacing=5 * S, angle=45, color=INK_LIGHT, width=S)

    save_image(img, output_path, target_size=(128, 64))


def generate_apc_turret(output_path: str) -> None:
    """Generates 48x32 APC rotating machine gun turret facing right (+X)."""
    S = 4
    W, H = 48 * S, 32 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    tcx, tcy = 18 * S, 16 * S

    # 1. Conical faceted armored turret cupola
    cr = 12 * S
    draw.ellipse([tcx - cr, tcy - cr, tcx + cr, tcy + cr], fill=COLOR_OLIVE_DRAB, outline=INK_DARK, width=2 * S)
    draw.ellipse([tcx - 6 * S, tcy - 6 * S, tcx + 6 * S, tcy + 6 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
    img = draw_crosshatch(img, tcx - 10 * S, tcy - 10 * S, tcx + 2 * S, tcy + 10 * S, spacing=3 * S, angle=60, color=INK_LIGHT, width=S)
    draw = ImageDraw.Draw(img)

    # 2. Dual Heavy Machine Gun Barrels
    draw.rectangle([tcx + 8 * S, tcy - 4 * S, tcx + 26 * S, tcy - 1 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=int(1.5 * S))
    draw.polygon([(tcx + 26 * S, tcy - 5 * S), (tcx + 29 * S, tcy - 6 * S),
                  (tcx + 29 * S, tcy), (tcx + 26 * S, tcy)], fill=COLOR_STEEL_LIGHT, outline=INK_DARK)
    draw.rectangle([tcx + 8 * S, tcy + 1 * S, tcx + 22 * S, tcy + 3 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)
    draw.rounded_rectangle([tcx + 4 * S, tcy - 6 * S, tcx + 10 * S, tcy + 6 * S], radius=2 * S, fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))

    save_image(img, output_path, target_size=(48, 32))


def generate_apc_wreck(output_path: str) -> None:
    """Generates 128x64 burned-out, blackened APC wreck with blown hatches and soot."""
    S = 4
    W, H = 128 * S, 64 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    tire_x_offsets = [28 * S, 52 * S, 76 * S, 100 * S]
    for tx in tire_x_offsets:
        draw.rectangle([tx - 6 * S, 4 * S, tx + 6 * S, 12 * S], fill=(22, 20, 18, 255), outline=INK_DARK, width=int(1.5 * S))
        draw.rectangle([tx - 6 * S, H - 12 * S, tx + 6 * S, H - 4 * S], fill=(22, 20, 18, 255), outline=INK_DARK, width=int(1.5 * S))

    hull_pts = [
        (12 * S, 13 * S), (96 * S, 12 * S), (120 * S, 29 * S), (118 * S, 35 * S),
        (96 * S, 51 * S), (12 * S, 52 * S), (10 * S, 16 * S)
    ]
    draw.polygon(hull_pts, fill=(35, 32, 28, 255), outline=INK_DARK)
    draw.line(hull_pts + [hull_pts[0]], fill=INK_DARK, width=int(2.5 * S))

    hole_pts = [
        (54 * S, 24 * S), (74 * S, 20 * S), (82 * S, 32 * S),
        (76 * S, 44 * S), (58 * S, 42 * S), (50 * S, 32 * S)
    ]
    draw.polygon(hole_pts, fill=(12, 10, 8, 255), outline=INK_DARK, width=2 * S)

    img = draw_crosshatch(img, 20 * S, 14 * S, 100 * S, 50 * S, spacing=3 * S, angle=45, color=(18, 16, 14, 200), width=int(1.5 * S))
    img = draw_crosshatch(img, 20 * S, 14 * S, 100 * S, 50 * S, spacing=4 * S, angle=-45, color=(18, 16, 14, 180), width=int(1.5 * S))

    # Rust streaks via alpha composite overlay
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    draw_ov.line([(30 * S, 20 * S), (24 * S, 35 * S)], fill=(120, 50, 20, 200), width=2 * S)
    draw_ov.line([(85 * S, 22 * S), (92 * S, 40 * S)], fill=(120, 50, 20, 200), width=2 * S)
    img = Image.alpha_composite(img, overlay)

    save_image(img, output_path, target_size=(128, 64))


def generate_tank_hull(output_path: str) -> None:
    """Generates 160x96 T-55 Main Battle Tank hull facing right (+X)."""
    S = 4
    W, H = 160 * S, 96 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Caterpillar Continuous Tracks
    draw.rectangle([14 * S, 6 * S, 148 * S, 22 * S], fill=(42, 40, 36, 255), outline=INK_DARK, width=2 * S)
    draw.rectangle([14 * S, 74 * S, 148 * S, 90 * S], fill=(42, 40, 36, 255), outline=INK_DARK, width=2 * S)

    for wi in range(5):
        wx = 34 * S + wi * 24 * S
        draw.ellipse([wx - 8 * S, 7 * S, wx + 8 * S, 21 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
        draw.ellipse([wx - 3 * S, 11 * S, wx + 3 * S, 17 * S], fill=COLOR_STEEL_DARK)
        draw.ellipse([wx - 8 * S, 75 * S, wx + 8 * S, 89 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
        draw.ellipse([wx - 3 * S, 79 * S, wx + 3 * S, 85 * S], fill=COLOR_STEEL_DARK)

    # Track treads
    img = draw_crosshatch(img, 14 * S, 6 * S, 148 * S, 22 * S, spacing=3 * S, angle=90, color=INK_DARK, width=int(1.5 * S))
    img = draw_crosshatch(img, 14 * S, 74 * S, 148 * S, 90 * S, spacing=3 * S, angle=90, color=INK_DARK, width=int(1.5 * S))
    draw = ImageDraw.Draw(img)

    # 2. Main Tank Armored Hull Body
    hull_pts = [
        (16 * S, 20 * S),
        (128 * S, 20 * S),
        (152 * S, 36 * S),
        (154 * S, 48 * S),
        (152 * S, 60 * S),
        (128 * S, 76 * S),
        (16 * S, 76 * S)
    ]
    draw.polygon(hull_pts, fill=COLOR_OLIVE_DRAB, outline=INK_DARK)
    draw.line(hull_pts + [hull_pts[0]], fill=INK_DARK, width=int(2.5 * S))

    # 3. Sloped Front Glacis Plate
    draw.line([(128 * S, 20 * S), (128 * S, 76 * S)], fill=INK_DARK, width=2 * S)
    draw.line([(130 * S, 26 * S), (146 * S, 48 * S)], fill=COLOR_OLIVE_DARK, width=2 * S)
    draw.line([(130 * S, 70 * S), (146 * S, 48 * S)], fill=COLOR_OLIVE_DARK, width=2 * S)

    # 4. Central Turret Mount Ring
    tcx, tcy = 76 * S, 48 * S
    tr = 22 * S
    draw.ellipse([tcx - tr, tcy - tr, tcx + tr, tcy + tr], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=2 * S)

    # 5. Rear Engine Deck & Louvers (Weak point!)
    draw.rectangle([18 * S, 24 * S, 52 * S, 72 * S], fill=(58, 68, 46, 255), outline=INK_DARK, width=2 * S)
    draw.ellipse([24 * S, 28 * S, 42 * S, 46 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=int(1.5 * S))
    img = draw_crosshatch(img, 24 * S, 28 * S, 42 * S, 46 * S, spacing=2 * S, angle=45, color=INK_MID, width=S)
    draw = ImageDraw.Draw(img)

    draw.ellipse([24 * S, 50 * S, 42 * S, 68 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=int(1.5 * S))
    img = draw_crosshatch(img, 24 * S, 50 * S, 42 * S, 68 * S, spacing=2 * S, angle=45, color=INK_MID, width=S)
    draw = ImageDraw.Draw(img)

    draw.rectangle([8 * S, 26 * S, 15 * S, 44 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
    draw.rectangle([8 * S, 52 * S, 15 * S, 70 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))

    # Cross-hatching shading on hull armor
    img = draw_crosshatch(img, 54 * S, 22 * S, 126 * S, 74 * S, spacing=6 * S, angle=45, color=INK_LIGHT, width=S)

    save_image(img, output_path, target_size=(160, 96))


def generate_tank_turret(output_path: str) -> None:
    """Generates 112x48 T-55 rotating dome turret with long 100mm rifled cannon facing right."""
    S = 4
    W, H = 112 * S, 48 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    tcx, tcy = 28 * S, 24 * S

    # 1. 100mm Main Gun Barrel
    draw.rectangle([tcx + 14 * S, tcy - 3 * S, tcx + 78 * S, tcy + 3 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=2 * S)
    draw.rectangle([tcx + 50 * S, tcy - 4 * S, tcx + 62 * S, tcy + 4 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
    draw.rectangle([tcx + 76 * S, tcy - 4 * S, tcx + 80 * S, tcy + 4 * S], fill=COLOR_STEEL_LIGHT, outline=INK_DARK, width=int(1.5 * S))

    # 2. Gun Mantlet
    mantlet_pts = [
        (tcx + 12 * S, tcy - 8 * S),
        (tcx + 18 * S, tcy - 5 * S),
        (tcx + 18 * S, tcy + 5 * S),
        (tcx + 12 * S, tcy + 8 * S)
    ]
    draw.polygon(mantlet_pts, fill=COLOR_KHAKI, outline=INK_DARK)

    # 3. Cast Dome Turret
    tr_x, tr_y = 22 * S, 18 * S
    draw.ellipse([tcx - tr_x, tcy - tr_y, tcx + tr_x, tcy + tr_y], fill=COLOR_OLIVE_DRAB, outline=INK_DARK, width=int(2.5 * S))
    draw.ellipse([tcx - 6 * S, tcy - 14 * S, tcx + 6 * S, tcy - 4 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
    draw.ellipse([tcx - 6 * S, tcy + 4 * S, tcx + 6 * S, tcy + 14 * S], fill=COLOR_OLIVE_DARK, outline=INK_DARK, width=int(1.5 * S))
    draw.rectangle([tcx + 12 * S, tcy - 12 * S, tcx + 16 * S, tcy - 8 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)

    img = draw_crosshatch(img, tcx - 18 * S, tcy - 14 * S, tcx + 2 * S, tcy + 14 * S, spacing=4 * S, angle=60, color=INK_LIGHT, width=S)

    save_image(img, output_path, target_size=(112, 48))


def generate_tank_wreck(output_path: str) -> None:
    """Generates 160x96 smoldering T-55 tank wreck with broken track and charred armor."""
    S = 4
    W, H = 160 * S, 96 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.rectangle([14 * S, 6 * S, 148 * S, 22 * S], fill=(24, 22, 20, 255), outline=INK_DARK, width=2 * S)
    draw.polygon([(14 * S, 74 * S), (110 * S, 74 * S), (124 * S, 88 * S), (80 * S, 94 * S), (14 * S, 90 * S)],
                 fill=(24, 22, 20, 255), outline=INK_DARK, width=2 * S)

    hull_pts = [
        (16 * S, 20 * S), (128 * S, 20 * S), (150 * S, 36 * S),
        (148 * S, 58 * S), (126 * S, 76 * S), (16 * S, 76 * S)
    ]
    draw.polygon(hull_pts, fill=(32, 28, 25, 255), outline=INK_DARK)
    draw.line(hull_pts + [hull_pts[0]], fill=INK_DARK, width=int(2.5 * S))

    hole_pts = [
        (22 * S, 30 * S), (46 * S, 26 * S), (52 * S, 54 * S),
        (40 * S, 68 * S), (20 * S, 62 * S)
    ]
    draw.polygon(hole_pts, fill=(10, 8, 8, 255), outline=INK_DARK, width=2 * S)

    img = draw_crosshatch(img, 16 * S, 20 * S, 148 * S, 76 * S, spacing=4 * S, angle=45, color=(16, 14, 12, 220), width=int(1.5 * S))
    img = draw_crosshatch(img, 16 * S, 20 * S, 148 * S, 76 * S, spacing=4 * S, angle=-45, color=(16, 14, 12, 180), width=int(1.5 * S))

    # Rust/heat discoloration overlay
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    draw_ov.ellipse([60 * S, 32 * S, 94 * S, 64 * S], outline=(140, 55, 20, 180), width=3 * S)
    img = Image.alpha_composite(img, overlay)

    save_image(img, output_path, target_size=(160, 96))


# ---------------------------------------------------------------------------
# 3. Terrain Field Maps Generator (512x512 Seamless/Field Maps)
# ---------------------------------------------------------------------------

def generate_terrain_staging(output_path: str) -> None:
    """Generates 512x512 Forest Staging & Farmland map (Mission 1) with 100% opacity."""
    img = Image.new("RGBA", (512, 512), (225, 218, 195, 255))

    # Translucent watercolor washes and markings drawn onto overlay
    overlay = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)

    # 1. Warm olive grass wash patches + tilled soil patches
    for _ in range(40):
        px = random.randint(0, 512)
        py = random.randint(0, 512)
        pr = random.randint(30, 90)
        draw_ov.ellipse([px - pr, py - pr, px + pr, py + pr], fill=(138, 156, 114, 45))
    for _ in range(22):
        px = random.randint(0, 512)
        py = random.randint(0, 512)
        pr = random.randint(18, 55)
        draw_ov.ellipse([px - pr, py - pr // 2, px + pr, py + pr // 2], fill=(150, 122, 84, 38))
    # Grass blade strokes and hay speckles (hand-sketched ground detail)
    for _ in range(420):
        gx = random.randint(0, 511)
        gy = random.randint(0, 511)
        ln = random.randint(3, 7)
        tilt = random.randint(-3, 3)
        draw_ov.line([(gx, gy), (gx + tilt, gy - ln)], fill=(104, 122, 74, 70), width=1)
    for _ in range(260):
        sx = random.randint(0, 511)
        sy = random.randint(0, 511)
        draw_ov.point((sx, sy), fill=(178, 152, 96, 90))

    # 2. Hand-inked topographic contour lines
    for contour_y in range(40, 500, 64):
        pts = []
        for x in range(0, 513, 32):
            wave = 20 * math.sin(x * 0.02 + contour_y) + 10 * math.cos(x * 0.04)
            pts.append((x, contour_y + wave))
        draw_ov.line(pts, fill=(100, 90, 75, 110), width=1)
        draw_ov.text((256, int(contour_y + 5)), f"{120 + (contour_y // 4)}m", fill=(100, 90, 75, 140))

    # 3. Tactical grid coordinate ticks (+) every 128px
    for gx in range(64, 512, 128):
        for gy in range(64, 512, 128):
            draw_ov.line([(gx - 8, gy), (gx + 8, gy)], fill=INK_MID, width=1)
            draw_ov.line([(gx, gy - 8), (gx, gy + 8)], fill=INK_MID, width=1)

    # 4. Dirt wheel ruts / cart tracks
    road_pts_l = [(x, 220 + 30 * math.sin(x * 0.015)) for x in range(0, 513, 16)]
    road_pts_r = [(x, 240 + 30 * math.sin(x * 0.015)) for x in range(0, 513, 16)]
    draw_ov.line(road_pts_l, fill=(140, 115, 80, 130), width=2)
    draw_ov.line(road_pts_r, fill=(140, 115, 80, 130), width=2)

    img = Image.alpha_composite(img, overlay)
    img.putalpha(255)  # Enforce 100% solid opacity
    save_image(img, output_path, target_size=(512, 512))


def generate_terrain_trenches(output_path: str) -> None:
    """Generates 512x512 Trench Warfare & Mud map (Mission 2 - Lika Front) with 100% opacity."""
    img = Image.new("RGBA", (512, 512), (110, 86, 60, 255))

    # Translucent mud churn washes drawn onto overlay
    overlay = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)

    # 1. Mud churn washes + wet puddle sheen + boot/track scuffs
    for _ in range(50):
        px = random.randint(0, 512)
        py = random.randint(0, 512)
        pr = random.randint(25, 80)
        draw_ov.ellipse([px - pr, py - pr, px + pr, py + pr], fill=(85, 65, 42, 70))
    for _ in range(14):
        px = random.randint(0, 480)
        py = random.randint(0, 480)
        draw_ov.ellipse([px, py, px + random.randint(14, 34), py + random.randint(8, 16)], fill=(70, 78, 84, 60))
    for _ in range(300):
        sx = random.randint(0, 511)
        sy = random.randint(0, 511)
        draw_ov.line([(sx, sy), (sx + random.randint(-6, 6), sy + random.randint(-4, 4))], fill=(60, 46, 30, 60), width=1)

    # Craters outer rims on overlay
    craters = [(100, 200, 32), (380, 210, 40), (260, 370, 30), (420, 380, 26)]
    for cx, cy, cr in craters:
        draw_ov.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(140, 110, 75, 200), outline=INK_DARK, width=2)

    img = Image.alpha_composite(img, overlay)
    draw = ImageDraw.Draw(img)

    # 2. Zigzagging military trench network
    trench_segments = [
        [(40, 80), (140, 120), (200, 80), (320, 140), (420, 90), (480, 130)],
        [(30, 260), (120, 310), (220, 260), (340, 320), (440, 270), (490, 300)],
        [(50, 420), (160, 460), (240, 410), (360, 470), (460, 430)]
    ]
    for seg in trench_segments:
        draw.line(seg, fill=INK_DARK, width=20)
        draw.line(seg, fill=(45, 32, 20, 255), width=16)
        draw.line(seg, fill=(160, 125, 80, 255), width=4)

    # Crater dark center
    for cx, cy, cr in craters:
        draw.ellipse([cx - cr * 0.6, cy - cr * 0.6, cx + cr * 0.6, cy + cr * 0.6], fill=(40, 30, 20, 255))

    # 4. Barbed wire barrier markers
    for bx in range(60, 480, 24):
        draw.line([(bx, 180), (bx + 16, 180)], fill=INK_MID, width=1)
        draw.line([(bx + 8, 175), (bx + 8, 185)], fill=INK_DARK, width=2)

    img.putalpha(255)  # Enforce 100% solid opacity
    save_image(img, output_path, target_size=(512, 512))


def generate_terrain_highway(output_path: str) -> None:
    """Generates 512x512 Highway Ambush map with asphalt & gravel (Mission 3) with 100% opacity."""
    img = Image.new("RGBA", (512, 512), (155, 142, 115, 255))

    # Translucent scrubland washes on overlay
    overlay = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)

    # 1. Balkan scrubland texture + dry grass strokes + gravel speckle
    for _ in range(40):
        px = random.randint(0, 512)
        py = random.randint(0, 512)
        draw_ov.ellipse([px - 30, py - 30, px + 30, py + 30], fill=(135, 125, 95, 60))
    for _ in range(380):
        gx = random.randint(0, 511)
        gy = random.randint(0, 511)
        if 160 < gy < 350:
            continue  # keep the asphalt clean
        draw_ov.line([(gx, gy), (gx + random.randint(-3, 3), gy - random.randint(3, 6))], fill=(150, 138, 92, 70), width=1)
    for _ in range(220):
        draw_ov.point((random.randint(0, 511), random.randint(0, 511)), fill=(96, 90, 74, 110))

    img = Image.alpha_composite(img, overlay)
    draw = ImageDraw.Draw(img)

    # 2. Highway Asphalt Strip
    draw.rectangle([0, 180, 512, 332], fill=(70, 72, 70, 255))
    draw.line([(0, 180), (512, 180)], fill=INK_DARK, width=3)
    draw.line([(0, 332), (512, 332)], fill=INK_DARK, width=3)

    # Gravel shoulders on overlay for proper blend
    overlay_road = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw_ro = ImageDraw.Draw(overlay_road)
    draw_ro.rectangle([0, 164, 512, 180], fill=(120, 115, 95, 200))
    draw_ro.rectangle([0, 332, 512, 348], fill=(120, 115, 95, 200))

    # Faded dashed yellow highway centerline
    for dx in range(0, 512, 40):
        draw_ro.line([(dx, 256), (dx + 22, 256)], fill=(210, 180, 45, 220), width=4)

    # Asphalt cracks and skid marks
    for _ in range(8):
        sx = random.randint(30, 450)
        draw_ro.arc([sx, 220, sx + 60, 290], 0, 180, fill=(35, 35, 35, 160), width=3)

    img = Image.alpha_composite(img, overlay_road)
    img.putalpha(255)  # Enforce 100% solid opacity
    save_image(img, output_path, target_size=(512, 512))


def generate_terrain_urban(output_path: str) -> None:
    """Generates 512x512 Urban Cobblestone & Pavement Street grid (Mission 4 - Knin) with 100% opacity."""
    img = Image.new("RGBA", (512, 512), (130, 128, 122, 255))
    draw = ImageDraw.Draw(img)

    # 1. Cobblestone paver pattern
    for y in range(0, 512, 12):
        x_shift = 6 if (y // 12) % 2 == 1 else 0
        for x in range(0, 512, 16):
            draw.rectangle([x + x_shift, y, x + x_shift + 14, y + 10],
                           fill=(115 + (x * 7) % 20, 112 + (y * 5) % 20, 108, 255),
                           outline=INK_DARK, width=1)

    # 2. Paved Main Street intersection
    draw.rectangle([0, 200, 512, 312], fill=(85, 84, 82, 255), outline=INK_DARK, width=2)
    draw.rectangle([200, 0, 312, 512], fill=(85, 84, 82, 255), outline=INK_DARK, width=2)

    # 3. Sidewalk curbs
    draw.line([(0, 198), (512, 198)], fill=(160, 158, 152, 255), width=4)
    draw.line([(0, 314), (512, 314)], fill=(160, 158, 152, 255), width=4)
    draw.line([(198, 0), (198, 512)], fill=(160, 158, 152, 255), width=4)
    draw.line([(314, 0), (314, 512)], fill=(160, 158, 152, 255), width=4)

    # Crosswalk overlay for translucent stripes
    overlay = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    for zi in range(208, 308, 14):
        draw_ov.rectangle([160, zi, 190, zi + 8], fill=(210, 210, 200, 220))
        draw_ov.rectangle([322, zi, 352, zi + 8], fill=(210, 210, 200, 220))

    img = Image.alpha_composite(img, overlay)
    draw = ImageDraw.Draw(img)

    # Masonry rubble & debris piles
    for rx, ry in [(90, 90), (410, 110), (110, 420), (420, 420)]:
        for _ in range(12):
            bx = rx + random.randint(-20, 20)
            by = ry + random.randint(-20, 20)
            draw.rectangle([bx, by, bx + 6, by + 4], fill=(165, 85, 50, 255), outline=INK_DARK, width=1)

    # Ash smudges & glass/spall speckle (war-torn street detail)
    overlay_ash = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw_ash = ImageDraw.Draw(overlay_ash)
    for _ in range(18):
        ax = random.randint(0, 480)
        ay = random.randint(0, 480)
        draw_ash.ellipse([ax, ay, ax + random.randint(20, 60), ay + random.randint(10, 30)], fill=(40, 38, 36, 40))
    for _ in range(240):
        draw_ash.point((random.randint(0, 511), random.randint(0, 511)), fill=(200, 196, 186, 90))
    img = Image.alpha_composite(img, overlay_ash)
    draw = ImageDraw.Draw(img)

    img.putalpha(255)  # Enforce 100% solid opacity
    save_image(img, output_path, target_size=(512, 512))


def generate_terrain_fortress(output_path: str) -> None:
    """Generates 512x512 Knin Fortress stone flagstone pavers & masonry (Mission 5) with 100% opacity."""
    img = Image.new("RGBA", (512, 512), (160, 156, 148, 255))
    draw = ImageDraw.Draw(img)

    # 1. Ancient rectangular limestone flagstones
    tile_w, tile_h = 48, 32
    for row, y in enumerate(range(0, 512, tile_h)):
        offset = 24 if row % 2 == 1 else 0
        for x in range(-24, 512, tile_w):
            tx0, ty0 = x + offset, y
            shade = random.randint(-12, 12)
            stone_c = (150 + shade, 146 + shade, 138 + shade, 255)
            draw.rectangle([tx0, ty0, tx0 + tile_w - 2, ty0 + tile_h - 2], fill=stone_c, outline=INK_MID, width=1)
            if random.random() > 0.6:
                draw.line([(tx0 + 6, ty0 + 10), (tx0 + 20, ty0 + 20)], fill=INK_MID, width=1)

    # 2. Rampart edge stone coping / battlements along top edge
    draw.rectangle([0, 0, 512, 28], fill=(110, 106, 100, 255), outline=INK_DARK, width=3)
    for bx in range(20, 500, 60):
        draw.rectangle([bx, 4, bx + 32, 24], fill=(85, 82, 78, 255), outline=INK_DARK, width=2)

    # 3. Weathering moss / lichen green washes on overlay
    overlay = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    for _ in range(25):
        mx = random.randint(0, 512)
        my = random.randint(30, 512)
        draw_ov.ellipse([mx - 15, my - 8, mx + 15, my + 8], fill=(85, 105, 70, 50))

    img = Image.alpha_composite(img, overlay)
    img.putalpha(255)  # Enforce 100% solid opacity
    save_image(img, output_path, target_size=(512, 512))


# ---------------------------------------------------------------------------
# 4. Illustrated Props Generator
# ---------------------------------------------------------------------------

def generate_building_roof_tiles(output_path: str) -> None:
    """Generates 160x120 Mediterranean terracotta clay tile roof with drop shadow."""
    S = 4
    W, H = 160 * S, 120 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Soft ink drop shadow along bottom-right edge
    draw.rectangle([10 * S, 10 * S, 158 * S, 118 * S], fill=(25, 20, 18, 90))

    # 2. Main terracotta roof slab
    rx0, ry0, rx1, ry1 = 4 * S, 4 * S, 152 * S, 112 * S
    draw.rectangle([rx0, ry0, rx1, ry1], fill=(186, 88, 52, 255), outline=INK_DARK, width=int(2.5 * S))

    # 3. Scalloped overlapping terracotta tile rows with alternating row shading
    row_h = 8 * S
    tile_w = 12 * S
    for ri, y in enumerate(range(ry0, ry1, row_h)):
        shade = (208, 104, 64, 255) if ri % 2 == 0 else (170, 78, 44, 255)
        draw.rectangle([rx0, y, rx1, y + row_h], fill=shade)
        draw.line([(rx0, y), (rx1, y)], fill=INK_DARK, width=int(1.2 * S))
        for x in range(rx0, rx1, tile_w):
            draw.arc([x, y - 2 * S, x + tile_w, y + row_h * 2], 180, 360, fill=INK_MID, width=int(1.8 * S))
            draw.line([(x + tile_w // 2, y + 2 * S), (x + tile_w // 2, y + row_h - 2 * S)],
                      fill=(232, 130, 84, 255), width=int(1.5 * S))

    # 4. Central Roof Ridge Cap line (thicker, tiled caps)
    mid_y = (ry0 + ry1) // 2
    draw.rectangle([rx0, mid_y - 4 * S, rx1, mid_y + 4 * S], fill=(150, 64, 36, 255), outline=INK_DARK, width=int(1.5 * S))
    for x in range(rx0 + 2 * S, rx1 - 4 * S, 10 * S):
        draw.arc([x, mid_y - 4 * S, x + 10 * S, mid_y + 4 * S], 180, 360, fill=INK_MID, width=int(1.5 * S))

    # 5. Small brick chimney stack
    draw.rectangle([120 * S, 16 * S, 136 * S, 32 * S], fill=(140, 60, 35, 255), outline=INK_DARK, width=int(1.5 * S))
    draw.rectangle([122 * S, 18 * S, 134 * S, 30 * S], fill=(30, 25, 22, 255))

    save_image(img, output_path, target_size=(160, 120))


def generate_building_roof_tin(output_path: str) -> None:
    """Generates 140x100 Corrugated industrial tin roof with rust runoff & shadow."""
    S = 4
    W, H = 140 * S, 100 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Soft ink drop shadow
    draw.rectangle([8 * S, 8 * S, 138 * S, 98 * S], fill=(25, 20, 18, 90))

    # 2. Tin roof slab
    rx0, ry0, rx1, ry1 = 4 * S, 4 * S, 134 * S, 94 * S
    draw.rectangle([rx0, ry0, rx1, ry1], fill=(125, 135, 142, 255), outline=INK_DARK, width=int(2.5 * S))

    # 3. Vertical Corrugation Seams
    rib_spacing = 6 * S
    for x in range(rx0 + rib_spacing, rx1, rib_spacing):
        draw.line([(x, ry0), (x, ry1)], fill=INK_DARK, width=int(1.5 * S))
        draw.line([(x + S, ry0), (x + S, ry1)], fill=(165, 175, 182, 255), width=S)

    # 4. Weathered rust runoff streaks via overlay composite
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    for rx, ry_len in [(32 * S, 40 * S), (75 * S, 60 * S), (110 * S, 35 * S)]:
        draw_ov.line([(rx, ry0), (rx, ry0 + ry_len)], fill=(145, 75, 40, 200), width=3 * S)
    img = Image.alpha_composite(img, overlay)
    draw = ImageDraw.Draw(img)

    # Rivet lines
    for x in range(rx0 + 4 * S, rx1 - 4 * S, 12 * S):
        draw.ellipse([x - S, ry0 + 3 * S - S, x + S, ry0 + 3 * S + S], fill=COLOR_STEEL_DARK)
        draw.ellipse([x - S, ry1 - 3 * S - S, x + S, ry1 - 3 * S + S], fill=COLOR_STEEL_DARK)

    save_image(img, output_path, target_size=(140, 100))


def generate_bunker_concrete(output_path: str) -> None:
    """Generates 96x72 concrete pillbox bunker with firing embrasure slit."""
    S = 4
    W, H = 96 * S, 72 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    pts = [
        (10 * S, 10 * S),
        (72 * S, 10 * S),
        (88 * S, 24 * S),
        (88 * S, 48 * S),
        (72 * S, 62 * S),
        (10 * S, 62 * S)
    ]
    draw.polygon(pts, fill=(120, 124, 120, 255), outline=INK_DARK)
    draw.line(pts + [pts[0]], fill=INK_DARK, width=int(2.5 * S))

    draw.rectangle([76 * S, 28 * S, 88 * S, 44 * S], fill=(16, 14, 12, 255), outline=INK_DARK, width=2 * S)
    draw.ellipse([64 * S, 6 * S, 82 * S, 18 * S], fill=COLOR_KHAKI, outline=INK_DARK, width=int(1.5 * S))
    draw.ellipse([64 * S, 54 * S, 82 * S, 66 * S], fill=COLOR_KHAKI, outline=INK_DARK, width=int(1.5 * S))

    for y in range(16 * S, 60 * S, 8 * S):
        draw.line([(12 * S, y), (70 * S, y)], fill=(95, 98, 95, 255), width=S)

    img = draw_crosshatch(img, 12 * S, 12 * S, 60 * S, 60 * S, spacing=5 * S, angle=45, color=INK_LIGHT, width=S)

    save_image(img, output_path, target_size=(96, 72))


def generate_sandbag_straight(output_path: str) -> None:
    """Generates 64x24 straight stacked sandbag revetment wall."""
    S = 4
    W, H = 64 * S, 24 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    bag_w, bag_h = 14 * S, 9 * S
    for row in range(2):
        y = 2 * S + row * 9 * S
        x_start = 2 * S if row == 0 else -4 * S
        for x in range(x_start, W, bag_w - 2 * S):
            draw.rounded_rectangle([x, y, x + bag_w, y + bag_h], radius=3 * S,
                                   fill=COLOR_KHAKI, outline=INK_DARK, width=int(1.5 * S))
            draw.line([(x + 2 * S, y + bag_h // 2), (x + bag_w - 2 * S, y + bag_h // 2)], fill=INK_MID, width=S)
            img = draw_crosshatch(img, x + 2 * S, y + 2 * S, x + bag_w - 2 * S, y + bag_h - 2 * S,
                                  spacing=3 * S, angle=45, color=INK_LIGHT, width=S)
            draw = ImageDraw.Draw(img)

    save_image(img, output_path, target_size=(64, 24))


def generate_sandbag_corner(output_path: str) -> None:
    """Generates 48x48 90-degree corner sandbag defensive revetment."""
    S = 4
    W, H = 48 * S, 48 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for x in range(2 * S, 44 * S, 11 * S):
        draw.rounded_rectangle([x, 3 * S, x + 12 * S, 16 * S], radius=3 * S,
                               fill=COLOR_KHAKI, outline=INK_DARK, width=int(1.5 * S))
        img = draw_crosshatch(img, x, 3 * S, x + 12 * S, 16 * S, spacing=3 * S, angle=45, color=INK_LIGHT, width=S)
        draw = ImageDraw.Draw(img)

    for y in range(16 * S, 44 * S, 11 * S):
        draw.rounded_rectangle([3 * S, y, 16 * S, y + 12 * S], radius=3 * S,
                               fill=COLOR_KHAKI, outline=INK_DARK, width=int(1.5 * S))
        img = draw_crosshatch(img, 3 * S, y, 16 * S, y + 12 * S, spacing=3 * S, angle=45, color=INK_LIGHT, width=S)
        draw = ImageDraw.Draw(img)

    save_image(img, output_path, target_size=(48, 48))


def generate_ammo_crate_wooden(output_path: str) -> None:
    """Generates 32x32 military wooden ammo crate with corner brackets and stencil."""
    S = 4
    W, H = 32 * S, 32 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.rectangle([2 * S, 2 * S, 30 * S, 30 * S], fill=(88, 102, 68, 255), outline=INK_DARK, width=int(1.5 * S))
    draw.line([(2 * S, 11 * S), (30 * S, 11 * S)], fill=INK_DARK, width=int(1.5 * S))
    draw.line([(2 * S, 21 * S), (30 * S, 21 * S)], fill=INK_DARK, width=int(1.5 * S))

    bw = 5 * S
    for cx, cy in [(2 * S, 2 * S), (30 * S - bw, 2 * S), (2 * S, 30 * S - bw), (30 * S - bw, 30 * S - bw)]:
        draw.rectangle([cx, cy, cx + bw, cy + bw], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)

    draw.line([(12 * S, 16 * S), (20 * S, 16 * S)], fill=(220, 190, 45, 255), width=2 * S)
    draw.line([(16 * S, 12 * S), (16 * S, 20 * S)], fill=(220, 190, 45, 255), width=2 * S)

    draw.arc([0, 12 * S, 4 * S, 20 * S], 90, 270, fill=INK_DARK, width=int(1.5 * S))
    draw.arc([28 * S, 12 * S, 32 * S, 20 * S], -90, 90, fill=INK_DARK, width=int(1.5 * S))

    save_image(img, output_path, target_size=(32, 32))


def generate_fuel_drum(output_path: str) -> None:
    """Generates 28x28 circular top-down steel fuel drum with rim chimes & bungs."""
    S = 4
    W, H = 28 * S, 28 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = W // 2, H // 2
    r = 12 * S

    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(165, 42, 32, 255), outline=INK_DARK, width=2 * S)
    draw.ellipse([cx - r + 3 * S, cy - r + 3 * S, cx + r - 3 * S, cy + r - 3 * S],
                 fill=(145, 36, 28, 255), outline=INK_DARK, width=int(1.5 * S))
    draw.ellipse([cx - 4 * S, cy - 6 * S, cx, cy - 2 * S], fill=COLOR_STEEL_LIGHT, outline=INK_DARK, width=S)
    draw.ellipse([cx + 2 * S, cy + 3 * S, cx + 5 * S, cy + 6 * S], fill=COLOR_STEEL_LIGHT, outline=INK_DARK, width=S)

    img = draw_crosshatch(img, cx - 8 * S, cy - 4 * S, cx + 6 * S, cy + 8 * S, spacing=2 * S, angle=45, color=INK_MID, width=S)

    save_image(img, output_path, target_size=(28, 28))


def generate_barbed_wire(output_path: str) -> None:
    """Generates 64x20 concertina barbed wire coil obstacle."""
    S = 4
    W, H = 64 * S, 20 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cy = H // 2

    for px in [10 * S, 32 * S, 54 * S]:
        draw.rectangle([px - 2 * S, 2 * S, px + 2 * S, H - 2 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=S)

    for x in range(4 * S, W - 8 * S, 6 * S):
        draw.arc([x, 4 * S, x + 10 * S, H - 4 * S], 0, 360, fill=COLOR_STEEL, width=int(1.5 * S))
        draw.line([(x + 2 * S, cy - 3 * S), (x + 4 * S, cy + 3 * S)], fill=INK_DARK, width=S)
        draw.line([(x + 6 * S, cy + 3 * S), (x + 8 * S, cy - 3 * S)], fill=INK_DARK, width=S)

    save_image(img, output_path, target_size=(64, 20))


def generate_tree_ink_sketch(output_path: str) -> None:
    """Generates 80x80 hand-sketched Balkan pine / oak canopy viewed from above."""
    S = 4
    W, H = 80 * S, 80 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = W // 2, H // 2

    # 1. Soft ink drop shadow beneath canopy
    draw.ellipse([cx - 28 * S, cy - 24 * S, cx + 34 * S, cy + 34 * S], fill=(24, 20, 18, 80))

    # 2. Organic lobed foliage clusters
    clusters = [
        (cx, cy, 26 * S, (62, 88, 48, 255)),
        (cx - 10 * S, cy - 8 * S, 18 * S, (74, 102, 56, 255)),
        (cx + 12 * S, cy - 6 * S, 16 * S, (82, 110, 62, 255)),
        (cx - 8 * S, cy + 12 * S, 16 * S, (54, 78, 42, 255)),
        (cx + 10 * S, cy + 10 * S, 18 * S, (68, 94, 52, 255))
    ]
    for lx, ly, lr, c in clusters:
        draw.ellipse([lx - lr, ly - lr, lx + lr, ly + lr], fill=c, outline=INK_DARK, width=int(1.5 * S))
        img = draw_crosshatch(img, lx - lr * 0.7, ly - lr * 0.7, lx + lr * 0.7, ly + lr * 0.7,
                              spacing=4 * S, angle=random.choice([30, 60, 120]), color=INK_LIGHT, width=S)
        draw = ImageDraw.Draw(img)

    # 3. Central trunk peak / branch hints
    draw.ellipse([cx - 3 * S, cy - 3 * S, cx + 3 * S, cy + 3 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=S)
    for ba in [0.3, 1.8, 3.4, 4.9]:
        bx = cx + 12 * S * math.cos(ba)
        by = cy + 12 * S * math.sin(ba)
        draw.line([(cx, cy), (bx, by)], fill=INK_DARK, width=int(1.5 * S))

    save_image(img, output_path, target_size=(80, 80))


def generate_health_kit(output_path: str, large: bool = False) -> None:
    """Field dressing kit: olive satchel + white roundel + red cross. NOT a red box."""
    size = 40 if large else 32
    S = 4
    W, H = size * S, size * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pad = 4 * S
    # Olive canvas satchel with flap
    draw.rounded_rectangle([pad, pad + 2 * S, W - pad, H - pad], radius=3 * S,
                           fill=(96, 104, 74, 255), outline=INK_DARK, width=int(1.5 * S))
    draw.line([(pad, pad + 6 * S), (W - pad, pad + 6 * S)], fill=INK_MID, width=S)  # flap seam
    draw.line([(W // 2, pad + 2 * S), (W // 2, H - pad)], fill=INK_FAINT, width=S)   # strap shadow
    # White roundel + red cross
    r = 8 * S if large else 6 * S
    draw.ellipse([W // 2 - r, H // 2 - r, W // 2 + r, H // 2 + r], fill=(238, 236, 228, 255),
                 outline=INK_DARK, width=int(1.5 * S))
    cw = (r * 2) // 3
    ch = cw // 3
    draw.rectangle([W // 2 - cw // 2, H // 2 - r + ch, W // 2 + cw // 2, H // 2 + r - ch], fill=COLOR_CRO_RED)
    draw.rectangle([W // 2 - ch // 2, H // 2 - r + cw // 2 - ch // 2, W // 2 + ch // 2, H // 2 + r - cw // 2 + ch // 2], fill=COLOR_CRO_RED)
    if large:
        # Carry handle for the big kit
        draw.arc([W // 2 - 6 * S, pad - 3 * S, W // 2 + 6 * S, pad + 4 * S], 180, 360, fill=INK_DARK, width=int(1.5 * S))
    img = draw_crosshatch(img, pad + S, pad + 3 * S, W - pad - S, H - pad - S,
                          spacing=4 * S, angle=45, color=INK_FAINT, width=S)
    save_image(img, output_path, target_size=(size, size))


def generate_weapon_pickup(output_path: str) -> None:
    """Weapon crate: dark green box, rifle silhouette, gold glint corner."""
    S = 4
    W, H = 32 * S, 32 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([3 * S, 6 * S, 29 * S, 26 * S], radius=2 * S, fill=(54, 62, 44, 255),
                           outline=INK_DARK, width=int(1.5 * S))
    draw.line([(3 * S, 12 * S), (29 * S, 12 * S)], fill=INK_MID, width=S)
    # Rifle silhouette
    draw.rectangle([7 * S, 16 * S, 25 * S, 18 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
    draw.rectangle([9 * S, 18 * S, 13 * S, 21 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
    # Gold glint
    draw.line([(26 * S, 7 * S), (28 * S, 9 * S)], fill=(230, 200, 60, 255), width=S)
    draw.line([(28 * S, 7 * S), (26 * S, 9 * S)], fill=(230, 200, 60, 255), width=S)
    save_image(img, output_path, target_size=(32, 32))


def generate_bullet_tracer(output_path: str, enemy: bool = False) -> None:
    """Bright elongated tracer streak (player = warm white-gold, enemy = hot red)."""
    S = 4
    W, H = 16 * S, 6 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    core = (255, 244, 200, 255) if not enemy else (255, 120, 90, 255)
    glow = (255, 200, 80, 160) if not enemy else (220, 40, 30, 160)
    tail = (255, 170, 60, 90) if not enemy else (180, 30, 24, 90)
    cy = H // 2
    draw.line([(1 * S, cy), (9 * S, cy)], fill=tail, width=2 * S)
    draw.line([(4 * S, cy), (13 * S, cy)], fill=glow, width=int(2.5 * S))
    draw.line([(8 * S, cy), (15 * S, cy)], fill=core, width=int(1.5 * S))
    draw.ellipse([13 * S, cy - S, 15 * S, cy + S], fill=(255, 255, 240, 255))
    save_image(img, output_path, target_size=(16, 6))


def generate_rocket_sprite(output_path: str) -> None:
    """RPG rocket: olive body, dark warhead cone, fins, ink outline."""
    S = 4
    W, H = 24 * S, 8 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cy = H // 2
    draw.rectangle([6 * S, cy - 1 * S, 18 * S, cy + 1 * S], fill=(88, 92, 70, 255), outline=INK_DARK, width=1)
    draw.polygon([(18 * S, cy - 2 * S), (23 * S, cy), (18 * S, cy + 2 * S)], fill=COLOR_STEEL_DARK, outline=INK_DARK)
    draw.polygon([(6 * S, cy - 1 * S), (3 * S, cy - 2 * S), (5 * S, cy)], fill=(70, 74, 62, 255), outline=INK_DARK)
    draw.polygon([(6 * S, cy + 1 * S), (3 * S, cy + 2 * S), (5 * S, cy)], fill=(70, 74, 62, 255), outline=INK_DARK)
    save_image(img, output_path, target_size=(24, 8))


def generate_mortar_prop(output_path: str) -> None:
    """Top-down mortar pit: circular baseplate, angled tube, sand ring."""
    S = 4
    W, H = 48 * S, 48 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = W // 2, H // 2
    draw.ellipse([4 * S, 4 * S, W - 4 * S, H - 4 * S], fill=(96, 88, 66, 255), outline=INK_DARK, width=int(1.5 * S))
    draw.ellipse([10 * S, 10 * S, W - 10 * S, H - 10 * S], fill=(70, 64, 48, 255), outline=INK_DARK, width=S)
    draw.ellipse([cx - 8 * S, cy - 8 * S, cx + 8 * S, cy + 8 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)
    draw.rectangle([cx - 2 * S, cy - 16 * S, cx + 2 * S, cy], fill=(52, 56, 58, 255), outline=INK_DARK, width=S)
    draw.line([(cx - 6 * S, cy + 2 * S), (cx - 10 * S, cy + 8 * S)], fill=COLOR_STEEL_DARK, width=S)
    draw.line([(cx + 6 * S, cy + 2 * S), (cx + 10 * S, cy + 8 * S)], fill=COLOR_STEEL_DARK, width=S)
    img = draw_crosshatch(img, 8 * S, 8 * S, W - 8 * S, H - 8 * S, spacing=5 * S, angle=60, color=INK_FAINT, width=S)
    save_image(img, output_path, target_size=(48, 48))


def generate_mine(output_path: str) -> None:
    """20x20 anti-personnel mine: dark disc, pressure spider, barely visible."""
    S = 4
    W, H = 20 * S, 20 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = W // 2, H // 2
    draw.ellipse([3 * S, 3 * S, W - 3 * S, H - 3 * S], fill=(48, 44, 38, 255), outline=INK_DARK, width=S)
    draw.ellipse([cx - 4 * S, cy - 4 * S, cx + 4 * S, cy + 4 * S], fill=(70, 66, 56, 255), outline=INK_DARK, width=1)
    for a in range(0, 360, 60):
        ax = cx + int(6 * S * math.cos(math.radians(a)))
        ay = cy + int(6 * S * math.sin(math.radians(a)))
        draw.line([(cx, cy), (ax, ay)], fill=INK_MID, width=1)
    save_image(img, output_path, target_size=(20, 20))


def generate_minefield_sign(output_path: str) -> None:
    """48x48 minefield warning: two posts + red-bordered triangle with skull."""
    S = 4
    W, H = 48 * S, 48 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([10 * S, 18 * S, 13 * S, 42 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=S)
    draw.rectangle([35 * S, 18 * S, 38 * S, 42 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=S)
    pts = [(24 * S, 6 * S), (42 * S, 34 * S), (6 * S, 34 * S)]
    draw.polygon(pts, fill=(222, 214, 190, 255))
    draw.line(pts + [pts[0]], fill=COLOR_CRO_RED, width=3 * S)
    # Skull hint
    draw.ellipse([20 * S, 18 * S, 28 * S, 26 * S], fill=INK_DARK)
    draw.rectangle([21 * S, 25 * S, 27 * S, 29 * S], fill=INK_DARK)
    save_image(img, output_path, target_size=(48, 48))


def generate_grenade(output_path: str) -> None:
    """20x20 M75 hand grenade: oval frag body + lever."""
    S = 4
    W, H = 20 * S, 20 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([5 * S, 6 * S, 14 * S, 17 * S], fill=(56, 60, 46, 255), outline=INK_DARK, width=S)
    for i in range(3):
        y = (8 + i * 3) * S
        draw.line([(6 * S, y), (13 * S, y)], fill=INK_MID, width=1)
    for i in range(2):
        x = (8 + i * 3) * S
        draw.line([(x, 7 * S), (x, 16 * S)], fill=INK_MID, width=1)
    draw.arc([8 * S, 2 * S, 16 * S, 10 * S], -90, 90, fill=COLOR_STEEL_LIGHT, width=int(1.5 * S))
    draw.ellipse([7 * S, 4 * S, 10 * S, 7 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
    save_image(img, output_path, target_size=(20, 20))


def generate_warning_circle(output_path: str) -> None:
    """64x64 dashed red target telegraph circle with inner crosshair ticks."""
    S = 4
    W, H = 64 * S, 64 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r = 28 * S
    for a in range(0, 360, 12):
        a0, a1 = math.radians(a), math.radians(a + 7)
        x0, y0 = W // 2 + r * math.cos(a0), H // 2 + r * math.sin(a0)
        x1, y1 = W // 2 + r * math.cos(a1), H // 2 + r * math.sin(a1)
        draw.line([(x0, y0), (x1, y1)], fill=(200, 40, 30, 200), width=2 * S)
    draw.ellipse([W // 2 - 4 * S, H // 2 - 4 * S, W // 2 + 4 * S, H // 2 + 4 * S], outline=(200, 40, 30, 160), width=S)
    save_image(img, output_path, target_size=(64, 64))


def generate_armor_vest(output_path: str) -> None:
    """28x28 flak vest pickup: olive vest with plate panels and straps."""
    S = 4
    W, H = 28 * S, 28 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pts = [(8 * S, 4 * S), (20 * S, 4 * S), (24 * S, 10 * S), (22 * S, 24 * S), (6 * S, 24 * S), (4 * S, 10 * S)]
    draw.polygon(pts, fill=(78, 86, 62, 255))
    draw.line(pts + [pts[0]], fill=INK_DARK, width=int(1.5 * S))
    draw.rectangle([10 * S, 8 * S, 18 * S, 16 * S], fill=(62, 68, 50, 255), outline=INK_DARK, width=S)
    draw.line([(6 * S, 6 * S), (4 * S, 10 * S)], fill=INK_DARK, width=S)
    draw.line([(22 * S, 6 * S), (24 * S, 10 * S)], fill=INK_DARK, width=S)
    img = draw_crosshatch(img, 8 * S, 6 * S, 20 * S, 22 * S, spacing=3 * S, angle=45, color=INK_FAINT, width=S)
    save_image(img, output_path, target_size=(28, 28))


def generate_stone_wall(output_path: str) -> None:
    """64x28 crenellated fortress stone wall segment (Knin ramparts)."""
    S = 4
    W, H = 64 * S, 28 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 8 * S, W, 26 * S], fill=(132, 128, 118, 255), outline=INK_DARK, width=int(1.5 * S))
    # Battlements
    for bx in range(2 * S, W - 8 * S, 12 * S):
        draw.rectangle([bx, 2 * S, bx + 8 * S, 10 * S], fill=(120, 116, 106, 255), outline=INK_DARK, width=S)
    # Stone courses
    for row, y in enumerate(range(10 * S, 26 * S, 5 * S)):
        off = 4 * S if row % 2 else 0
        for x in range(-4 * S + off, W, 10 * S):
            shade = random.randint(-10, 10)
            draw.rectangle([x, y, x + 9 * S, y + 4 * S],
                           fill=(132 + shade, 128 + shade, 118 + shade, 255), outline=INK_MID, width=1)
    img = draw_crosshatch(img, 0, 8 * S, W, 26 * S, spacing=6 * S, angle=30, color=INK_FAINT, width=S)
    save_image(img, output_path, target_size=(64, 28))


def generate_building_walls(kind: str, output_path: str) -> None:
    """Front wall band (with door + windows) to sit under a roof sprite and give height."""
    w = 160 if kind == "tiles" else 140
    S = 4
    W, H = w * S, 28 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    plaster = (214, 200, 168, 255) if kind == "tiles" else (168, 160, 142, 255)
    draw.rectangle([4 * S, 0, (w - 4) * S, H - 4 * S], fill=plaster, outline=INK_DARK, width=int(1.5 * S))
    # Stone foundation
    draw.rectangle([4 * S, H - 8 * S, (w - 4) * S, H - 4 * S], fill=(120, 116, 106, 255), outline=INK_DARK, width=S)
    # Door (dark, arched top)
    dx = W // 2 - 6 * S
    draw.rectangle([dx, 8 * S, dx + 12 * S, H - 6 * S], fill=(44, 34, 24, 255), outline=INK_DARK, width=S)
    draw.arc([dx, 5 * S, dx + 12 * S, 11 * S], 180, 360, fill=INK_DARK, width=S)
    # Windows with shutters
    for wx in (W // 4 - 5 * S, 3 * W // 4 - 5 * S):
        draw.rectangle([wx, 8 * S, wx + 10 * S, 16 * S], fill=(30, 34, 38, 255), outline=INK_DARK, width=S)
        draw.line([(wx - 2 * S, 8 * S), (wx - 2 * S, 16 * S)], fill=COLOR_WOOD_DARK, width=2 * S)
        draw.line([(wx + 12 * S, 8 * S), (wx + 12 * S, 16 * S)], fill=COLOR_WOOD_DARK, width=2 * S)
    img = draw_crosshatch(img, 4 * S, 2 * S, (w - 4) * S, H - 6 * S, spacing=7 * S, angle=45, color=INK_FAINT, width=S)
    save_image(img, output_path, target_size=(w, 28))


def generate_hay_bale(output_path: str) -> None:
    """28x28 round hay bale top-down with spiral wrap."""
    S = 4
    W, H = 28 * S, 28 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = W // 2, H // 2
    draw.ellipse([cx - 12 * S, cy - 10 * S, cx + 14 * S, cy + 14 * S], fill=(24, 20, 16, 70))  # shadow
    draw.ellipse([cx - 11 * S, cy - 11 * S, cx + 11 * S, cy + 11 * S], fill=(196, 168, 92, 255), outline=INK_DARK, width=int(1.5 * S))
    for r in (8 * S, 5 * S, 2 * S):
        draw.arc([cx - r, cy - r, cx + r, cy + r], 0, 330, fill=(150, 124, 62, 255), width=S)
    img = draw_crosshatch(img, cx - 9 * S, cy - 9 * S, cx + 9 * S, cy + 9 * S, spacing=3 * S, angle=60, color=INK_FAINT, width=S)
    save_image(img, output_path, target_size=(28, 28))


def generate_wrecked_car(output_path: str) -> None:
    """56x28 burnt-out civilian car hulk, top-down."""
    S = 4
    W, H = 56 * S, 28 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([6 * S, 16 * S, 50 * S, 30 * S], fill=(20, 16, 14, 90))  # shadow
    draw.rounded_rectangle([4 * S, 6 * S, 52 * S, 24 * S], radius=5 * S, fill=(52, 48, 44, 255), outline=INK_DARK, width=int(1.5 * S))
    draw.rectangle([18 * S, 8 * S, 38 * S, 22 * S], fill=(30, 28, 26, 255), outline=INK_DARK, width=S)   # burnt cabin
    draw.line([(20 * S, 8 * S), (36 * S, 22 * S)], fill=(70, 64, 56, 255), width=S)                      # seat springs
    draw.line([(36 * S, 8 * S), (20 * S, 22 * S)], fill=(70, 64, 56, 255), width=S)
    for wx in (10 * S, 44 * S):
        draw.ellipse([wx - 3 * S, 4 * S, wx + 3 * S, 8 * S], fill=(24, 22, 20, 255), outline=INK_DARK, width=1)
        draw.ellipse([wx - 3 * S, 22 * S, wx + 3 * S, 26 * S], fill=(24, 22, 20, 255), outline=INK_DARK, width=1)
    # Rust blooms
    for _ in range(6):
        rx, ry = random.randint(6 * S, 50 * S), random.randint(7 * S, 23 * S)
        draw.ellipse([rx - 2 * S, ry - S, rx + 2 * S, ry + S], fill=(120, 66, 34, 120))
    save_image(img, output_path, target_size=(56, 28))


def generate_telegraph_pole(output_path: str) -> None:
    """16x32 telegraph pole top-down: wood post dot, crossarm, long shadow."""
    S = 4
    W, H = 16 * S, 32 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = W // 2
    draw.line([(cx + 4 * S, 8 * S), (cx + 12 * S, 26 * S)], fill=(24, 20, 16, 70), width=2 * S)  # shadow
    draw.line([(cx - 6 * S, 10 * S), (cx + 6 * S, 10 * S)], fill=COLOR_WOOD_DARK, width=int(1.5 * S))  # crossarm
    draw.ellipse([cx - 3 * S, 6 * S, cx + 3 * S, 12 * S], fill=COLOR_WOOD, outline=INK_DARK, width=S)
    draw.ellipse([cx - S, 8 * S, cx + S, 10 * S], fill=INK_DARK)
    save_image(img, output_path, target_size=(16, 32))


def generate_road_sign(output_path: str) -> None:
    """14x24 rural road sign: post + arrow board."""
    S = 4
    W, H = 14 * S, 24 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = W // 2
    draw.line([(cx + 3 * S, 6 * S), (cx + 7 * S, 20 * S)], fill=(24, 20, 16, 70), width=S)
    draw.rectangle([cx - S, 8 * S, cx + S, 22 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=1)
    pts = [(2 * S, 3 * S), (10 * S, 3 * S), (13 * S, 6 * S), (10 * S, 9 * S), (2 * S, 9 * S)]
    draw.polygon(pts, fill=(226, 218, 190, 255))
    draw.line(pts + [pts[0]], fill=INK_DARK, width=S)
    save_image(img, output_path, target_size=(14, 24))


def generate_grass_tuft(output_path: str) -> None:
    """16x16 grass tuft scatter detail."""
    S = 4
    W, H = 16 * S, 16 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = W // 2, H - 3 * S
    for i, (ang, ln, c) in enumerate([(-60, 9, (96, 116, 66)), (-30, 11, (110, 130, 76)), (0, 12, (88, 108, 60)),
                                      (30, 10, (120, 138, 84)), (60, 8, (96, 116, 66))]):
        a = math.radians(ang - 90)
        ex = cx + ln * S * math.cos(a) * 0.4 + (i - 2) * S
        ey = cy - ln * S * 0.9
        draw.line([(cx + (i - 2) * S, cy), (ex, ey)], fill=(*c, 255), width=int(1.2 * S))
    save_image(img, output_path, target_size=(16, 16))


def generate_stone_scatter(output_path: str) -> None:
    """20x16 pebble/scree scatter detail."""
    S = 4
    W, H = 20 * S, 16 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for _ in range(7):
        px, py = random.randint(2 * S, W - 4 * S), random.randint(2 * S, H - 4 * S)
        r = random.randint(S, 2 * S)
        shade = random.randint(-15, 15)
        draw.ellipse([px - r, py - r, px + r, py + r],
                     fill=(128 + shade, 122 + shade, 110 + shade, 255), outline=INK_MID, width=1)
    save_image(img, output_path, target_size=(20, 16))


# ---------------------------------------------------------------------------
# 4b. Held Weapon Sprites (for WeaponSprite nodes, drawn facing +X, grip left)
# ---------------------------------------------------------------------------

def _weapon_canvas(w: int, h: int) -> tuple:
    S = 4
    img = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img), S


def generate_held_weapon(kind: str, output_path: str) -> None:
    """Slim, dark, readable top-down weapon silhouettes. ~40x14 long guns, 16x10 pistol."""
    if kind == "php_pistol":
        img, draw, S = _weapon_canvas(16, 10)
        draw.rectangle([5 * S, 3 * S, 14 * S, 5 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)  # slide
        draw.rectangle([5 * S, 5 * S, 9 * S, 8 * S], fill=COLOR_STEEL, outline=INK_DARK, width=S)        # grip
        draw.rectangle([4 * S, 4 * S, 6 * S, 6 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=S)    # frame rear
        save_image(img, output_path, target_size=(16, 10))
        return

    img, draw, S = _weapon_canvas(40, 14)
    cy = 7 * S

    if kind == "m70_rifle":
        # Wooden stock + receiver, steel barrel, curved banana magazine
        draw.rectangle([2 * S, cy - 2 * S, 16 * S, cy + 2 * S], fill=COLOR_WOOD, outline=INK_DARK, width=S)
        draw.rectangle([16 * S, cy - 1 * S, 34 * S, cy + 1 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)
        draw.arc([10 * S, cy + 1 * S, 17 * S, cy + 8 * S], 0, 90, fill=INK_DARK, width=int(1.5 * S))  # magazine curve
        draw.rectangle([1 * S, cy - 1 * S, 4 * S, cy + 2 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=S)
    elif kind == "hawk_shotgun":
        # Thick ribbed barrel + wood pump grip
        draw.rectangle([8 * S, cy - 2 * S, 33 * S, cy + 2 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)
        draw.line([(8 * S, cy - 2 * S), (33 * S, cy - 2 * S)], fill=COLOR_STEEL_LIGHT, width=S)
        draw.rectangle([12 * S, cy + 2 * S, 20 * S, cy + 4 * S], fill=COLOR_WOOD, outline=INK_DARK, width=S)
        draw.rectangle([2 * S, cy - 2 * S, 10 * S, cy + 2 * S], fill=COLOR_WOOD, outline=INK_DARK, width=S)
    elif kind == "skorpion_smg":
        # Compact stamped body, folding wire stock, small mag
        draw.rectangle([6 * S, cy - 2 * S, 24 * S, cy + 2 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)
        draw.rectangle([24 * S, cy - 1 * S, 30 * S, cy + 1 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)
        draw.line([(6 * S, cy - 3 * S), (2 * S, cy - 4 * S)], fill=COLOR_STEEL, width=S)  # wire stock
        draw.line([(6 * S, cy + 3 * S), (2 * S, cy + 4 * S)], fill=COLOR_STEEL, width=S)
        draw.rectangle([12 * S, cy + 2 * S, 15 * S, cy + 7 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)
    elif kind == "m48_mauser":
        # Long slim bolt-action: full wood stock, slim barrel, bolt knob
        draw.rectangle([2 * S, cy - 1 * S, 20 * S, cy + 1 * S], fill=COLOR_WOOD, outline=INK_DARK, width=S)
        draw.rectangle([20 * S, cy - 1 * S, 37 * S, cy], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
        draw.ellipse([8 * S, cy + 1 * S, 11 * S, cy + 4 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)  # bolt
        draw.rectangle([1 * S, cy - 1 * S, 3 * S, cy + 1 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=1)
    elif kind == "rpg7":
        # Tube + conical warhead + pistol grips
        draw.rectangle([6 * S, cy - 1 * S, 30 * S, cy + 1 * S], fill=(70, 74, 62, 255), outline=INK_DARK, width=S)
        draw.polygon([(30 * S, cy - 3 * S), (37 * S, cy), (30 * S, cy + 3 * S)], fill=COLOR_STEEL_DARK, outline=INK_DARK)
        draw.rectangle([12 * S, cy + 1 * S, 14 * S, cy + 4 * S], fill=COLOR_WOOD_DARK, outline=INK_DARK, width=1)
        draw.rectangle([4 * S, cy - 2 * S, 6 * S, cy + 2 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)  # venturi
    elif kind == "m72_rpk":
        # RPK: rifle silhouette + drum magazine + bipod hint + carrying handle
        draw.rectangle([2 * S, cy - 2 * S, 16 * S, cy + 2 * S], fill=COLOR_WOOD, outline=INK_DARK, width=S)
        draw.rectangle([16 * S, cy - 1 * S, 35 * S, cy + 1 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)
        draw.ellipse([10 * S, cy + 1 * S, 18 * S, cy + 8 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=S)  # drum
        draw.line([(30 * S, cy + 1 * S), (33 * S, cy + 5 * S)], fill=COLOR_STEEL, width=S)  # bipod leg
        draw.line([(30 * S, cy - 1 * S), (33 * S, cy - 5 * S)], fill=COLOR_STEEL, width=S)
    elif kind == "m76_dmr":
        # DMR: long barrel, scope bump, slim wood
        draw.rectangle([2 * S, cy - 1 * S, 18 * S, cy + 1 * S], fill=COLOR_WOOD, outline=INK_DARK, width=S)
        draw.rectangle([18 * S, cy - 1 * S, 38 * S, cy], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
        draw.rectangle([12 * S, cy - 4 * S, 20 * S, cy - 2 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)  # scope
        draw.rectangle([9 * S, cy + 1 * S, 13 * S, cy + 5 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)   # mag
    elif kind == "m80_zolja":
        # Disposable tube launcher: plain green tube, rear cone, sight nub
        draw.rectangle([4 * S, cy - 2 * S, 34 * S, cy + 2 * S], fill=(84, 92, 66, 255), outline=INK_DARK, width=S)
        draw.polygon([(34 * S, cy - 2 * S), (38 * S, cy), (34 * S, cy + 2 * S)], fill=(64, 70, 50, 255), outline=INK_DARK)
        draw.rectangle([2 * S, cy - 1 * S, 4 * S, cy + 1 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
        draw.rectangle([26 * S, cy - 4 * S, 29 * S, cy - 2 * S], fill=COLOR_STEEL_DARK, outline=INK_DARK, width=1)
    else:
        raise ValueError(f"Unknown held weapon kind: {kind}")

    save_image(img, output_path, target_size=(40, 14))


# ---------------------------------------------------------------------------
# 5. Combat VFX Generator
# ---------------------------------------------------------------------------

def generate_muzzle_flash_m70(output_path: str) -> None:
    """Generates 32x32 M70 rifle starburst muzzle flash."""
    S = 4
    W, H = 32 * S, 32 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = 8 * S, 16 * S

    spikes = [
        [(cx, cy - 2 * S), (cx + 22 * S, cy), (cx, cy + 2 * S)],
        [(cx, cy - 2 * S), (cx + 14 * S, cy - 10 * S), (cx + 4 * S, cy)],
        [(cx, cy + 2 * S), (cx + 14 * S, cy + 10 * S), (cx + 4 * S, cy)],
        [(cx - 2 * S, cy - 6 * S), (cx, cy), (cx - 2 * S, cy + 6 * S)]
    ]
    for sp in spikes:
        draw.polygon(sp, fill=COLOR_FIRE_ORANGE)

    core_pts = [(cx, cy - S), (cx + 15 * S, cy), (cx, cy + S)]
    draw.polygon(core_pts, fill=COLOR_FIRE_YELLOW)
    draw.ellipse([cx - 2 * S, cy - 3 * S, cx + 6 * S, cy + 3 * S], fill=COLOR_FIRE_WHITE)

    # Ink smoke streaks on overlay
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    draw_ov.line([(cx + 10 * S, cy - 6 * S), (cx + 20 * S, cy - 10 * S)], fill=INK_LIGHT, width=S)
    draw_ov.line([(cx + 10 * S, cy + 6 * S), (cx + 20 * S, cy + 10 * S)], fill=INK_LIGHT, width=S)
    img = Image.alpha_composite(img, overlay)

    save_image(img, output_path, target_size=(32, 32))


def generate_muzzle_flash_shotgun(output_path: str) -> None:
    """Generates 48x32 wide conical shotgun muzzle flash."""
    S = 4
    W, H = 48 * S, 32 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = 6 * S, 16 * S

    cone_pts = [(cx, cy - 2 * S), (cx + 38 * S, cy - 14 * S),
                (cx + 34 * S, cy), (cx + 38 * S, cy + 14 * S), (cx, cy + 2 * S)]
    draw.polygon(cone_pts, fill=COLOR_FIRE_ORANGE)

    inner_cone = [(cx, cy - S), (cx + 24 * S, cy - 8 * S),
                  (cx + 22 * S, cy), (cx + 24 * S, cy + 8 * S), (cx, cy + S)]
    draw.polygon(inner_cone, fill=COLOR_FIRE_YELLOW)
    draw.ellipse([cx - 2 * S, cy - 4 * S, cx + 8 * S, cy + 4 * S], fill=COLOR_FIRE_WHITE)

    for _ in range(12):
        sx = cx + random.uniform(16, 40) * S
        sy = cy + random.uniform(-12, 12) * S
        draw.ellipse([sx - S, sy - S, sx + S, sy + S], fill=COLOR_FIRE_YELLOW)

    save_image(img, output_path, target_size=(48, 32))


def generate_explosion_charcoal(output_path: str) -> None:
    """Generates 64x64 billowing charcoal smoke explosion fireball."""
    S = 4
    W, H = 64 * S, 64 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = W // 2, H // 2

    num_lobes = 10
    for i in range(num_lobes):
        ang = i * (2 * math.pi / num_lobes)
        dist = random.uniform(14, 24) * S
        lx = cx + dist * math.cos(ang)
        ly = cy + dist * math.sin(ang)
        lr = random.uniform(10, 16) * S
        draw.ellipse([lx - lr, ly - lr, lx + lr, ly + lr],
                     fill=(38, 34, 30, 240), outline=INK_DARK, width=int(1.5 * S))
        img = draw_crosshatch(img, lx - lr * 0.6, ly - lr * 0.6, lx + lr * 0.6, ly + lr * 0.6,
                              spacing=3 * S, angle=45, color=INK_MID, width=S)
        draw = ImageDraw.Draw(img)

    draw.ellipse([cx - 16 * S, cy - 16 * S, cx + 16 * S, cy + 16 * S], fill=COLOR_FIRE_ORANGE)
    draw.ellipse([cx - 10 * S, cy - 10 * S, cx + 10 * S, cy + 10 * S], fill=COLOR_FIRE_YELLOW)
    draw.ellipse([cx - 5 * S, cy - 5 * S, cx + 5 * S, cy + 5 * S], fill=COLOR_FIRE_WHITE)

    for _ in range(10):
        ang = random.uniform(0, 2 * math.pi)
        dist = random.uniform(22, 30) * S
        draw.line([(cx, cy), (cx + dist * math.cos(ang), cy + dist * math.sin(ang))], fill=COLOR_FIRE_YELLOW, width=S)

    save_image(img, output_path, target_size=(64, 64))


def generate_shell_casing_rifle(output_path: str) -> None:
    """Generates 8x4 7.62mm brass rifle cartridge casing."""
    S = 8
    W, H = 8 * S, 4 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.rectangle([S, S, 7 * S, 3 * S], fill=(215, 175, 45, 255), outline=INK_DARK, width=S)
    draw.line([(2 * S, S), (2 * S, 3 * S)], fill=INK_DARK, width=S)
    draw.rectangle([6 * S, S, 7 * S, 3 * S], fill=(40, 35, 25, 255))

    save_image(img, output_path, target_size=(8, 4))


def generate_shell_casing_shotgun(output_path: str) -> None:
    """Generates 8x6 12-gauge red shotgun hull with brass head."""
    S = 8
    W, H = 8 * S, 6 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.rectangle([S, S, 7 * S, 5 * S], fill=(195, 38, 28, 255), outline=INK_DARK, width=S)
    draw.rectangle([S, S, 3 * S, 5 * S], fill=(215, 175, 45, 255), outline=INK_DARK, width=S)

    save_image(img, output_path, target_size=(8, 6))


def generate_blood_splatter_decals(output_path: str) -> None:
    """Generates 64x64 hand-inked arterial blood splatter decal with pooling and droplets."""
    S = 4
    W, H = 64 * S, 64 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = W // 2, H // 2

    pool_pts = []
    num_pts = 14
    for i in range(num_pts):
        ang = i * (2 * math.pi / num_pts)
        r = (8 + random.uniform(-3, 6)) * S
        pool_pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    draw.polygon(pool_pts, fill=COLOR_BLOOD)
    draw.polygon(pool_pts, outline=COLOR_BLOOD_DARK, width=int(1.5 * S))

    for _ in range(16):
        ang = random.uniform(0, 2 * math.pi)
        dist = random.uniform(12, 28) * S
        dr = random.uniform(1, 3) * S
        sx = cx + dist * math.cos(ang)
        sy = cy + dist * math.sin(ang)
        draw.ellipse([sx - dr, sy - dr, sx + dr, sy + dr], fill=COLOR_BLOOD_FRESH)
        if random.random() > 0.5:
            draw.line([(cx, cy), (sx, sy)], fill=COLOR_BLOOD, width=S)

    save_image(img, output_path, target_size=(64, 64))


def generate_scorch_mark(output_path: str) -> None:
    """Generates 64x64 explosion blast crater scorch mark with soot & fractures."""
    S = 4
    W, H = 64 * S, 64 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = W // 2, H // 2

    for r in range(24 * S, 4 * S, -4 * S):
        alpha = int(220 * (1.0 - (r / (24.0 * S))))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(22, 20, 18, alpha))

    for _ in range(8):
        ang = random.uniform(0, 2 * math.pi)
        pts = [(cx, cy)]
        cur_x, cur_y = cx, cy
        for step in range(4):
            cur_x += random.uniform(4, 8) * S * math.cos(ang + random.uniform(-0.3, 0.3))
            cur_y += random.uniform(4, 8) * S * math.sin(ang + random.uniform(-0.3, 0.3))
            pts.append((cur_x, cur_y))
        draw.line(pts, fill=INK_DARK, width=int(1.5 * S))

    save_image(img, output_path, target_size=(64, 64))


# ---------------------------------------------------------------------------
# 6. Hand-Drawn UI Generator
# ---------------------------------------------------------------------------

def generate_paper_parchment_bg(output_path: str) -> None:
    """Generates 512x512 authentic vintage military field map parchment texture with 100% opacity."""
    img = Image.new("RGBA", (512, 512), (234, 224, 202, 255))

    # Translucent washes and marks drawn on overlay
    overlay = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)

    # 1. Fiber noise and watercolor tea-stains
    for _ in range(30):
        px = random.randint(0, 512)
        py = random.randint(0, 512)
        pr = random.randint(40, 120)
        draw_ov.ellipse([px - pr, py - pr, px + pr, py + pr], fill=(215, 200, 172, 35))

    # Coffee ring watermarks
    for cx, cy in [(140, 160), (380, 360)]:
        draw_ov.ellipse([cx - 45, cy - 45, cx + 45, cy + 45], outline=(175, 150, 120, 60), width=3)

    # Fold creases
    draw_ov.line([(0, 256), (512, 256)], fill=(185, 170, 145, 90), width=1)
    draw_ov.line([(256, 0), (256, 512)], fill=(185, 170, 145, 90), width=1)

    # 2. Pencil border margin lines & tactical coordinate tick marks
    draw_ov.rectangle([16, 16, 496, 496], outline=(110, 100, 85, 160), width=1)
    draw_ov.rectangle([20, 20, 492, 492], outline=(110, 100, 85, 100), width=1)
    for t in range(32, 480, 32):
        draw_ov.line([(t, 16), (t, 22)], fill=(110, 100, 85, 180), width=1)
        draw_ov.line([(t, 490), (t, 496)], fill=(110, 100, 85, 180), width=1)
        draw_ov.line([(16, t), (22, t)], fill=(110, 100, 85, 180), width=1)
        draw_ov.line([(490, t), (496, t)], fill=(110, 100, 85, 180), width=1)

    img = Image.alpha_composite(img, overlay)
    img.putalpha(255)  # Enforce 100% solid opacity
    save_image(img, output_path, target_size=(512, 512))


def generate_hud_health_frame(output_path: str) -> None:
    """Generates 220x32 tactical military HUD health bar container frame."""
    S = 4
    W, H = 220 * S, 32 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.rounded_rectangle([2 * S, 2 * S, W - 2 * S, H - 2 * S], radius=4 * S,
                           fill=(235, 226, 205, 240), outline=INK_DARK, width=2 * S)
    draw.rounded_rectangle([4 * S, 4 * S, W - 4 * S, H - 4 * S], radius=3 * S,
                           outline=INK_MID, width=S)

    mcx, mcy = 16 * S, 16 * S
    cw, cl = 3 * S, 9 * S
    draw.rectangle([mcx - cl, mcy - cw, mcx + cl, mcy + cw], fill=COLOR_CRO_RED, outline=INK_DARK, width=S)
    draw.rectangle([mcx - cw, mcy - cl, mcx + cw, mcy + cl], fill=COLOR_CRO_RED, outline=INK_DARK, width=S)

    # Health bar cutout slot
    draw.rectangle([30 * S, 6 * S, 212 * S, 26 * S], fill=(45, 40, 35, 60), outline=INK_DARK, width=int(1.5 * S))

    for tx in range(30 * S, 212 * S, 18 * S):
        draw.line([(tx, 6 * S), (tx, 10 * S)], fill=INK_MID, width=S)
        draw.line([(tx, 22 * S), (tx, 26 * S)], fill=INK_MID, width=S)

    for cx, cy in [(4 * S, 4 * S), (W - 5 * S, 4 * S), (4 * S, H - 5 * S), (W - 5 * S, H - 5 * S)]:
        draw.ellipse([cx, cy, cx + 2 * S, cy + 2 * S], fill=COLOR_STEEL_DARK)

    save_image(img, output_path, target_size=(220, 32))


def generate_hud_ammo_frame(output_path: str) -> None:
    """Generates 180x44 military ammo counter gauge frame."""
    S = 4
    W, H = 180 * S, 44 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.rounded_rectangle([2 * S, 2 * S, W - 2 * S, H - 2 * S], radius=4 * S,
                           fill=(230, 220, 198, 240), outline=INK_DARK, width=2 * S)
    draw.rounded_rectangle([5 * S, 5 * S, W - 5 * S, H - 5 * S], radius=3 * S,
                           outline=INK_LIGHT, width=S)

    draw.rectangle([14 * S, 14 * S, 24 * S, 30 * S], fill=(210, 175, 45, 255), outline=INK_DARK, width=S)
    draw.polygon([(14 * S, 14 * S), (19 * S, 8 * S), (24 * S, 14 * S)], fill=COLOR_STEEL_LIGHT, outline=INK_DARK)

    draw.rectangle([36 * S, 8 * S, 172 * S, 36 * S], fill=(42, 38, 32, 60), outline=INK_DARK, width=int(1.5 * S))

    for rx, ry in [(5 * S, 5 * S), (W - 6 * S, 5 * S), (5 * S, H - 6 * S), (W - 6 * S, H - 6 * S)]:
        draw.ellipse([rx, ry, rx + 2 * S, ry + 2 * S], fill=COLOR_STEEL_DARK)

    save_image(img, output_path, target_size=(180, 44))


def generate_minimap_compass(output_path: str) -> None:
    """Generates 48x48 vintage military compass rose."""
    S = 4
    W, H = 48 * S, 48 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = W // 2, H // 2
    r_outer = 21 * S

    draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer],
                 outline=INK_DARK, width=int(1.5 * S))

    for deg in range(0, 360, 30):
        rad = math.radians(deg)
        x0 = cx + (r_outer - 3 * S) * math.cos(rad)
        y0 = cy + (r_outer - 3 * S) * math.sin(rad)
        x1 = cx + r_outer * math.cos(rad)
        y1 = cy + r_outer * math.sin(rad)
        draw.line([(x0, y0), (x1, y1)], fill=INK_DARK, width=S)

    # 8-Point Compass Star
    draw.polygon([(cx, cy - 18 * S), (cx - 4 * S, cy), (cx, cy)], fill=COLOR_CRO_RED, outline=INK_DARK)
    draw.polygon([(cx, cy - 18 * S), (cx + 4 * S, cy), (cx, cy)], fill=INK_DARK, outline=INK_DARK)
    draw.polygon([(cx, cy + 18 * S), (cx - 4 * S, cy), (cx, cy)], fill=INK_MID, outline=INK_DARK)
    draw.polygon([(cx, cy + 18 * S), (cx + 4 * S, cy), (cx, cy)], fill=(220, 220, 210, 255), outline=INK_DARK)
    draw.polygon([(cx + 18 * S, cy), (cx, cy - 4 * S), (cx, cy)], fill=INK_DARK, outline=INK_DARK)
    draw.polygon([(cx + 18 * S, cy), (cx, cy + 4 * S), (cx, cy)], fill=(220, 220, 210, 255), outline=INK_DARK)
    draw.polygon([(cx - 18 * S, cy), (cx, cy - 4 * S), (cx, cy)], fill=INK_MID, outline=INK_DARK)
    draw.polygon([(cx - 18 * S, cy), (cx, cy + 4 * S), (cx, cy)], fill=(220, 220, 210, 255), outline=INK_DARK)

    draw.ellipse([cx - 3 * S, cy - 3 * S, cx + 3 * S, cy + 3 * S], fill=(220, 190, 50, 255), outline=INK_DARK, width=S)

    draw.line([(cx - 2 * S, cy - 20 * S), (cx - 2 * S, cy - 15 * S)], fill=COLOR_CRO_RED, width=int(1.5 * S))
    draw.line([(cx - 2 * S, cy - 20 * S), (cx + 2 * S, cy - 15 * S)], fill=COLOR_CRO_RED, width=int(1.5 * S))
    draw.line([(cx + 2 * S, cy - 20 * S), (cx + 2 * S, cy - 15 * S)], fill=COLOR_CRO_RED, width=int(1.5 * S))

    save_image(img, output_path, target_size=(48, 48))


def generate_stamp_mission_complete(output_path: str) -> None:
    """Generates 160x64 authentic red rubber ink stamp ('ZADAĆA IZVRŠENA')."""
    S = 4
    W, H = 160 * S, 64 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    stamp_color = (185, 34, 28, 220)

    draw.rounded_rectangle([4 * S, 4 * S, W - 4 * S, H - 4 * S], radius=6 * S,
                           outline=stamp_color, width=3 * S)
    draw.rounded_rectangle([8 * S, 8 * S, W - 8 * S, H - 8 * S], radius=4 * S,
                           outline=stamp_color, width=int(1.5 * S))

    try:
        font_large = ImageFont.load_default(size=14 * S)
        font_small = ImageFont.load_default(size=9 * S)
    except Exception:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()

    text1 = "★ ZADAĆA IZVRŠENA ★"
    text2 = "OPERATION STORM 1995"

    bbox1 = draw.textbbox((0, 0), text1, font=font_large)
    bbox2 = draw.textbbox((0, 0), text2, font=font_small)

    w1, h1 = bbox1[2] - bbox1[0], bbox1[3] - bbox1[1]
    w2, h2 = bbox2[2] - bbox2[0], bbox2[3] - bbox2[1]

    draw.text(((W - w1) // 2, 14 * S), text1, fill=stamp_color, font=font_large)
    draw.text(((W - w2) // 2, 36 * S), text2, fill=stamp_color, font=font_small)

    for _ in range(300):
        vx = random.randint(4 * S, W - 4 * S)
        vy = random.randint(4 * S, H - 4 * S)
        draw.point((vx, vy), fill=(0, 0, 0, 0))

    save_image(img, output_path, target_size=(160, 64))


def _draw_cloth_shading(img: Image.Image) -> Image.Image:
    """Soft vertical cloth-wave shading so flags read as fabric, not flat plastic."""
    W, H = img.size
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    for x in range(0, W, 8):
        wave = int(3 * math.sin(x * 0.08))
        draw_ov.line([(x, 0), (x + wave, H)], fill=(255, 255, 255, 14), width=3)
        draw_ov.line([(x + 4, 0), (x + 4 + wave, H)], fill=(20, 16, 12, 10), width=2)
    return Image.alpha_composite(img, overlay)


def _shield_polygon(cx: int, top: int, w: int, h: int) -> list:
    """Heater-shield outline: flat top, straight sides, pointed base."""
    x0, x1 = cx - w // 2, cx + w // 2
    return [(x0, top), (x1, top), (x1, top + int(h * 0.55)), (cx, top + h), (x0, top + int(h * 0.55))]


def _draw_sahovnica_shield(img: Image.Image, cx: int, top: int, w: int, h: int,
                           cell_border: int, crown: bool = True) -> Image.Image:
    """Draws the Croatian coat of arms: blue shield, 5x5 šahovnica starting RED, 5-shield crown."""
    draw = ImageDraw.Draw(img)
    shield_pts = _shield_polygon(cx, top, w, h)

    # Crown of five small historical shields in an arc above the main shield
    if crown:
        cw = max(2, w // 7)
        ch = max(2, h // 5)
        gap = max(1, w // 24)
        total = 5 * cw + 4 * gap
        cx0 = cx - total // 2
        crown_colors = [
            ((46, 94, 171, 255), (255, 255, 255, 255)),   # star & crescent blue
            ((240, 240, 235, 255), (196, 34, 28, 255)),   # white w/ red bars
            ((196, 34, 28, 255), (240, 240, 235, 255)),   # red w/ white dot
            ((46, 94, 171, 255), (240, 240, 235, 255)),   # blue w/ white stripe
            ((196, 34, 28, 255), (255, 210, 50, 255)),    # red w/ gold dot
        ]
        for i, (base, mark) in enumerate(crown_colors):
            mx0 = cx0 + i * (cw + gap)
            my0 = top - ch + abs(i - 2) * max(1, ch // 4)
            pts = _shield_polygon(mx0 + cw // 2, my0, cw, ch)
            draw.polygon(pts, fill=base, outline=INK_DARK)
            draw.point((mx0 + cw // 2, my0 + ch // 3), fill=mark)

    # Blue shield field
    draw.polygon(shield_pts, fill=(28, 64, 142, 255))

    # 5x5 checkerboard masked to the shield silhouette, starting RED top-left
    checker = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw_ck = ImageDraw.Draw(checker)
    inset = cell_border
    cw = (w - 2 * inset) // 5
    chh = (int(h * 0.62) - inset) // 5
    x0, y0 = cx - w // 2 + inset, top + inset
    for row in range(5):
        for col in range(5):
            c = COLOR_CRO_RED if (row + col) % 2 == 0 else COLOR_CRO_WHITE
            draw_ck.rectangle([x0 + col * cw, y0 + row * chh,
                               x0 + (col + 1) * cw, y0 + (row + 1) * chh], fill=c)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(shield_pts, fill=255)
    checker.putalpha(ImageChops.multiply(checker.getchannel("A"), mask))
    img = Image.alpha_composite(img, checker)
    draw = ImageDraw.Draw(img)

    draw.line(shield_pts + [shield_pts[0]], fill=INK_DARK, width=max(1, w // 22))
    return img


def generate_croatian_flag(output_path: str) -> None:
    """Croatian flag, official 1:2 ratio: red/white/blue thirds + crowned šahovnica shield."""
    S = 4
    W, H = 96 * S, 48 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    band = H // 3
    draw.rectangle([0, 0, W, band], fill=COLOR_CRO_RED)
    draw.rectangle([0, band, W, band * 2], fill=COLOR_CRO_WHITE)
    draw.rectangle([0, band * 2, W, H], fill=COLOR_CRO_BLUE)
    img = _draw_cloth_shading(img)
    img = _draw_sahovnica_shield(img, W // 2, 11 * S, 22 * S, 26 * S, cell_border=2 * S)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, W - 1, H - 1], outline=INK_DARK, width=S)
    save_image(img, output_path, target_size=(96, 48))


def generate_svk_flag(output_path: str) -> None:
    """Serbian / SVK horizontal tricolor, red-blue-white equal thirds, 2:1 cloth."""
    S = 4
    W, H = 96 * S, 48 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    band = H // 3
    draw.rectangle([0, 0, W, band], fill=COLOR_SVK_RED)
    draw.rectangle([0, band, W, band * 2], fill=COLOR_SVK_BLUE)
    draw.rectangle([0, band * 2, W, H], fill=COLOR_SVK_WHITE)
    img = _draw_cloth_shading(img)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, W - 1, H - 1], outline=INK_DARK, width=S)
    save_image(img, output_path, target_size=(96, 48))


def generate_svk_insignia(output_path: str) -> None:
    """Generates a simple SAO Krajina / SVK shield insignia."""
    S = 4
    W, H = 32 * S, 32 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = W // 2, H // 2
    # Shield outline
    pts = [(cx, 4 * S), (W - 4 * S, 10 * S), (W - 6 * S, H - 6 * S), (cx, H - 3 * S), (6 * S, H - 6 * S), (4 * S, 10 * S)]
    draw.polygon(pts, fill=(36, 40, 34, 255), outline=INK_DARK)
    # Tricolor bands inside shield
    draw.rectangle([cx - 6 * S, cy - 6 * S, cx + 6 * S, cy - 2 * S], fill=COLOR_SVK_RED)
    draw.rectangle([cx - 6 * S, cy - 2 * S, cx + 6 * S, cy + 2 * S], fill=COLOR_SVK_BLUE)
    draw.rectangle([cx - 6 * S, cy + 2 * S, cx + 6 * S, cy + 6 * S], fill=COLOR_SVK_WHITE)
    draw.rectangle([cx - 6 * S, cy - 6 * S, cx + 6 * S, cy + 6 * S], outline=INK_DARK, width=S)
    save_image(img, output_path, target_size=(32, 32))


def generate_hv_insignia(output_path: str) -> None:
    """HV insignia badge: proper pointed šahovnica shield with crown on a dark roundel."""
    S = 4
    W, H = 32 * S, 32 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = W // 2, H // 2
    draw.ellipse([3 * S, 3 * S, W - 3 * S, H - 3 * S], fill=(36, 40, 34, 255), outline=INK_DARK, width=S)
    img = _draw_sahovnica_shield(img, cx, 9 * S, 16 * S, 17 * S, cell_border=1 * S)
    draw = ImageDraw.Draw(img)
    draw.ellipse([3 * S, 3 * S, W - 3 * S, H - 3 * S], outline=(212, 176, 90, 255), width=S)
    save_image(img, output_path, target_size=(32, 32))


# ---------------------------------------------------------------------------
# Main Generation Pipeline
# ---------------------------------------------------------------------------

def generate_all_assets() -> None:
    """Generates all War-Journal assets including faction flags/insignia."""
    print("=== Generating War-Journal High-Definition Asset Library ===")

    # 1. Characters (10 assets)
    print("\n--- 1. Characters ---")
    generate_torso("player", "assets/sprites/characters/player_torso.png")
    generate_torso("rifleman", "assets/sprites/characters/enemy_rifleman_torso.png")
    generate_torso("shotgunner", "assets/sprites/characters/enemy_shotgunner_torso.png")
    generate_torso("mg", "assets/sprites/characters/enemy_mg_torso.png")
    generate_torso("sniper", "assets/sprites/characters/enemy_sniper_torso.png")
    generate_torso("officer", "assets/sprites/characters/enemy_officer_torso.png")
    generate_torso("grenadier", "assets/sprites/characters/enemy_grenadier_torso.png")
    generate_soldier_legs("assets/sprites/characters/soldier_legs_sheet.png")
    generate_soldier_shadow("assets/sprites/characters/soldier_shadow.png")
    generate_casualty_decals("assets/sprites/characters/casualty_decals.png")

    # 2. Vehicles (6 assets)
    print("\n--- 2. Armored Vehicles ---")
    generate_apc_hull("assets/sprites/vehicles/apc_hull.png")
    generate_apc_turret("assets/sprites/vehicles/apc_turret.png")
    generate_apc_wreck("assets/sprites/vehicles/apc_wreck.png")
    generate_tank_hull("assets/sprites/vehicles/tank_hull.png")
    generate_tank_turret("assets/sprites/vehicles/tank_turret.png")
    generate_tank_wreck("assets/sprites/vehicles/tank_wreck.png")

    # 3. Terrain (5 assets)
    print("\n--- 3. Terrain Maps ---")
    generate_terrain_staging("assets/sprites/terrain/terrain_staging.png")
    generate_terrain_trenches("assets/sprites/terrain/terrain_trenches.png")
    generate_terrain_highway("assets/sprites/terrain/terrain_highway.png")
    generate_terrain_urban("assets/sprites/terrain/terrain_urban.png")
    generate_terrain_fortress("assets/sprites/terrain/terrain_fortress.png")

    # 4. Props (18 assets)
    print("\n--- 4. Illustrated Props ---")
    generate_building_roof_tiles("assets/sprites/props/building_roof_tiles.png")
    generate_building_roof_tin("assets/sprites/props/building_roof_tin.png")
    generate_building_walls("tiles", "assets/sprites/props/building_walls_tiles.png")
    generate_building_walls("tin", "assets/sprites/props/building_walls_tin.png")
    generate_bunker_concrete("assets/sprites/props/bunker_concrete.png")
    generate_sandbag_straight("assets/sprites/props/sandbag_straight.png")
    generate_sandbag_corner("assets/sprites/props/sandbag_corner.png")
    generate_ammo_crate_wooden("assets/sprites/props/ammo_crate_wooden.png")
    generate_fuel_drum("assets/sprites/props/fuel_drum.png")
    generate_barbed_wire("assets/sprites/props/barbed_wire.png")
    generate_tree_ink_sketch("assets/sprites/props/tree_ink_sketch.png")
    generate_stone_wall("assets/sprites/props/stone_wall.png")
    generate_hay_bale("assets/sprites/props/hay_bale.png")
    generate_wrecked_car("assets/sprites/props/wrecked_car.png")
    generate_telegraph_pole("assets/sprites/props/telegraph_pole.png")
    generate_road_sign("assets/sprites/props/road_sign.png")
    generate_grass_tuft("assets/sprites/props/grass_tuft.png")
    generate_stone_scatter("assets/sprites/props/stone_scatter.png")

    # 4c. Held weapon sprites (9 assets)
    print("\n--- 4c. Held Weapon Sprites ---")
    generate_held_weapon("m70_rifle", "assets/sprites/weapons/m70_rifle.png")
    generate_held_weapon("php_pistol", "assets/sprites/weapons/php_pistol.png")
    generate_held_weapon("hawk_shotgun", "assets/sprites/weapons/hawk_shotgun.png")
    generate_held_weapon("skorpion_smg", "assets/sprites/weapons/skorpion_smg.png")
    generate_held_weapon("m48_mauser", "assets/sprites/weapons/m48_mauser.png")
    generate_held_weapon("rpg7", "assets/sprites/weapons/rpg7.png")
    generate_held_weapon("m72_rpk", "assets/sprites/weapons/m72_rpk.png")
    generate_held_weapon("m76_dmr", "assets/sprites/weapons/m76_dmr.png")
    generate_held_weapon("m80_zolja", "assets/sprites/weapons/m80_zolja.png")

    # 4d. Pickups & legacy sprite restyles (war-journal style)
    print("\n--- 4d. Pickups & Legacy Restyles ---")
    generate_health_kit("assets/sprites/health_kit.png")
    generate_health_kit("assets/sprites/large_health.png", large=True)
    generate_ammo_crate_wooden("assets/sprites/ammo_crate.png")
    generate_weapon_pickup("assets/sprites/weapon_pickup.png")
    generate_bullet_tracer("assets/sprites/bullet.png")
    generate_bullet_tracer("assets/sprites/bullet_enemy.png", enemy=True)
    generate_rocket_sprite("assets/sprites/rocket.png")
    generate_mortar_prop("assets/sprites/mortar.png")
    generate_mine("assets/sprites/mine.png")
    generate_minefield_sign("assets/sprites/minefield.png")
    generate_grenade("assets/sprites/grenade.png")
    generate_warning_circle("assets/sprites/warning_circle.png")
    generate_armor_vest("assets/sprites/armor_vest.png")

    # 5. Combat VFX (7 assets)
    print("\n--- 5. Combat VFX ---")
    generate_muzzle_flash_m70("assets/sprites/vfx/muzzle_flash_m70.png")
    generate_muzzle_flash_shotgun("assets/sprites/vfx/muzzle_flash_shotgun.png")
    generate_explosion_charcoal("assets/sprites/vfx/explosion_charcoal.png")
    generate_shell_casing_rifle("assets/sprites/vfx/shell_casing_rifle.png")
    generate_shell_casing_shotgun("assets/sprites/vfx/shell_casing_shotgun.png")
    generate_blood_splatter_decals("assets/sprites/vfx/blood_splatter_decals.png")
    generate_scorch_mark("assets/sprites/vfx/scorch_mark.png")

    # 6. UI (5 assets)
    print("\n--- 6. UI Frames & Stamps ---")
    generate_paper_parchment_bg("assets/sprites/ui/paper_parchment_bg.png")
    generate_hud_health_frame("assets/sprites/ui/hud_health_frame.png")
    generate_hud_ammo_frame("assets/sprites/ui/hud_ammo_frame.png")
    generate_minimap_compass("assets/sprites/ui/minimap_compass.png")
    generate_stamp_mission_complete("assets/sprites/ui/stamp_mission_complete.png")

    # 7. Faction flags & insignia
    print("\n--- 7. Faction Flags & Insignia ---")
    generate_croatian_flag("assets/sprites/flag.png")
    generate_croatian_flag("assets/sprites/factions/hv_flag.png")
    generate_svk_flag("assets/sprites/factions/svk_flag.png")
    generate_hv_insignia("assets/sprites/factions/hv_insignia.png")
    generate_svk_insignia("assets/sprites/factions/svk_insignia.png")

    print("\n=== All Assets Generated Successfully! ===")


if __name__ == "__main__":
    generate_all_assets()
