# Liturgical Symbols Font

`assets/fonts/LiturgicalSymbols-Regular.ttf` unifies the special characters used across the Divine Office display (response/versicle marks, antiphon markers, flex/mediant signs) into a single font, replacing the previous mix of Unicode characters rendered by whatever fallback font iOS/Android picked, plus a set of hand-made SVG files for antiphon markers.

Base letterforms (R, A, V and the subscript digits/letters) are drawn from **Libertinus Serif** (already bundled in `assets/fonts/`), matched with bar/swash glyphs adapted from the **Gregorio Project**'s `greextra` font — the same companion font GregorioTeX itself uses to typeset `R/`, `V/` and `A/` in chant scores. The horizontal shift of each bar (R: 0.35em, A: 0.30em using the R/V bar shape, V: 0.10em) matches the offsets documented in `gregoriotex-symbols.tex`, calibrated for Libertine/Libertinus.

---

## Character table

| Codepoint | Glyph | Meaning |
|---|---|---|
| `U+E000` | R/ | Response (℟) |
| `U+E001` | A/ | Antiphon marker, single (replaces `Ant.` SVG) |
| `U+E002` | V/ | Versicle (℣) |
| `U+E003` | R/1 | Response, numbered variant 1 |
| `U+E004` | R/2 | Response, numbered variant 2 |
| `U+E005` | R/3 | Response, numbered variant 3 |
| `U+E006` | A/1 | Antiphon marker 1 (replaces `Ant. 1` SVG) |
| `U+E007` | A/2 | Antiphon marker 2 (replaces `Ant. 2` SVG) |
| `U+E008` | A/3 | Antiphon marker 3 (replaces `Ant. 3` SVG) |
| `U+E009` | A/A | Antiphon marker, liturgical year A (replaces `Ant. A` SVG) |
| `U+E00A` | A/B | Antiphon marker, liturgical year B (replaces `Ant. B` SVG) |
| `U+E00B` | A/C | Antiphon marker, liturgical year C (replaces `Ant. C` SVG) |
| `U+E00C` | Cross | Rubric cross (from greextra `Cross`, U+E02C in the source font) |
| `U+E00D` | Dagger | Flex mark (from greextra `Dagger`) |
| `U+E00E` | Star | Mediant/asterisk mark (from greextra `StarHeight`, U+E02B in the source font) |
| `U+E00F` | ✙ | Outlined Latin cross (hand-drawn, not from greextra) |

All codepoints are in the Private Use Area, chosen freely for this font — they do not need to match greextra's own PUA assignments.

`AntiphonMarkerIcon` (`lib/widgets/offline_liturgy_common_widgets/antiphon_marker_icon.dart`) only uses `U+E001` (A/): an `AntiphonMarker`'s index (`1`, `2`… with no upper bound, or `A`/`B`/`C` for the liturgical year) is drawn after it as a subscript in Libertinus Serif. The precomposed `U+E006`–`U+E00B` glyphs remain in the font but are no longer used, since they capped numbered antiphons at 3.

---

## Provenance & licensing

- Bar/cross/star outlines: adapted from the Gregorio Project's `greextra.sfd` (SIL Open Font License 1.1, per the font's own embedded copyright notice).
- Base letterforms and subscript digits/letters: Libertinus Serif Regular (SIL Open Font License 1.1).
- Outlined cross (`U+E00F`) and the composition/assembly of all glyphs: original work for this project.

---

## Usage in the code

The font is declared in `pubspec.yaml` as the `LiturgicalSymbols` family. The glyph constants live in `YamlTextParser` (`lib/parsers/yaml_text_parser.dart`): `responseGlyph`, `versicleGlyph`, `responseNb1Glyph`–`responseNb3Glyph`, `starGlyph`, `daggerGlyph`, `outlinedCrossGlyph`.

| Where | What |
|---|---|
| `YamlTextParser` | `R/`, `V/`, `R/1`–`R/3` are pre-substituted to their codepoints; `*` and `+` stay literal in the text and are mapped to Star/Dagger at render time by `glyphFor()` |
| `psalm_parser.dart` | Same substitution for psalm verses; `*` and `+` are drawn as raised marks above the baseline |
| `AntiphonMarkerIcon` | `U+E001` (A/) + subscript index |
| `offline_liturgy_mass_view.dart` | `U+E00F` (outlined cross) before the Gospel announcement |

## Not yet migrated

- `formatted_text_parser.dart` (used by the Hebrew/Greek psalm parsers) still uses the old Unicode approach: `R/`→℟, `V/`→℣, `*`→✽.
- `U+E00C` (Cross) is in the font but not referenced by any code.
