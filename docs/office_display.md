# Office display — general architecture

## Overview

The office display is built on a 4-layer architecture:

1. **Data**: the `offline_liturgy` package resolves and exports liturgical content
2. **State**: `BaseOfficeViewState` manages the lifecycle (loading, selection, error)
3. **Main display**: an `XxxOfficeDisplay` widget orchestrates the sections
4. **Common widgets**: reusable blocks (antiphon, psalm, header, text…)

---

## 1. Lifecycle and loading (`BaseOfficeViewState`)

`BaseOfficeViewState<W, T>` is the abstract class shared by Morning (Lauds), Vespers, Readings, and Middle of Day. Compline has its own simplified state.

### Loading sequence

```
initState()
  └─ _loadOffice()
       ├─ Finds the first "celebrable" celebration in celebrationList
       ├─ Consults SelectedCelebrationState to honour a pre-existing global choice
       │   (only if that celebration has a priority ≤ the first option)
       ├─ Reads imprecatory verses (getImprecatoryVerses)
       ├─ Resolves the default common (first in list, or global choice if compatible)
       ├─ Calls exportOffice(CelebrationContext) → Future<T>
       └─ setState() → buildOfficeDisplay(...)
```

### Reload triggers

| Event | Method |
|---|---|
| Date or list change | `didUpdateWidget` → `_loadOffice` |
| Psalm tone SVG source change | listener on `LiturgyState` → `_loadOffice` |
| User selects another celebration | `_onCelebrationChanged` |
| User selects another common | `_onCommonChanged` |
| Long press → precedence override | `_onPrecedenceOverridden` → `_onCelebrationChanged` + shake animation |

### Shake animation

On a precedence override (forcing a feast or solemnity), a `TweenSequence` translates the display horizontally (±6 px, 500 ms) to visually signal the change.

---

## 2. Display modes: tabs vs scroll

Each office can be displayed in two modes controlled by `LiturgyState.useScrollMode`:

### Tab mode (default)
```
DefaultTabController
  ├─ LiturgyTabBar           ← coloured tab bar
  └─ PinchZoomSelectionArea
       └─ TabBarView          ← each section in its own scrollable widget
```
Each tab contains an independent `ListView`. Content is not loaded until the tab is visited.

### Scroll mode
```
PinchZoomSelectionArea
  └─ CustomScrollView (or SingleChildScrollView)
       ├─ SliverToBoxAdapter (section 1)
       ├─ SliverToBoxAdapter (section 2)
       …
```
All sections are instantiated immediately with `shrinkWrap: true` + `NeverScrollableScrollPhysics`. Psalms with SVG use `SliverStickyHeader` to pin the tone during scrolling. **No `Divider` is placed between sections** — sections flow continuously without horizontal separators.

---

## 3. Office structure

### Morning Prayer / Lauds (`MorningOfficeDisplay`)

| Tab | Content |
|---|---|
| Office *(if needed)* | Celebration + common selectors |
| Introduction | Header + introduction text + invitatory (selectable psalm) |
| Hymns | Hymn selector |
| Psalmodie *(scroll only)* | `LiturgyPartTitle` heading, key `psalmody` |
| Psalm 1…N | One psalm per tab |
| Capitulum | Short reading + responsory |
| Benedictus | Evangelical canticle with antiphons |
| Intercession | Text + Pater Noster (expandable) |
| Oration | Oration(s) + blessing |

The invitatory has a chip-based psalm selector (multi-psalm case). The selected psalm index is managed by `_MorningOfficeDisplayState` and shared between tab mode and scroll mode: switching between modes preserves the current selection. In scroll mode, the selected psalm follows immediately with an optional sticky SVG tone.

### Vespers (`VespersOfficeDisplay`)

| Tab | Content |
|---|---|
| Office *(if needed)* | Celebration + common selectors |
| Introduction | Header + introduction text |
| Hymns | Hymn selector |
| Psalmodie *(scroll only)* | `LiturgyPartTitle` heading, key `psalmody` |
| Psalm 1…N | One psalm per tab |
| Reading | Short reading + responsory |
| Magnificat | Evangelical canticle with antiphons |
| Intercession | Text + Pater Noster (expandable) |
| Oration | Oration(s) + blessing |

Same structure as Morning Prayer, without the invitatory.

### Readings (`ReadingsOfficeDisplay`)

