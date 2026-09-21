"""Render every LiturgicalSymbols glyph to a PNG for a quick visual sanity
check after regenerating the font (build_final_font.py).

Usage: python3 scripts/font/render_preview.py
       (writes scripts/font/preview.png)
"""
import os
from PIL import Image, ImageDraw, ImageFont

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
FONT_PATH = os.path.join(REPO_ROOT, "assets", "fonts", "LiturgicalSymbols-Regular.ttf")

FONT = ImageFont.truetype(FONT_PATH, 90)
try:
    LABEL_FONT = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 15)
except OSError:
    LABEL_FONT = ImageFont.load_default()

items = [
    ("R/", 0xE000), ("A/", 0xE001), ("V/", 0xE002),
    ("R/1", 0xE003), ("R/2", 0xE004), ("R/3", 0xE005),
    ("A/1", 0xE006), ("A/2", 0xE007), ("A/3", 0xE008),
    ("A/A", 0xE009), ("A/B", 0xE00A), ("A/C", 0xE00B),
    ("Cross", 0xE00C), ("Dagger", 0xE00D), ("Star", 0xE00E), ("OutlCross", 0xE00F),
]

CELL_W, CELL_H, PAD, COLS = 160, 180, 20, 4
rows = (len(items) + COLS - 1) // COLS
img = Image.new("RGB", (PAD * 2 + COLS * CELL_W, PAD * 2 + rows * CELL_H), "white")
draw = ImageDraw.Draw(img)

for i, (label, cp) in enumerate(items):
    col, row = i % COLS, i // COLS
    x, y = PAD + col * CELL_W, PAD + row * CELL_H
    draw.rectangle([x, y, x + CELL_W - 10, y + CELL_H - 10], outline="#cccccc")
    ch = chr(cp)
    bbox = draw.textbbox((0, 0), ch, font=FONT)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    cx = x + (CELL_W - 10 - w) / 2 - bbox[0]
    cy = y + (CELL_H - 10 - h) / 2 - bbox[1] - 10
    draw.text((cx, cy), ch, font=FONT, fill="#8B0000")
    draw.text((x + 5, y + CELL_H - 22), f"{label}  U+{cp:04X}", font=LABEL_FONT, fill="black")

out_path = os.path.join(SCRIPT_DIR, "preview.png")
img.save(out_path)
print("saved", out_path)
