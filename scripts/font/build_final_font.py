"""Build assets/fonts/LiturgicalSymbols-Regular.ttf.

Composites R/, V/, A/ (and their numbered/lettered variants) from Libertinus
Serif letterforms + bar glyphs adapted from the Gregorio Project's greextra
font, plus a handful of standalone marks (cross, dagger, mediant star, and
the outlined ✙ cross traced from Noto Sans Symbols2).

See docs/liturgical-symbols-font.md for the character table and rationale.

Requires: fonttools, skia-pathops (pip install fonttools skia-pathops)
Usage:    python3 scripts/font/build_final_font.py
          (writes straight into assets/fonts/, overwriting the shipped font)
"""
import os
import pathops
from fontTools.ttLib import TTFont
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.areaPen import AreaPen
from fontTools.pens.reverseContourPen import ReverseContourPen
from fontTools.misc.transform import Transform

import sfd_lib

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
ASSETS_FONTS = os.path.join(REPO_ROOT, "assets", "fonts")

BOLD_WIDTH = 20  # font units (1000 upm) added via stroke+union outset

def embolden(recording_pen, width):
    """Outset every contour outward by ~width/2 (stroke the outline, then
    union the stroke ribbon back onto the fill) — counters/holes shrink and
    the outer silhouette grows, same as a normal font's regular->bold step."""
    if width <= 0:
        return recording_pen
    orig_path = pathops.Path()
    recording_pen.replay(orig_path.getPen())

    stroke_path = pathops.Path()
    recording_pen.replay(stroke_path.getPen())
    stroke_path.stroke(width, pathops.LineCap.ROUND_CAP,
                        pathops.LineJoin.ROUND_JOIN, 4.0)
    stroke_path.convertConicsToQuads()

    result = pathops.op(orig_path, stroke_path, pathops.PathOp.UNION)
    target = result if result is not None else orig_path
    out = RecordingPen()
    target.draw(out)
    return out

def _split_contours(pen_value):
    contours = []
    cur = []
    for op, args in pen_value:
        if op == "moveTo":
            if cur:
                contours.append(cur)
            cur = [(op, args)]
        else:
            cur.append((op, args))
    if cur:
        contours.append(cur)
    return contours

def _contour_area(contour):
    ap = AreaPen(None)
    for op, args in contour:
        getattr(ap, op)(*args)
    return ap.value

def outer_contour_sign(recording_pen):
    """Sign of the largest-by-area contour — i.e. the glyph's own body/outer
    shape, as opposed to any internal counter (hole), which is always smaller
    and opposite-signed by construction."""
    contours = _split_contours(recording_pen.value)
    best_area, best_sign = 0.0, 1
    for c in contours:
        area = _contour_area(c)
        if abs(area) > abs(best_area):
            best_area, best_sign = area, (1 if area >= 0 else -1)
    return best_sign

def append_matching_winding(source_pen, target_pen, target_sign):
    """Replay source_pen's contours into target_pen, reversing them first if
    their (single, outer) winding doesn't match target_sign — otherwise two
    glyph sources authored with opposite winding conventions cancel out to a
    hole wherever they overlap instead of reinforcing each other."""
    if outer_contour_sign(source_pen) != target_sign:
        source_pen.replay(ReverseContourPen(target_pen))
    else:
        target_pen.value.extend(source_pen.value)

UPM = 1000
LIB_PATH = os.path.join(ASSETS_FONTS, "LibertinusSerif-Regular.otf")

lib_font = TTFont(LIB_PATH)
assert lib_font["head"].unitsPerEm == UPM
lib_gs = lib_font.getGlyphSet()
lib_cmap = lib_font.getBestCmap()
lib_hmtx = lib_font["hmtx"]

def lib_name(ch):
    return lib_cmap[ord(ch)]

def lib_bounds(ch):
    bp = BoundsPen(lib_gs)
    lib_gs[lib_name(ch)].draw(bp)
    return bp.bounds  # xMin, yMin, xMax, yMax

def draw_lib_letter(ch, pen, dx=0.0, dy=0.0, scale=1.0):
    t = Transform(scale, 0, 0, scale, dx, dy)
    tpen = TransformPen(pen, t)
    lib_gs[lib_name(ch)].draw(tpen)

# --- greextra bars/symbols (Gregorio Project, SIL OFL 1.1) ---
blocks = sfd_lib.parse_sfd(os.path.join(SCRIPT_DIR, "greextra.sfd"))