| Tab | Content |
|---|---|
| Office *(if needed)* | Celebration + common selectors |
| Introduction | Header + introduction text |
| Hymns | Hymn selector |
| Psalmodie *(scroll only)* | `LiturgyPartTitle` heading, key `psalmody` — always shown |
| Psalm 1…N | One psalm per tab (if any) |
| Biblical reading | Title + subtitle + content + responsory |
| Patristic reading | Title + subtitle + content + responsory |
| Te Deum | Text (conditional) |
| Oration | Oration(s) + blessing |

### Compline (`ComplineOfficeDisplay`)

Compline does not inherit from `BaseOfficeViewState`. Its own state (`_ComplineViewState`) manages:
- Compline type selection (Sunday, ferial…) via chips
- Loading via `complineExport()`
- `getImprecatoryVerses()` for imprecatory verses

| Tab | Content |
|---|---|
| Office *(if > 1 type)* | Compline type selector |
| Introduction | Header + optional commentary + Confiteor (expandable) |
| Hymns | Hymn selector |
| Psalmodie *(scroll only)* | `LiturgyPartTitle` heading, key `psalmody` |
| Psalm 1…N | One psalm per tab |
| Reading | Short reading + responsory |
| Canticle of Simeon | Canticle with antiphons |
| Oration | Oration(s) + conclusion |
| Marian hymns | Marian hymn selector |

During loading, a 2 px `LinearProgressIndicator` is displayed at the top via a `Stack`.

### Middle of Day — Terce / Sext / None (`MiddleOfDayOfficeView`)

A single generic `MiddleOfDayOfficeView` widget serves all three little hours. Selectors passed as parameters (`hymnSelector`, `hourOfficeSelector`, `psalmodySelector`) extract the relevant part of `MiddleOfDay`.

| Tab | Content |
|---|---|
| Office *(if needed)* | Celebration + common selectors |
| Introduction | Header + introduction text |
| Hymn | Hymn selector |
| Psalmodie *(scroll only)* | `LiturgyPartTitle` heading, key `psalmody` |
| Psalm 1…N | One psalm per tab |
| Capitulum | Short reading + responsory + oration + short blessing |

---

## 4. Office tab — celebration selection

The Office tab appears only if at least one of the following is true:
- There are multiple celebrable celebrations (`isCelebrable`)
- The feast requires a common AND there are multiple commons available (or precedence > 8)

Exceptions: Paschal and Christmas octaves — no common selection even if one exists.

### `CelebrationChipsSelector`

Each celebration displayed as a `ChoiceChip` coloured by liturgical colour. Feasts (precedence 5–11, except the Virgin Mary memory) support long press:
- Normal → Forced feast (precedence 8)
- Feast/Memory → Forced solemnity (precedence 4)
- Solemnity → back to normal

Differentiated haptic feedback (light/medium/heavy) accompanies each level.

Non-celebrable celebrations are displayed in italics in a separate section.

### `CommonChipsSelector`

If only one common is available (with no "no common" option), it is displayed as plain informational text. Otherwise, selection chips with a "No common" option if precedence > 8.

---

## 5. Title and text style widgets

### `LiturgyPartTitle`

Main section heading, used for all major parts within a tab (Introduction, Invitatory, Biblical Reading, Responsory, Oration, Blessing, Te Deum, etc.).

- Font: `fontSize: 18 * zoom/100`, `fontWeight: bold`, color: `headlineSmall.color` (theme)
- Padding: `top: 10 * zoom/100`
- Supports an optional `trailing` widget right-aligned on the same baseline (e.g. a reference button)
- Content is parsed through `YamlTextParser` — supports rubrics, italics, and liturgical symbols

### `LiturgyPartContentTitle`

Sub-heading for individual content items within a section (e.g. the title of each biblical or patristic reading).

- Font: `fontSize: 16 * zoom/100`, `fontWeight: bold`, color: `titleMedium.color` (theme — slightly lighter than `LiturgyPartTitle`)
- Padding: `top: 10 * zoom/100, bottom: 2 * zoom/100`
- Supports an optional `trailing` widget (e.g. `BiblicalReferenceButton`)
- Content is also parsed through `YamlTextParser`

### `OfficeSectionTitle`

Label for selector groups within the Office tab ("Select celebration", "Select common").

- Font: `fontSize: 15 * zoom/100`, `fontWeight: w600`
- Padding: `horizontal: 16 * zoom/100, vertical: 8 * zoom/100`
- Uses `Consumer<CurrentZoom>` internally

