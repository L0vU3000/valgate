#!/usr/bin/env python3
"""Render the Valgate 'Energetic Sleek' before/after comparison as a PNG."""
from PIL import Image, ImageDraw, ImageFont
import os

# --- Fonts (try to find Inter or fall back to DejaVu) ---
def find_font(size, weight="Regular"):
    candidates = {
        "Regular": [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        ],
        "Bold": [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        ],
    }
    for c in candidates.get(weight, candidates["Regular"]):
        if os.path.exists(c):
            try:
                return ImageFont.truetype(c, size)
            except Exception:
                pass
    return ImageFont.load_default()

# --- Colors ---
CANVAS   = (245, 247, 250)
WHITE    = (255, 255, 255)
CARD_BG  = (248, 250, 252)
INK      = (17, 24, 39)
SECONDARY= (102, 116, 133)
MUTED    = (60, 60, 67)
COBALT   = (36, 91, 255)
BORDER   = (229, 231, 235)
RED_BG   = (254, 226, 226)
RED_TXT  = (185, 28, 28)
BLUE_BG  = (219, 234, 254)
BLUE_TXT = (29, 78, 216)

W, H = 900, 720
img = Image.new("RGB", (W, H), CANVAS)
d = ImageDraw.Draw(img)

# --- Title ---
f_title = find_font(22, "Bold")
f_sub   = find_font(13, "Regular")
f_h2    = find_font(13, "Bold")
f_tag   = find_font(11, "Bold")
f_label = find_font(11, "Bold")
f_val   = find_font(17, "Bold")
f_val_r = find_font(17, "Regular")
f_cap   = find_font(13, "Regular")
f_metric= find_font(34, "Bold")
f_oldlabel = find_font(15, "Regular")

d.text((40, 24), "Valgate iOS — Energetic Sleek Refactor", font=f_title, fill=INK)
d.text((40, 58), "Before (current Figma) vs After (Energetic Sleek) — core components", font=f_sub, fill=SECONDARY)

def draw_tag(d, x, y, text, bg, fg):
    w = d.textlength(text, font=f_tag) + 16
    d.rounded_rectangle([x, y, x+w, y+22], radius=11, fill=bg)
    d.text((x+8, y+4), text, font=f_tag, fill=fg)
    return w

def draw_card(x, y, w, h, title, is_after):
    d.rounded_rectangle([x, y, x+w, y+h], radius=16, fill=WHITE,
                        outline=(COBALT if is_after else BORDER), width=1 if is_after else 0)
    # header
    d.text((x+20, y+18), title, font=f_h2, fill=(COBALT if is_after else SECONDARY))
    return y + 48

# --- VGDataRow section ---
sec_y = 100
# Before card
by = draw_card(40, sec_y, 400, 300, "VGDataRow (current)", False)
draw_tag(d, 60, by, "BEFORE", RED_BG, RED_TXT)
by += 34
rows_before = [
    ("Monthly rent", "$1,450", "per month"),
    ("Property type", "Villa", None),
    ("Bedrooms", "4", None),
]
for label, val, cap in rows_before:
    d.line([(60, by+40), (420, by+40)], fill=BORDER, width=1)
    d.text((60, by+6), label, font=f_oldlabel, fill=MUTED)
    d.text((60, by+26), val, font=f_val_r, fill=MUTED)
    if cap:
        d.text((60, by+46), cap, font=f_cap, fill=SECONDARY)
    by += 70

# After card
ay = draw_card(460, sec_y, 400, 300, "VGDataRow (Sleek)", True)
draw_tag(d, 480, ay, "AFTER", BLUE_BG, BLUE_TXT)
ay += 34
rows_after = [
    ("Monthly rent", "$1,450", "per month"),
    ("Property type", "Villa", None),
    ("Bedrooms", "4", None),
]
for label, val, cap in rows_after:
    d.rounded_rectangle([480, ay, 840, ay+56], radius=12, fill=CARD_BG)
    d.text((496, ay+6), label.upper(), font=f_label, fill=SECONDARY)
    d.text((496, ay+26), val, font=f_val, fill=INK)
    if cap:
        d.text((496, ay+40), cap, font=f_cap, fill=SECONDARY)
    ay += 66

# --- VGMetric section ---
sec2_y = 420
# Before
by2 = draw_card(40, sec2_y, 400, 260, "VGMetric (current)", False)
draw_tag(d, 60, by2, "BEFORE", RED_BG, RED_TXT)
by2 += 40
d.text((60, by2), "PORTFOLIO VALUE", font=f_label, fill=SECONDARY)
d.text((60, by2+22), "$14.79M", font=f_metric, fill=INK)
d.text((60, by2+70), "across 27 properties", font=f_cap, fill=SECONDARY)

# After
ay2 = draw_card(460, sec2_y, 400, 260, "VGMetric (Sleek)", True)
draw_tag(d, 480, ay2, "AFTER", BLUE_BG, BLUE_TXT)
ay2 += 40
# accent bar
d.rounded_rectangle([480, ay2, 483, ay2+110], radius=2, fill=COBALT)
d.text((496, ay2), "PORTFOLIO VALUE", font=f_label, fill=SECONDARY)
d.text((496, ay2+22), "$14.79M", font=f_metric, fill=INK)
d.text((496, ay2+70), "across 27 properties", font=f_cap, fill=SECONDARY)

out = "/home/hermes/development/projects/valgate-monorepo/apps/ios/docs/design/before-after.png"
img.save(out)
print(f"Saved: {out}")