def greextra_contours(name):
    return sfd_lib.parse_splineset(blocks[name])

RBAR = greextra_contours("RBar")
VBAR = greextra_contours("VBar")
CROSS = greextra_contours("Cross")
DAGGER = greextra_contours("Dagger")
STARHEIGHT = greextra_contours("StarHeight")

RBAR_BOUNDS = sfd_lib.contours_bounds(RBAR)   # (0, -135, 307, 744)
VBAR_BOUNDS = sfd_lib.contours_bounds(VBAR)

# --- outlined cross (U+2719), traced from Noto Sans Symbols2 (SIL OFL 1.1) ---
NOTO_PATH = os.path.join(SCRIPT_DIR, "NotoSansSymbols2-Regular.ttf")
noto_font = TTFont(NOTO_PATH)
assert noto_font["head"].unitsPerEm == UPM
noto_gs = noto_font.getGlyphSet()
NOTO_CROSS_NAME = noto_font.getBestCmap()[0x2719]
NOTO_CROSS_ADVANCE = noto_font["hmtx"][NOTO_CROSS_NAME][0]

SHIFT_EM = {"R": 0.35, "A": 0.30, "V": 0.10}
BAR_FOR = {"R": RBAR, "A": RBAR, "V": VBAR}   # A uses the same bar as R, per feedback
BAR_BOUNDS_FOR = {"R": RBAR_BOUNDS, "A": RBAR_BOUNDS, "V": VBAR_BOUNDS}

SUB_SCALE = 0.55
GAP_UNITS = {"R": -115, "V": -115, "A": -65}

def build_barred_glyph(letter, sub=None):
    """letter: 'R' | 'A' | 'V' ; sub: subscript char (digit or A/B/C) or None."""
    rec = RecordingPen()
    letter_rec = RecordingPen()
    draw_lib_letter(letter, letter_rec)  # base letter, identity transform
    target_sign = outer_contour_sign(letter_rec)
    rec.value.extend(letter_rec.value)

    shift = SHIFT_EM[letter] * UPM
    bar_contours = BAR_FOR[letter]
    bar_bounds = BAR_BOUNDS_FOR[letter]
    bar_rec = RecordingPen()
    sfd_lib.replay_contours(bar_contours, bar_rec, dx=shift, dy=0.0)
    # greextra's contours wind opposite to Libertinus's — merging them as-is
    # cancels to a hole (nonzero fill rule) wherever the bar overlaps the
    # letter's body. Normalize before merging.
    append_matching_winding(bar_rec, rec, target_sign)

    letter_bounds = lib_bounds(letter)
    ink_right = max(letter_bounds[2], bar_bounds[2] + shift)
    advance = max(lib_hmtx[lib_name(letter)][0], ink_right + 20)

    if sub is not None:
        gap = GAP_UNITS[letter]
        digit_x = ink_right + gap
        digit_baseline = bar_bounds[1]  # yMin of the bar (bottom of its ink), dy=0 so unaffected by shift
        sub_rec = RecordingPen()
        draw_lib_letter(sub, sub_rec, dx=digit_x, dy=digit_baseline, scale=SUB_SCALE)
        append_matching_winding(sub_rec, rec, target_sign)
        sub_bounds = lib_bounds(sub)
        sub_right = digit_x + sub_bounds[2] * SUB_SCALE
        advance = max(advance, sub_right + 20)

    return rec, advance

def build_plain_glyph(contours):
    rec = RecordingPen()
    sfd_lib.replay_contours(contours, rec)
    bounds = sfd_lib.contours_bounds(contours)
    advance = bounds[2] + 40
    return rec, advance

def build_outlined_cross():
    """Traced from Noto Sans Symbols2's own U+2719 (OFL) — the actual ✙
    model (equal-armed, hollow-outline cross), not a freehand approximation."""
    rec = RecordingPen()
    noto_gs[NOTO_CROSS_NAME].draw(rec)
    return rec, NOTO_CROSS_ADVANCE

def to_ttglyph(recording_pen, bold=False):
    pen = embolden(recording_pen, BOLD_WIDTH) if bold else recording_pen
    tt_pen = TTGlyphPen(None)
    cu2qu = Cu2QuPen(tt_pen, max_err=1.0)
    pen.replay(cu2qu)
    return tt_pen.glyph()