### `LiturgyTabBar`

Scrollable tab bar displayed at the top of tab mode.

- Background: `theme.primaryColor`
- Active tab indicator and label: `tabBarTheme.labelColor ?? colorScheme.secondary`
- Inactive label: `tabBarTheme.unselectedLabelColor ?? colorScheme.secondary` at 70% opacity

### Summary

| Widget | Use case | Font size | Weight | Color token |
|---|---|---|---|---|
| `LiturgyPartTitle` | Section heading | 18 × zoom/100 | bold | `headlineSmall` |
| `LiturgyPartContentTitle` | Reading / item title | 16 × zoom/100 | bold | `titleMedium` |
| `OfficeSectionTitle` | Selector label | 15 × zoom/100 | w600 | default |

---

## 6. Common widgets

### `OfficeHeaderDisplay`

Displayed first in each Introduction tab. Contains in order:
1. Office title (`officeDescription`) — `fontSize: 20 * zoom/100`, bold, small-caps (`smcp`), centred
2. Liturgical colour bar — fixed height 6 px, radius 3
3. Additional info (`additionalInfo` = liturgical year + week) — `fontSize: 12 * zoom/100`, italic, right-aligned; otherwise empty space
4. Rank label (`typeLabel`, e.g. "Obligatory memorial") — `fontSize: 14 * zoom/100`, italic, centred
5. Description box (`celebrationDescription`) — text in a bordered container, `fontSize: 14 * zoom/100`

All vertical spacings are proportional to zoom.

### `AntiphonWidget`

Displays one to three antiphons. Each antiphon is a `Row`:
- Coloured label ("Ant.", "Ant. 1"…) — `fontSize: 13 * zoom/100`, secondary colour
- Text via `YamlTextWidget` — `fontSize: 13 * zoom/100`, `paragraphSpacing: 4 * zoom/100`

Inter-antiphon spacing: `top: 3 * zoom/100` on antiphons 2 and 3.
Effective total spacing between two antiphons = **4 + 3 = 7 px** at zoom 100.

### `PsalmDisplayWidget` / `PsalmDisplayHeader` + `PsalmDisplayBody`

Both `PsalmDisplayWidget` and `PsalmDisplayHeader` accept `isScrollMode` (default `false`) which changes the title rendering:

- **Tab mode** (`isScrollMode: false`): title rendered with `LiturgyPartTitle` (size 20, `secondary`, small-caps, bold)
- **Scroll mode** (`isScrollMode: true`): compact title — 8×8 px `secondary` square at left + 16 bold text, `top: 4 * zoom/100`

Structure of a psalm:
```
Title                              ← LiturgyPartTitle (tab) or square + text (scroll)
  [Biblical reference, right-aligned, own line — if present]
Subtitle (optional)
Commentary (optional) + SizedBox(12 * zoom/100)
SizedBox(12 * zoom/100)
Opening antiphon (optional) + SizedBox(12 * zoom/100)
[SVG psalm tone - if non-sticky mode]
Psalm text (PsalmFromMarkdown)
SizedBox(20 * zoom/100)
Closing antiphon (optional)
SizedBox(12 * zoom/100)
Verse after (optional)
```

`PsalmDisplayHeader` + `PsalmDisplayBody` are the split versions for sticky SVG mode (sliver), used when `svgData` is present in tab or scroll mode.

### `CanticleWidget` / `CanticleHeader` + `CanticleBody`

Evangelical canticle (Benedictus, Magnificat, Nunc Dimittis). Same header/body split logic as psalms. Antiphons are in `Map<String, List<String>>`: the key can be `'antiphon'` (single), `'A'`/`'B'`/`'C'` (by liturgical year), or an index for multiple antiphons.

Title rendered with `LiturgyPartTitle`. Biblical reference on its own line, right-aligned, below the title. `shortReference` (AT/NT) is not displayed.

### `LiturgyRow`

Reusable layout wrapper used for all prose liturgical content (introductory texts, responsories, antiphons, intercessions, blessings, etc.).

**Structure**

```
Row
  └─ Expanded
       └─ Row
            ├─ verseIdPlaceholder  (optional, left)
            ├─ Expanded → Padding → builder(context, zoom)
            └─ Padding(right: 15, bottom: 10)   (fixed right gutter)
```

