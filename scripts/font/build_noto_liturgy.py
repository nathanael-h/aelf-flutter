"""Build assets/fonts/NotoSansLiturgy-*.ttf, the modern display's text font.

Noto Sans (SIL OFL 1.1) drawn at the size of Libertinus Serif, the classic
display's font: at the same font size, Noto Sans's letters are much larger
(x-height 536 vs 429, cap height 714 vs 658), so switching displays would
change the apparent text size. Shrinking the text through its font size
would also shrink the line spacing, which the app sets as a multiple of the
font size. Instead, the outlines are kept and the em is enlarged
(unitsPerEm = 1000 / SCALE): every glyph renders SCALE times smaller while
the font size, and so the line spacing, stays the same as in the classic
display.

Noto Sans is also loosely spaced next to Libertinus: every advance width is
narrowed by TRACKING (a fraction of Noto Sans's em), like a slightly
negative letter spacing.

Only Latin script, punctuation and common symbols are kept (UNICODE_RANGES),
which divides the files' size by about three: the app's Greek and Hebrew
texts are set in Gentium Plus, and anything else missing falls back to the
system fonts.

The fonts are renamed "Noto Sans Liturgy" since they no longer render like
Noto Sans.

Requires: fonttools (pip install fonttools)
Usage:    python3 scripts/font/build_noto_liturgy.py <dir with NotoSans-*.ttf>
          (writes straight into assets/fonts/)

Source files (unhinted static TTF, Noto Sans 2.015):
  https://cdn.jsdelivr.net/gh/notofonts/notofonts.github.io/fonts/NotoSans/unhinted/ttf/NotoSans-{Regular,Italic,Bold,BoldItalic}.ttf
"""
import os
import sys
from fontTools import subset
from fontTools.ttLib import TTFont

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
ASSETS_FONTS = os.path.join(REPO_ROOT, "assets", "fonts")

# Rendered size relative to Noto Sans. Between the x-height ratio (0.80) and
# the cap-height ratio (0.92) to Libertinus Serif; at 0.86 a line of text
# takes about the same width in both fonts.
SCALE = 0.86

# Letter spacing, in fractions of Noto Sans's em, taken off every advance.
TRACKING = -0.01

# Characters kept; Noto Sans's glyphs outside these ranges are dropped.
UNICODE_RANGES = [
    (0x0000, 0x024F),  # Basic Latin, Latin-1, Latin Extended-A and -B
    (0x02B0, 0x036F),  # spacing modifier letters, combining diacritics
    (0x1D00, 0x1DBF),  # phonetic extensions (ᵉ in "1ᵉʳ")
    (0x1E00, 0x1EFF),  # Latin Extended Additional
    (0x2000, 0x22FF),  # punctuation, super/subscripts, currency, letterlike
                       # (℟ ℣, read by build_final_font.py), arrows, math
    (0x25A0, 0x25FF),  # geometric shapes
    (0xFB00, 0xFB06),  # Latin ligatures
    (0xFEFF, 0xFEFF), (0xFFFD, 0xFFFD),
]

FAMILY = "Noto Sans Liturgy"
STYLES = ["Regular", "Italic", "Bold", "BoldItalic"]


def build(src_dir, style):
    font = TTFont(os.path.join(src_dir, f"NotoSans-{style}.ttf"))
    assert font["head"].unitsPerEm == 1000

    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=[cp for lo, hi in UNICODE_RANGES
                                 for cp in range(lo, hi + 1)])
    subsetter.subset(font)
    font["head"].unitsPerEm = round(1000 / SCALE)

    # Zero-width glyphs (combining marks) keep their width.
    tracking_units = round(TRACKING * 1000)
    hmtx = font["hmtx"]
    for name, (advance, lsb) in hmtx.metrics.items():
        if advance > 0:
            hmtx.metrics[name] = (max(0, advance + tracking_units), lsb)

    subfamily = {"Regular": "Regular", "Italic": "Italic", "Bold": "Bold",
                 "BoldItalic": "Bold Italic"}[style]
    ps_name = f"NotoSansLiturgy-{style}"
    names = font["name"]
    for record in list(names.names):
        if record.nameID in (1, 3, 4, 6, 16, 17):
            names.removeNames(nameID=record.nameID)
    names.setName(FAMILY, 1, 3, 1, 0x409)
    names.setName(subfamily, 2, 3, 1, 0x409)
    names.setName(f"{ps_name};{font['head'].fontRevision:.3f}", 3, 3, 1, 0x409)
    names.setName(f"{FAMILY} {subfamily}", 4, 3, 1, 0x409)
    names.setName(ps_name, 6, 3, 1, 0x409)
    names.setName(
        f"Noto Sans {style}, modified for the AELF app: rendered "
        f"{SCALE} times smaller (unitsPerEm enlarged) to match the size of "
        f"Libertinus Serif, letter spacing {TRACKING:+.0%}.", 10, 3, 1, 0x409)

    out_path = os.path.join(ASSETS_FONTS, f"{ps_name}.ttf")
    font.save(out_path)
    print("saved", out_path)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    for style in STYLES:
        build(sys.argv[1], style)