# --- Assemble all glyphs ---
CODEPOINTS = {
    "response": 0xE000,        # R/
    "antiphon": 0xE001,        # A/
    "versicle": 0xE002,        # V/
    "responseNb1": 0xE003,     # R/1
    "responseNb2": 0xE004,     # R/2
    "responseNb3": 0xE005,     # R/3
    "antiphonNb1": 0xE006,     # A/1
    "antiphonNb2": 0xE007,     # A/2
    "antiphonNb3": 0xE008,     # A/3
    "antiphonYearA": 0xE009,   # A/A
    "antiphonYearB": 0xE00A,   # A/B
    "antiphonYearC": 0xE00B,   # A/C
    "cross": 0xE00C,           # Cross (greextra "Cross", U+E02C in the source font)
    "dagger": 0xE00D,          # Dagger (greextra)
    "star": 0xE00E,            # StarHeight (greextra)
    "outlinedCross": 0xE00F,   # ✙, traced from Noto Sans Symbols2
}

specs = {
    "response": lambda: build_barred_glyph("R"),
    "antiphon": lambda: build_barred_glyph("A"),
    "versicle": lambda: build_barred_glyph("V"),
    "responseNb1": lambda: build_barred_glyph("R", "1"),
    "responseNb2": lambda: build_barred_glyph("R", "2"),
    "responseNb3": lambda: build_barred_glyph("R", "3"),
    "antiphonNb1": lambda: build_barred_glyph("A", "1"),
    "antiphonNb2": lambda: build_barred_glyph("A", "2"),
    "antiphonNb3": lambda: build_barred_glyph("A", "3"),
    "antiphonYearA": lambda: build_barred_glyph("A", "A"),
    "antiphonYearB": lambda: build_barred_glyph("A", "B"),
    "antiphonYearC": lambda: build_barred_glyph("A", "C"),
    "cross": lambda: build_plain_glyph(CROSS),
    "dagger": lambda: build_plain_glyph(DAGGER),
    "star": lambda: build_plain_glyph(STARHEIGHT),
    "outlinedCross": build_outlined_cross,
}

glyph_order = [".notdef"] + list(CODEPOINTS.keys())
glyphs = {}
metrics = {".notdef": (500, 0)}
cmap = {}

notdef_pen = TTGlyphPen(None)
notdef_pen.moveTo((50, 0)); notdef_pen.lineTo((50, 700)); notdef_pen.lineTo((450, 700)); notdef_pen.lineTo((450, 0))
notdef_pen.closePath()
glyphs[".notdef"] = notdef_pen.glyph()

# Only the R/V/A-based marks get the weight bump; the standalone symbols
# (cross, dagger, star, outlined cross) keep their original source weight.
BOLD_GLYPHS = {
    "response", "antiphon", "versicle",
    "responseNb1", "responseNb2", "responseNb3",
    "antiphonNb1", "antiphonNb2", "antiphonNb3",
    "antiphonYearA", "antiphonYearB", "antiphonYearC",
}

for name in CODEPOINTS:
    rec, advance = specs[name]()
    glyphs[name] = to_ttglyph(rec, bold=name in BOLD_GLYPHS)
    metrics[name] = (round(advance), 0)
    cmap[CODEPOINTS[name]] = name

fb = FontBuilder(UPM, isTTF=True)
fb.setupGlyphOrder(glyph_order)
fb.setupCharacterMap(cmap)
fb.setupGlyf(glyphs)
fb.setupHorizontalMetrics(metrics)
fb.setupHorizontalHeader(ascent=900, descent=-200)
fb.setupNameTable({
    "familyName": "LiturgicalSymbols",
    "styleName": "Regular",
    "uniqueFontIdentifier": "LiturgicalSymbols-Regular:2026",
    "fullName": "LiturgicalSymbols Regular",
    "psName": "LiturgicalSymbols-Regular",
    "version": "Version 1.0",
    "copyright": "Bar/cross/star glyphs adapted from the Gregorio Project's greextra font "
                 "(SIL OFL 1.1). Base letterforms from Libertinus Serif (SIL OFL 1.1). "
                 "Outlined cross (U+2719) traced from Noto Sans Symbols2 (SIL OFL 1.1). "
                 "Composition original work.",
})
fb.setupOS2(sTypoAscender=900, sTypoDescender=-200, usWinAscent=900, usWinDescent=200)
fb.setupPost()

out_path = os.path.join(ASSETS_FONTS, "LiturgicalSymbols-Regular.ttf")
fb.save(out_path)
print("saved", out_path)
for name, cp in CODEPOINTS.items():
    print(f"  U+{cp:04X}  {name}  width={metrics[name][0]}")