**Left placeholder — `verseIdPlaceholder`**

An invisible `Container` whose width mirrors the verse-number column used in psalm text:

```
width = 5 + 5 + (verseFontSize × zoom / 100)
      = 10 + (16 × zoom/100)   →  26 px at zoom 100
```

This keeps all prose content horizontally aligned with psalm body text, even when no verse number is shown. The width scales with zoom, tracking the verse number font size exactly.

**`hideVerseIdPlaceholder`** (default `false`)

- `false`: left space is reserved but empty → content is indented, aligned with psalm verses
- `true`: no placeholder → content is flush with the left edge (full-width layout)

**`builder` callback**

`builder(BuildContext context, double? zoom)` — the zoom value is extracted once by `LiturgyRow`'s own `Consumer<CurrentZoom>` and passed directly, so callers never need a nested `Consumer`.

**`padding`** — optional `EdgeInsets` applied around the builder output inside the `Expanded`. Defaults to `EdgeInsets.zero`.

### `ScriptureWidget`

Displays a short reading: title + reference + justified text.

- Title: `LiturgyPartTitle`
- Biblical reference: own line, right-aligned (`Align(centerRight)`) below the title
- Spacing between title block and text: `spacing ?? 6 * zoom/100`

### `PsalmTabWidget`

Wrapper in tab mode for a psalm. Two paths:
- **Without SVG**: `ListView` with `PsalmDisplayWidget`. In scroll mode (`shrinkWrap: true`), the `ListView` top padding is 0 (bottom only: `16 * zoom/100`)
- **With SVG**: `CustomScrollView` with `SliverPersistentHeader` (pinned) containing `PsalmToneWidget`, framed by `PsalmDisplayHeader` and `PsalmDisplayBody`

### `BiblicalReferenceButton`

Compact `TextButton.icon` (`tapTargetSize: shrinkWrap`, `minimumSize: zero`, `padding: horizontal 4 px`) so it adds no vertical gap when placed on its own line.

### `HymnsTabWidget` → `HymnSelectorWithTitle`

If multiple hymns: `DropdownButton` selector + title + author + `HymnContentDisplay`. If only one: direct display. `HymnContentDisplay` uses `paragraphSpacing: 15 * zoomValue/100`.

---

## 7. Liturgical text rendering

### `YamlTextParser`

Parses a YAML string into `List<YamlTextParagraph>`. A paragraph = block separated by a blank line (`\n\n`). Each paragraph contains lines, each line contains typed segments.

Supported syntax:

| Marker | Effect |
|---|---|
| `%text%` | Italic |
| `§R…§E` | Rubric (red text, -3 px size, italic) |
| `^word` | Superscript (offset -(fontSize × 0.45), size × 0.65) |
| `>line` | Right indent (indent = fontSize × 1.5) |
| `R/`, `V/` | Converted to ℟ / ℣ (red, bold) |
| `+`, `*` | Liturgical symbols (red, bold) |
| `'` | Typographic apostrophe ' |
| ` :` ` ;` ` !` ` ?` | Narrow non-breaking space before punctuation |

### `YamlTextWidget`

Renders a `List<YamlTextParagraph>` as a `Column`. Each paragraph is wrapped in `Padding(bottom: paragraphSpacing)` — **including the last one**, which creates trailing space below the widget.

Key parameters:
- `paragraphSpacing`: default 12 px (not zoomed inside `YamlTextWidget` itself)
- `textStyle`: provided by the caller, typically `fontSize: 16 * zoom/100, height: 1.2`
- `textAlign`: left or justified depending on context

### `YamlTextFromString`

Wrapper with parse cache (`didUpdateWidget` re-parses if content changes). Scales automatically via `context.watch<CurrentZoom>()`: `fontSize: 16 * zoom/100` and `paragraphSpacing: widget.paragraphSpacing * zoom/100` (default 12 × zoom/100).

---

## 8. SVG psalm tone

### `PsalmToneWidget`

Displays one or more psalm tone SVG scores.

- The SVG is pre-processed by `preprocessPsalmSvg`: injection of text colour (according to theme), font (serif or not), and liturgical red colour
- Scale × 1.2 (`_svgScale`) relative to the natural SVG width, clamped to `screenWidth - 20`
- **1 SVG**: `SvgPicture.string` left-aligned, `Padding(vertical: 12, horizontal: 10)`
- **N SVGs**: horizontal `PageView` fixed height 160 px + `SizedBox(8)` + animated dots indicator

