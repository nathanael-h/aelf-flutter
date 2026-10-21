"""Build assets/fonts/RobotoLiturgy-*.ttf, the modern display's text font.

Roboto (SIL OFL 1.1) drawn at the size of Libertinus Serif, the classic
display's font: at the same font size, Roboto's letters are much larger
(x-height 0.528 em vs 0.429), so switching displays would change the
apparent text size, and the psalm-tone scores, whose syllables are placed
for Libertinus, would overlap. Shrinking the text through its font size
would also shrink the line spacing, which the app sets as a multiple of the
font size. Instead, the outlines are kept and the em is enlarged
(unitsPerEm = 2048 / SCALE): every glyph renders SCALE times smaller while
the font size, and so the line spacing, stays the same as in the classic
display.

Only Latin script, punctuation and common symbols are kept (UNICODE_RANGES):
the app's Greek and Hebrew texts are set in Gentium Plus, and anything else
missing falls back to the system fonts. Hinting is dropped, as it no longer
matches the enlarged em.

The fonts are renamed "Roboto Liturgy": on Android, Flutter's Material text
asks for the "Roboto" family, which a bundled font of that name would
replace by this smaller one.

Requires: fonttools (pip install fonttools)
Usage:    python3 scripts/font/build_roboto_liturgy.py <dir with Roboto*.ttf>
          (writes straight into assets/fonts/)

Source files (variable TTF, Roboto 3, saved under these names):
  https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/roboto/Roboto%5Bwdth,wght%5D.ttf
    -> Roboto.ttf
  https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/roboto/Roboto-Italic%5Bwdth,wght%5D.ttf
    -> Roboto-Italic.ttf
"""
import os
import sys
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
ASSETS_FONTS = os.path.join(REPO_ROOT, "assets", "fonts")

# Rendered size relative to Roboto: the x-height ratio to Libertinus Serif
# (0.429 / 0.528), so that lowercase letters are as tall in both displays.
SCALE = 0.812

# Characters kept; Roboto's glyphs outside these ranges are dropped.
UNICODE_RANGES = [
    (0x0000, 0x024F),  # Basic Latin, Latin-1, Latin Extended-A and -B
    (0x02B0, 0x036F),  # spacing modifier letters, combining diacritics
    (0x1D00, 0x1DBF),  # phonetic extensions (ᵉ in "1ᵉʳ")
    (0x1E00, 0x1EFF),  # Latin Extended Additional
    (0x2000, 0x22FF),  # punctuation, super/subscripts, currency, letterlike,
                       # arrows, math
    (0x25A0, 0x25FF),  # geometric shapes
    (0xFB00, 0xFB06),  # Latin ligatures
    (0xFEFF, 0xFEFF), (0xFFFD, 0xFFFD),
]

FAMILY = "Roboto Liturgy"
# style: (source file, weight)
STYLES = {
    "Regular": ("Roboto.ttf", 400),
    "Italic": ("Roboto-Italic.ttf", 400),
    "Bold": ("Roboto.ttf", 700),
    "BoldItalic": ("Roboto-Italic.ttf", 700),
}


def build(src_dir, style):
    source, weight = STYLES[style]
    font = instantiateVariableFont(TTFont(os.path.join(src_dir, source)),
                                   {"wght": weight, "wdth": 100})
    assert font["head"].unitsPerEm == 2048

    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.notdef_outline = True
    options.hinting = False
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=[cp for lo, hi in UNICODE_RANGES
                                 for cp in range(lo, hi + 1)])
    subsetter.subset(font)
    font["head"].unitsPerEm = round(2048 / SCALE)

    subfamily = {"Regular": "Regular", "Italic": "Italic", "Bold": "Bold",
                 "BoldItalic": "Bold Italic"}[style]
    ps_name = f"RobotoLiturgy-{style}"
    names = font["name"]
    for record in list(names.names):
        if record.nameID in (1, 3, 4, 6, 16, 17, 25):
            names.removeNames(nameID=record.nameID)
    names.setName(FAMILY, 1, 3, 1, 0x409)
    names.setName(subfamily, 2, 3, 1, 0x409)
    names.setName(f"{ps_name};{font['head'].fontRevision:.3f}", 3, 3, 1, 0x409)
    names.setName(f"{FAMILY} {subfamily}", 4, 3, 1, 0x409)
    names.setName(ps_name, 6, 3, 1, 0x409)
    names.setName(
        f"Roboto {subfamily}, modified for the AELF app: rendered "
        f"{SCALE} times smaller (unitsPerEm enlarged) to match the x-height "
        f"of Libertinus Serif.", 10, 3, 1, 0x409)

    out_path = os.path.join(ASSETS_FONTS, f"{ps_name}.ttf")
    font.save(out_path)
    print("saved", out_path)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    for style in STYLES:
        build(sys.argv[1], style)
