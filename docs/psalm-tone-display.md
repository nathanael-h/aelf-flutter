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

---

## Widget hierarchy

### Non-sticky (scroll mode / shrinkWrap)

```
PsalmDisplayWidget
  └── PsalmToneWidget(svgData)          ← StatefulWidget, processes SVG in build()
        └── SvgPicture.string(...)
```

`PsalmToneWidget` watches `ThemeNotifier` via `context.watch`. Any theme change triggers a rebuild and SVG reprocessing.

### Sticky (tab mode) — psalms

```
PsalmTabWidget (CustomScrollView)
  ├── SliverToBoxAdapter → PsalmDisplayHeader
  ├── SliverPersistentHeader(pinned: true)
  │     └── PsalmToneSliverDelegate(svgData, extent, themeKey)
  │           └── ColoredBox → PsalmToneWidget(svgData)
  └── SliverToBoxAdapter → PsalmDisplayBody
```

### Sticky (tab mode) — Benedictus (Lauds) / Magnificat (Vespers)

```
_CanticleTab (CustomScrollView)
  ├── SliverToBoxAdapter → CanticleHeader
  ├── SliverPersistentHeader(pinned: true)
  │     └── PsalmToneSliverDelegate(svgData, extent, themeKey)
  │           └── ColoredBox → PsalmToneWidget(svgData)
  └── SliverToBoxAdapter → CanticleBody
```

### Sticky (tab mode) — Invitatory psalm (Lauds Introduction tab)

```
_IntroductionTabState (CustomScrollView)
  ├── SliverToBoxAdapter → static header
  │     (OfficeHeaderDisplay + intro text + opening antiphon + psalm chips)
  ├── SliverPersistentHeader(pinned: true)
  │     └── PsalmToneSliverDelegate(svgData, extent, themeKey)
  │           └── ColoredBox → PsalmToneWidget(svgData)
  └── SliverToBoxAdapter → psalm body + closing antiphon
```

When the user selects a different psalm via the chips, `setState` rebuilds the `CustomScrollView`. The delegate's `shouldRebuild` detects the new `svgData` reference and rebuilds the sticky header accordingly.

In all three sticky cases, the partition pins just below the TabBar while the user reads through the text. The following section's header pushes it off screen as the user scrolls down.

---

## Fallback (no SVG data)

All three tab widgets (`PsalmTabWidget`, `_CanticleTab`, `_IntroductionTabState`) fall back to a `ListView` when no SVG data is available for the current content. `PsalmToneWidget` is omitted entirely in that case.

---

## Sticky header rebuild trigger

`SliverPersistentHeaderDelegate.shouldRebuild()` controls when the delegate's `build()` is re-invoked. Three conditions trigger a rebuild:

```dart
svgData != oldDelegate.svgData      // different psalm / source reload
|| extent != oldDelegate.extent     // screen width change
|| themeKey != oldDelegate.themeKey // dark/light or serif/sans toggle
```

`themeKey` is a `'${darkTheme}_${serifFont}'` string built in the parent widget's `build()`, which watches `ThemeNotifier`. Without this field, a theme change would leave the sticky header rendering with stale colours while the rest of the screen updated.

---

## Extent calculation

The height of the sticky header is pre-calculated by `psalmToneSliverExtent()` (`psalm_tone_sliver_delegate.dart`) from the raw SVG's `width` / `height` attributes, scaled by `_stickyScale = 1.2` and clamped to the available screen width. This avoids a layout jump when the header becomes pinned.

For multi-tone psalms (PageView), a fixed height of `202 + 24` px is used instead.

---

## Multiple tones (PageView)

When a psalm has more than one associated tone (i.e. `svgData.length > 1`), `PsalmToneWidget` renders a horizontal `PageView` with dot indicators. The user swipes between tones. The `PageController` is owned by `_PsalmToneWidgetState` and disposed with it.

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
| `lib/utils/svg_preprocessor.dart` | `preprocessPsalmSvg()` — font + colour substitution |
| `lib/widgets/…/psalm_tone_widget.dart` | `PsalmToneWidget` — renders one or more tones |
| `lib/widgets/…/psalm_tone_sliver_delegate.dart` | `PsalmToneSliverDelegate` — sticky header delegate + `psalmToneSliverExtent()` |
| `lib/widgets/…/psalms_display.dart` | `PsalmDisplayWidget`, `PsalmDisplayHeader`, `PsalmDisplayBody` |
| `lib/widgets/…/evangelic_canticle_display.dart` | `CanticleWidget`, `CanticleHeader`, `CanticleBody` |
| `lib/widgets/…/office_common_widgets.dart` | `PsalmTabWidget` — psalm sticky/non-sticky layout |
| `lib/widgets/offline_liturgy_morning_view.dart` | `_CanticleTab` (Benedictus), `_IntroductionTabState` (invitatory) |
| `lib/widgets/offline_liturgy_vespers_view.dart` | `_CanticleTab` (Magnificat) |
| `lib/widgets/…/base_office_view_state.dart` | Owns `_svgSource`, reacts to `LiturgyState` changes |
| `lib/states/liturgyState.dart` | `psalmSvgEnabled`, `psalmSvgSource` with change notifications |
