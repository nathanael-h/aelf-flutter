# Psalm Tone Display

Musical notation for psalm tones is rendered as SVG, sourced from external repositories (currently Séminaire Emmanuel or Séminaire de Paris). This document describes the full pipeline from raw SVG data to on-screen rendering, including theming and sticky-header behaviour.

---

## Data flow

```
offline_liturgy package
  └── exportOffice(CelebrationContext)
        └── CelebrationContext.svgSource   ← set from LiturgyState.psalmSvgSource
              └── loads raw SVG strings into Morning / Vespers office data
                    └── PsalmEntry.svgData: List<String>
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

### Sticky (tab mode, one psalm per tab)

```
PsalmTabWidget (CustomScrollView)
  ├── SliverToBoxAdapter → PsalmDisplayHeader
  ├── SliverPersistentHeader(pinned: true)
  │     └── PsalmToneSliverDelegate(svgData, extent, themeKey)
  │           └── ColoredBox → PsalmToneWidget(svgData)
  └── SliverToBoxAdapter → PsalmDisplayBody
```

The partition scrolls with the psalm header, then pins just below the TabBar while the user reads through the verses. When the next psalm's header scrolls up, it pushes the pinned partition off screen.

---

## Sticky header rebuild trigger

`SliverPersistentHeaderDelegate.shouldRebuild()` controls when the delegate's `build()` is re-invoked. Three conditions trigger a rebuild:

```dart
svgData != oldDelegate.svgData      // different psalm / source reload
|| extent != oldDelegate.extent     // screen width change
|| themeKey != oldDelegate.themeKey // dark/light or serif/sans toggle
```

`themeKey` is a `'${darkTheme}_${serifFont}'` string built in `PsalmTabWidget.build()`, which watches `ThemeNotifier`. Without this field, a theme change would leave the sticky header rendering with stale colours while the rest of the screen updated.

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
| `lib/widgets/…/psalm_tone_sliver_delegate.dart` | `PsalmToneSliverDelegate` — sticky header delegate |
| `lib/widgets/…/psalms_display.dart` | `PsalmDisplayWidget`, `PsalmDisplayHeader`, `PsalmDisplayBody` |
| `lib/widgets/…/office_common_widgets.dart` | `PsalmTabWidget` — chooses sticky vs. non-sticky layout |
| `lib/widgets/…/base_office_view_state.dart` | Owns `_svgSource`, reacts to `LiturgyState` changes |
| `lib/states/liturgyState.dart` | `psalmSvgEnabled`, `psalmSvgSource` with change notifications |
