# Psalm Tone Display

Musical notation for psalm tones is rendered as SVG, sourced from external repositories (currently Séminaire Emmanuel or Séminaire de Paris). This document describes the full pipeline from raw SVG data to on-screen rendering, including theming and sticky-header behaviour.

---

## Data flow

```
offline_liturgy package
  └── exportOffice(CelebrationContext)
        └── CelebrationContext.svgSource   ← set from LiturgyState.psalmSvgSource
              └── loads raw SVG strings into Morning / Vespers office data
                    ├── PsalmEntry.svgData: List<String>          (psalms)
                    ├── Morning.canticleSvgData: List<String>     (Benedictus)
                    ├── Vespers.canticleSvgData: List<String>     (Magnificat)
                    └── Invitatory.psalmsSvgData: List<List<String>>  (invitatory psalms)
```

`svgSource` is resolved in `BaseOfficeViewState._loadOffice()` synchronously from `LiturgyState.psalmSvgEnabled` / `LiturgyState.psalmSvgSource`. When either setting changes, `LiturgyState.notifyListeners()` fires and `_onPsalmSettingsChanged()` triggers a full reload.

---

## SVG preprocessing

Raw SVGs use placeholder values for font and colour that must be substituted at render time:

| Placeholder | Replacement | Source |
|---|---|---|
| `font-family="Linux Libertine"` | `LibertinusSerif` or `SourceSans3` | `ThemeNotifier.serifFont` |
| `currentColor` | `rgba(r, g, b, a)` CSS string | `Theme.textTheme.bodyMedium.color` |
| `color="rgba(100.0000%, …)"` | `fill="…" color="…"` | `Theme.colorScheme.secondary` |

Preprocessing is performed in `PsalmToneWidget.build()` via `preprocessPsalmSvg()` (`lib/utils/svg_preprocessor.dart`). The body text colour is read directly from the theme rather than hardcoded, so the SVG always matches the surrounding psalm text including its alpha channel.

A fourth substitution, `stroke:#000` → `redColor`, is a leftover from the former SVG antiphon markers. `AntiphonMarkerIcon` now draws a glyph of the LiturgicalSymbols font (see `docs/liturgical-symbols-font.md`), so this substitution no longer matches anything in the psalm-tone scores.

---

## Widget hierarchy

### `PsalmToneWidget`

```
PsalmToneWidget(svgData)                 ← StatefulWidget, processes SVG in build()
  └── LiturgyRow(left: LiturgyRowLeft.indent)   ← left column stays empty,
        └── SvgPicture.string(...)                aligned with verse text
```

`PsalmToneWidget` watches `ThemeNotifier` and `CurrentZoom` via `context.watch`: any theme or zoom change rebuilds it and reprocesses the SVG. The score is drawn at its natural width (the `width` attribute of the `<svg>` tag, or the `viewBox` width as a fallback), clamped to the width available in the `LiturgyRow` content column: `screenWidth - liturgyRowIndentWidth(zoom) - 15`.

### Sticky partition

The partition is kept pinned at the top of the screen while the user reads the text, using `SliverStickyHeader` from the `flutter_sticky_header` package. The same pattern is used everywhere:

```
CustomScrollView
  ├── SliverToBoxAdapter → header (title, antiphon…)
  ├── SliverStickyHeader
  │     header: ColoredBox(scaffoldBackgroundColor) → PsalmToneWidget(svgData)
  │     sliver: SliverToBoxAdapter → body (verses, closing antiphon)
  └── …
```

The header height is measured by the package itself, so there is no extent to precompute. The `ColoredBox` hides the text scrolling underneath. The next section's sticky header pushes the current one off screen.

| Content | Tab mode | Scroll mode |
|---|---|---|
| Psalms | `PsalmTabWidget` (`office_common_widgets.dart`): `PsalmDisplayHeader` / `PsalmDisplayBody` | Vespers and Lauds `_buildScrollView()`: one `SliverStickyHeader` per psalm with SVG |
| Benedictus (Lauds) | `_CanticleTab` (`offline_liturgy_morning_view.dart`) | `MorningOfficeDisplay._buildScrollView()` |
| Magnificat (Vespers) | `_CanticleTab` (`offline_liturgy_vespers_view.dart`) | `VespersOfficeDisplay._buildScrollView()` |
| Invitatory psalm (Lauds) | `_IntroductionTab` (`offline_liturgy_morning_view.dart`) | `MorningOfficeDisplay._buildScrollView()` |

For the invitatory, the selected psalm index (`_selectedInvitatoryPsalmIndex`) lives in `_MorningOfficeDisplayState`. `_IntroductionTab` is stateless and receives `selectedPsalmIndex` / `onPsalmSelected`. Selecting another psalm through the chips triggers a `setState`, which rebuilds the view with the new psalm's `svgData`.

---

## Fallback (no SVG data)

When no SVG data is available for the current content, the widgets fall back to their plain layout (`ListView` in tab mode, a simple `SliverToBoxAdapter` in scroll mode). `PsalmToneWidget` is omitted entirely in that case.

---

## Multiple tones (PageView)

When a psalm has more than one associated tone (`svgData.length > 1`), `PsalmToneWidget` renders a horizontal `PageView` with a fixed height of 160 px, followed by dot indicators. The user swipes between tones. The `PageController` is owned by `_PsalmToneWidgetState` and disposed with it.

---

## Settings

| Setting | Key | Provider field |
|---|---|---|
| SVG enabled | `psalm_svg_enabled` | `LiturgyState.psalmSvgEnabled` |
| SVG source | `psalm_svg_source` | `LiturgyState.psalmSvgSource` |
| Serif font | (ThemeNotifier) | `ThemeNotifier.serifFont` |
| Dark theme | (ThemeNotifier) | `ThemeNotifier.darkTheme` |

Changing `psalmSvgEnabled` or `psalmSvgSource` in the settings screen calls `LiturgyState.updatePsalmSvgEnabled()` / `updatePsalmSvgSource()`, which persist to `SharedPreferences` and call `notifyListeners()`. `BaseOfficeViewState` listens to `LiturgyState` and reloads the office when these values change.

---

## Key files

| File | Role |
|---|---|
| `lib/utils/svg_preprocessor.dart` | `preprocessPsalmSvg()`: font and colour substitution |
| `lib/widgets/liturgy_row.dart` | `liturgyRowIndentWidth(zoom)`: shared indent-width formula used to size the score within `LiturgyRow`'s content column |
| `lib/widgets/…/psalm_tone_widget.dart` | `PsalmToneWidget`: renders one or more tones |
| `lib/widgets/…/psalms_display.dart` | `PsalmDisplayWidget`, `PsalmDisplayHeader`, `PsalmDisplayBody` |
| `lib/widgets/…/evangelic_canticle_display.dart` | `CanticleWidget`, `CanticleHeader`, `CanticleBody` |
| `lib/widgets/…/office_common_widgets.dart` | `PsalmTabWidget`: psalm layout, sticky or not |
| `lib/widgets/offline_liturgy_morning_view.dart` | `_CanticleTab` (Benedictus), `_IntroductionTab` (invitatory), scroll mode |
| `lib/widgets/offline_liturgy_vespers_view.dart` | `_CanticleTab` (Magnificat), scroll mode |
| `lib/widgets/…/base_office_view_state.dart` | Owns `_svgSource`, reacts to `LiturgyState` changes |
| `lib/states/liturgyState.dart` | `psalmSvgEnabled`, `psalmSvgSource` with change notifications |
