# LiturgicalSymbols font build

Regenerates `assets/fonts/LiturgicalSymbols-Regular.ttf`. See
`docs/liturgical-symbols-font.md` for the character table and design
rationale — this is the "how", that doc is the "what/why".

## Files

- `build_final_font.py` — the generator. Run it after editing any of the
  tuning constants at the top (`BOLD_WIDTH`, `GAP_UNITS`, `SHIFT_EM`,
  `SUB_SCALE`, `BOLD_GLYPHS`) or after touching `greextra.sfd`.
- `sfd_lib.py` — a small parser for FontForge's `.sfd` text format (just
  enough to read `SplineSet` outlines; no FontForge install needed).
- `greextra.sfd` — the Gregorio Project's companion typesetting font
  (SIL OFL 1.1), source of the R/V/A bar glyphs, cross, dagger and star.
- `NotoSansSymbols2-Regular.ttf` — Noto Sans Symbols2 (SIL OFL 1.1), source
  of the outlined ✙ cross (U+2719).
- `render_preview.py` — renders every glyph to `preview.png` for a quick
  visual check after regenerating.

## Usage

```
pip install fonttools skia-pathops pillow
python3 scripts/font/build_final_font.py    # overwrites assets/fonts/LiturgicalSymbols-Regular.ttf
python3 scripts/font/render_preview.py      # writes scripts/font/preview.png
```

Base letterforms come directly from `assets/fonts/LibertinusSerif-Regular.otf`
(already in the repo) — no separate copy needed here.

## Why not just use FontForge

Everything here — reading `.sfd` outlines, merging glyphs from two different
source fonts, fixing the resulting winding-direction conflicts, and
emboldening — is done with `fonttools` + `skia-pathops` instead of a
FontForge install, since neither this repo nor most dev machines have
FontForge's Python bindings available.