### Sticky mode (tab) — `PsalmToneSliverDelegate`

`PsalmToneSliverDelegate` is a `SliverPersistentHeaderDelegate` with fixed height (`minExtent == maxExtent`). Height is computed by `psalmToneSliverExtent()` from the SVG `width`/`height` attributes:
- 1 SVG: `targetWidth × (naturalHeight / naturalWidth) + 24`
- N SVGs: `202 + 24 = 226 px`

A `HapticFeedback.lightImpact()` is triggered when the sliver enters pinned mode (`overlapsContent` switches to `true`).

### Sticky mode (scroll) — `SliverStickyHeader`

Provided by the `flutter_sticky_header` package. The tone is placed in the `header` (sticky) and the psalm body in the `sliver`. The next psalm pushes the tone off screen when it arrives.

---

## 9. Zoom system

### `CurrentZoom`

`ChangeNotifier` persisted via `SharedPreferences` (key `keyCurrentZoom`).

- Range: 60–300 (default: 100)
- Loaded at startup, immediately clamped

### Consuming zoom in widgets

The uniform pattern across all office widgets is `context.watch`:

```dart
final zoom = context.watch<CurrentZoom>().value;
```

`OfficeSectionTitle` is the only exception — it uses `Consumer<CurrentZoom>` internally.

### Zoom application convention

- **Font sizes**: `fontSize: baseSize * zoom / 100`
- **Vertical spacings**: `SizedBox(height: h * zoom / 100)`, `EdgeInsets.only(top/bottom: v * zoom / 100)`
- **Chip spacings**: `spacing: 8 * zoom / 100, runSpacing: 8 * zoom / 100`
- **Paragraph padding**: `paragraphSpacing: baseSpacing * zoom / 100`
- **Horizontal paddings**: not scaled (fixed screen margin, independent of text size)

### Pinch-to-zoom — `PinchZoomSelectionArea`

`GestureDetector` wrapper that captures `onScaleStart`/`onScaleUpdate`/`onScaleEnd` and calls `CurrentZoom.updateZoom(zoomBeforePinch × scale)`. Combines `SelectionArea` to allow text selection.

---

## 10. Relevant global state

| Provider | Role |
|---|---|
| `CurrentZoom` | Text zoom level (60–300) |
| `LiturgyState` | Scroll/tab mode, SVG tone source, imprecatory verses |
| `SelectedCelebrationState` | Current celebration, current common, precedence overrides by key |
| `ThemeNotifier` | Dark/light theme, serif font — influences SVG pre-processing |

`SelectedCelebrationState` is shared across offices for the same day: when the user selects a celebration at Morning Prayer, the same key is proposed by default at Vespers (subject to compatible priority).

---

## 11. Style reference

### Typography

| Widget | Role | Base size | Weight | Color token | Zoom-scaled |
|---|---|---|---|---|---|
| `LiturgyPartTitle` | Section heading (Introduction, Oration…) + psalm/canticle/scripture titles | 20 | bold, small-caps (`smcp`) | `secondary` | ✓ |
| Psalm title — scroll mode | Square 8×8 + bold text (scroll only) | 16 | bold | square: `secondary`, text: `titleMedium` | ✓ |
| `LiturgyPartContentTitle` | Item title (reading) | 16 | bold | `titleMedium` | ✓ |
| `LiturgyPartSubtitle` | Psalm subtitle | 16, italic | w500 | `bodyMedium` | ✓ |
| `LiturgyPartCommentary` | Psalm commentary | 12, italic | w500 | `bodyMedium` | ✓ |
| `OfficeSectionTitle` | Selector label (Office tab) | 15 | w600 | default | ✓ |
| `OfficeHeaderDisplay` — title | Feast name | 20, centred, small-caps (`smcp`) | bold | `bodyMedium` | ✓ |
| `OfficeHeaderDisplay` — additionalInfo | Liturgical year + breviary week | 12, italic, right | normal | `bodySmall` | ✓ |
| `OfficeHeaderDisplay` — typeLabel | Liturgical rank | 14, italic, centred | normal | `bodySmall` | ✓ |
| `OfficeHeaderDisplay` — description box | Hagiographic text | 14, h=1.4, justified | normal | `bodyMedium` | ✓ |
| `AntiphonWidget` — label | "Ant." / "Ant. 1" | 13, h=1.2 | normal | `secondary` | ✓ |
| `AntiphonWidget` — text | Antiphon body | 13, h=1.2 | normal | default | ✓ |
| `PsalmFromMarkdown` — verses | Psalm text | 16, h=1.2 | normal | default | ✓ |
| `PsalmFromMarkdown` — numbers | Verse numbers | 10 | normal | `secondary` | ✓ |
| `HymnSelectorWithTitle` — title | Hymn title (single hymn only) | 14 | bold | default | ✓ |
| `HymnSelectorWithTitle` — dropdown closed | Selected hymn title (`selectedItemBuilder`) | 14 | bold | default | ✓ |
| `HymnSelectorWithTitle` — dropdown open | Hymn titles in open list (`items`) | 12 | normal | default | ✓ |
| `HymnSelectorWithTitle` — author | Hymn author (italic, both cases) | 10 | italic | `bodySmall` | ✓ |
| `HymnContentDisplay` | Hymn body | 16, h=1.3 | normal | `bodyMedium` | ✓ |
| `CelebrationChipsSelector` chip | Celebration chip | 12 | normal | computed from liturgical colour | ✓ |
| `CommonChipsSelector` chip | Common chip | 12 | normal | default | ✓ |
| `CommonChipsSelector` — single text | Informational common | `bodyMedium` | — | `bodyMedium`, italic | via theme |

All text goes through `YamlTextParser` (rubrics, italics, liturgical symbols).

`OfflineLiturgyPartContentTitle` and `OfflineLiturgyPartSubtitle` are offline-only copies of the homonymous shared widgets (without the `Offline` prefix), located in `offline_liturgy_common_widgets/`. The online version (`LiturgyPartColumn`) still uses the originals in `lib/widgets/`. Modify the `Offline*` versions freely without risk of regression on the online display.

`OfflineLiturgyPartContentTitle` is no longer used for psalm titles, canticle titles, or scripture titles — all three now use `LiturgyPartTitle` directly. It remains in use for readings section titles (`ReadingsOfficeDisplay`).

### Colour tokens

| Element | Token |
|---|---|
| `LiturgyPartTitle` text | `colorScheme.secondary` |
| Liturgical symbols ℟ ℣ * + | `colorScheme.secondary` |
| Rubrics `§R…§E` | `colorScheme.secondary` |
| Antiphon label | `colorScheme.secondary` |
| Verse numbers | `colorScheme.secondary` |
| Commentary left border | `colorScheme.secondary` |
| Tab bar background | `primaryColor` |
| Active tab indicator + label | `tabBarTheme.labelColor ?? colorScheme.secondary` |
| Inactive tab label | same at 70% opacity |
| Liturgical colour bar | `getLiturgicalColor()` — 6 px fixed height, radius 3 |
| Description box border | `dividerColor`, radius 12 |
| Long-press hint (forced feast) | `colorScheme.error` |

### Spacing conventions

**Horizontal paddings** — fixed 16 px everywhere, not scaled. Exception: `OfficeSectionTitle` still uses `16 * zoom/100` horizontally.

**Vertical spacings** — all zoom-scaled (`SizedBox(height: h * zoom/100)`):

| Location | Value at zoom 100 |
|---|---|
| Between antiphon label and next antiphon | 3 px |
| `YamlTextWidget` default paragraph spacing | 12 px |
| Hymn paragraph spacing (`HymnContentDisplay`) | 15 px |
| Antiphon block → psalm body gap | 12 px |
| Psalm body → closing antiphon gap | 20 px |
| Between antiphons in canticle | 12 px |
| `LiturgyPartTitle` top padding | 10 px |
| `LiturgyPartContentTitle` top / bottom | 10 / 2 px |
| `LiturgyPartCommentary` left border padding | 8 px (fixed) |
| Psalm title top padding — scroll mode | 4 px |
| `ScriptureWidget` title → text gap | 6 px (default) |
| `PsalmTabWidget` ListView top padding — scroll mode | 0 px (bottom only: 16 px) |

**Chip spacing** — `spacing: 8 * zoom/100, runSpacing: 8 * zoom/100`.

**Notre Père (`ExpansionTile`)** — Morning and Vespers intercession. Wrapped in `Theme(data: theme.copyWith(dividerColor: Colors.transparent))` to suppress the default top/bottom dividers.
