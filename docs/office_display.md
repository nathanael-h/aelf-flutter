# Office display — general architecture

## Overview

The office display is built on a 4-layer architecture, sitting on top of the celebration-list fetch described in §0:

1. **Data**: the `offline_liturgy` package resolves and exports liturgical content
2. **State**: `BaseOfficeViewState` manages the lifecycle (loading, selection, error)
3. **Main display**: an `XxxOfficeDisplay` widget orchestrates the sections
4. **Common widgets**: reusable blocks (antiphon, psalm, header, text…)

---

## 0. Fetching the celebration list (`LiturgyState` / `liturgy_screen.dart`)

Before any `XxxOfficeDisplay`/`BaseOfficeViewState` widget exists, something has to fetch that day's `Map<String, CelebrationContext>` (or `Map<String, ComplineDefinition>` for Compline) from the `offline_liturgy` package and hand it to the widget. That happens one layer up, outside `BaseOfficeViewState`:

```
LiturgyState.updateLiturgy()
  └─ switch (liturgyType) { case 'offline_mass': ... }
       ├─ getOfflineXxx(date, region)  →  ensures the calendar is built, then
       │    calls Xxx­Detection() from offline_liturgy
       ├─ .then<void>((value) { offlineXxx = value; notifyListeners(); })
       └─ .catchError(onOfflineLoadError)  →  sets offlineLoadError, notifyListeners()

liturgy_screen.dart (Consumer<LiturgyState>)
  └─ case "offline_xxx":
       if (liturgyState.offlineXxx.isEmpty) return _offlineOfficeLoading(...);
       return XxxView(xxxList: liturgyState.offlineXxx, ...);
```

`_offlineOfficeLoading(liturgyState, loadingLabel)` (private to `liturgy_screen.dart`) renders a spinner + `loadingLabel`, or — if `liturgyState.offlineLoadError != null` — an error message (`liturgyLabels['error-office']`) with a retry button (`liturgyLabels['retry']`) that calls `updateLiturgy()` again. `offlineLoadError` is cleared at the start of every `updateLiturgy()` run and set by a shared `onOfflineLoadError` handler attached to each `offline_*` fetch's `.catchError()`.

This layer exists because the `Map.isEmpty` check alone can't distinguish "still fetching" from "fetch failed" — before `.catchError()` was added to these calls, a thrown exception anywhere in the chain (most commonly `LiturgyState._ensureCalendar()`, which used to leave a permanently-rejected `Future` cached after a failed calendar build) left the Map empty forever with the spinner never resolving into either content or a visible error. See `aelf-flutter/docs/mass.md` → "Related fix: Mass could get stuck on 'Loading mass...' forever" for how this was found and fixed.

Once `liturgyState.offlineXxx` is non-empty, control passes to `XxxView` → `BaseOfficeViewState` (§1 below), which has its own separate, narrower error handling for failures in `exportOffice()` (resolving the *content* of the already-known celebration list, as opposed to the celebration list itself).

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

Each section's own `ListView` uses `padding: shrinkWrap ? EdgeInsets.zero : EdgeInsets.symmetric(vertical: 16 * zoom/100)` — no padding at all in scroll mode (only the next section's own `LiturgyPartTitle` top spacing separates two consecutive sections), full page-margin padding in tab mode. This convention is shared by every `_XxxTab` widget (Reading, Canticle, Intercession, Oration, Capitulum, Biblical/Patristic Reading, Te Deum) and by `PsalmTabWidget`.

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

### Mass (`MassOfficeDisplay`)

New office, added on top of the `offline_liturgy` package's Mass pipeline (see `docs/mass.md` for the full data model and pipeline). Follows the same `BaseOfficeViewState`/tab-or-scroll pattern as the others, implemented in `lib/widgets/offline_liturgy_mass_view.dart`.

| Tab | Content |
|---|---|
| Office *(if needed)* | Celebration + common selectors — see note below |
| Ouverture | Header + entrance antiphon + opening prayer (`collect`, hidden if empty). Always its own tab (in both tab and scroll mode) — no longer merged into the first reading-part tab. |
| One tab per reading part | Labelled by position: "Lecture"/"1ère lecture"/"2ème lecture" (`READING`/`EPISTLE`), "Psaume" (`PSALM`/`CANTICLE`), "Évangile" (`GOSPEL`, always unique). Alternative options within one part (e.g. Easter Day's Colossians/1 Corinthians choice) are separated by "ou". Reading/Gospel body text is left-aligned, not justified (`_MassScriptureWidget`, a left-aligned sibling of the shared `ScriptureWidget`, which justifies on purpose for the other offices), and uses a smaller right-indent multiplier for `>` than other offices (see §7). Before the "Évangile" title, the Gospel always shows an "Alléluia" (or "Acclamation de l'Évangile" during `lent`/`holyweek`) heading + `acclamationAntiphon`, plus its own `acclamationAntiphonReference` if present (a second `BiblicalReferenceButton` right under the acclamation text); after the title/reference, `headline` (`_MassHeadlineCommentary`) then the "✝ Évangile de Jésus Christ selon saint X" announcement (`_MassGospelAnnouncement`, shown for both the long form and the forme brève) then the body text. When a forme brève exists: in scroll mode, a "Une forme brève est proposée plus bas" pointer is shown right after the Alléluia block (before the "Évangile" title), and the forme-brève block further down does not repeat the Alléluia (already shown once, just above, in the same continuous scroll); in tab mode, the forme-brève tab is fully self-contained and repeats the same Alléluia text/reference instead. |
| Séquence *(only if `sequence` is non-empty)* | The proper sequence (e.g. Victimae Paschali Laudes), resolved through the same hymn hydration mechanism as any office's `hymn:` field (see `docs/mass.md` → "Hymn/blessing hydration") and rendered via the shared `HymnsTabWidget`. Positioned right before the Gospel tab/block, since the sequence is sung after the second reading and before the Gospel acclamation — rare, only Easter and its Octave and Pentecost. |
| Offrandes *(only if there's something to show)* | `offeringPrayer` (hidden if empty). `prefaceList` is not rendered here — reserved for a separate, dedicated preface display. |
| Communion *(only if there's something to show)* | Communion antiphon → `prayerAfterCommunion` → `prayerOnThePeople` ("Prière sur le peuple", Lenten ferias) → solemn blessing (resolved `solemnBlessingList`), each hidden independently when its data is absent |

The three Mass orations (`collect` in Ouverture, `offeringPrayer` in Offrandes, `prayerAfterCommunion` in Communion) are left-aligned, not justified — the shared `buildOrationWidgets` (`office_common_widgets.dart`) gained an optional `textAlign` parameter (default `TextAlign.justify`, unchanged for every other office) that Mass's three call sites pass as `TextAlign.left`.

No separate "Bénédiction" tab — `prayerOnThePeople` and the solemn blessing are folded into the end of the Communion tab instead (see row above), each conditionally hidden rather than always present.

Coexists with the legacy AELF-web Mass (`"messes"`, `mass_parser.dart`) behind `feature_offline_liturgy` — does not replace it (see `app_sections.dart`: `offline_mass` next to `messes`).

Note: unlike every other office, `massDetection` can yield **several entries for the same day** (e.g. Palm Sunday's procession + Passion Mass, Easter's Vigil + day Mass). No dedicated "choose the Mass" selector was built — each variant is simply exposed as its own entry in the existing `CelebrationChipsSelector`, which already handles picking between several `CelebrationContext`s.

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

- Font: `fontSize: 20 * zoom/100`, `fontWeight: bold`, small-caps (`smcp`), color: `colorScheme.secondary`
- Padding: `top: 24 * zoom/100, bottom: 0` — owns the full spacing above every section title; call sites no longer add their own `SizedBox`/`Padding` before or after a title (removed as redundant duplicates during a spacing cleanup pass)
- Supports an optional `trailing` widget right-aligned on the same baseline (e.g. a reference button)
- `left` (default `LiturgyRowLeft.none`): psalm/canticle titles pass `LiturgyRowLeft.indent` to align with verse text
- Content is parsed through `YamlTextParser` — supports rubrics, italics, and liturgical symbols

### `LiturgyPartContentTitle`

Sub-heading for individual content items within a section (e.g. the title of each biblical or patristic reading).

- Font: `fontSize: 16 * zoom/100`, `fontWeight: bold`, color: `titleMedium.color` (theme — slightly lighter than `LiturgyPartTitle`)
- Padding: `top: 10 * zoom/100, bottom: 2 * zoom/100`
- Supports an optional `trailing` widget (e.g. `BiblicalReferenceButton`)
- `left` (default `LiturgyRowLeft.none`): pass `LiturgyRowLeft.indent` to align with verse text
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

Displays one to three antiphons (or, for canticles, a single antiphon with an explicit marker override). Each antiphon is its own `LiturgyRow`:
- Left column (`LiturgyRowLeft.widget(...)`): an `AntiphonMarkerIcon` — a small SVG glyph standing in for "Ant."/"Ant. 1"/"Ant. 2"/"Ant. 3"/"Année A/B/C", in the same spirit as the ℟/℣ liturgical symbols. The marker is chosen automatically (`single`/`first`/`second`/`third`) from which antiphons are present, or overridden per antiphon via `marker1`/`marker2`/`marker3` (used by canticles for `yearA`/`yearB`/`yearC`)
- Content column: `YamlTextWidget` — `fontSize: 13 * zoom/100`, `paragraphSpacing: 4 * zoom/100`

Inter-antiphon spacing: `top: 3 * zoom/100` on antiphons 2 and 3.

`AntiphonWidget` is self-contained (builds its own `LiturgyRow`(s) internally) — callers place it directly, with no external `LiturgyRow` wrapper.

### `AntiphonMarkerIcon`

`lib/widgets/offline_liturgy_common_widgets/antiphon_marker_icon.dart`. Loads the raw SVG matching an `AntiphonMarker` value (`antiphon`/`antiphon1`/`antiphon2`/`antiphon3`/`antiphonA`/`antiphonB`/`antiphonC.svg`, cached by asset name after first load), runs it through `preprocessPsalmSvg()` — the same colour pipeline as psalm-tone scores, see §8 — and renders it via `SvgPicture.string` at a fixed height (`14 * zoom/100`), width following the SVG's own aspect ratio.

Placed via `LiturgyRowLeft.widget(...)`, which top-aligns its content with the first line of the row (rather than centering across the full height of a multi-line antiphon) — `LiturgyRow`'s inner `Row` uses `crossAxisAlignment: CrossAxisAlignment.start` for this reason.

Raw assets live in `assets/svg/antiphon*.svg`, registered as their own `assets/svg/` entry in `pubspec.yaml` (Flutter does not bundle subdirectories recursively from a parent `assets/` entry).

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
            ├─ left column  (controlled by LiturgyRowLeft)
            ├─ Expanded → Padding → builder(context, zoom)
            └─ Padding(right: 15, bottom: 10)   (fixed right gutter)
```

**Left column — `LiturgyRowLeft`** (sealed class, default `LiturgyRowLeft.indent`)

Three exclusive states:

| Value | Effect | Width |
|---|---|---|
| `LiturgyRowLeft.indent` | Invisible spacer — content aligned with psalm verse text | `10 + verseFontSize × zoom/100` (≈ 26 px at zoom 100) |
| `LiturgyRowLeft.none` | No left column — content starts at the left edge | — |
| `LiturgyRowLeft.widget(w)` | Custom widget, top-aligned in the column (e.g. coloured bullet, antiphon marker) | same as `indent` |

`indent` keeps prose content horizontally aligned with psalm body text. `none` is used when the content widget manages its own left layout (e.g. `YamlTextFromString` with `useSymbolColumn: true`, which renders ℟/℣/* in its own column of the same width).

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
- **Without SVG**: `ListView` with `PsalmDisplayWidget`. In scroll mode (`shrinkWrap: true`) the `ListView` has no padding at all (`EdgeInsets.zero`); in tab mode it keeps `EdgeInsets.symmetric(vertical: 16 * zoom/100)` as page margin
- **With SVG**: `CustomScrollView` with `SliverPersistentHeader` (pinned) containing `PsalmToneWidget`, framed by `PsalmDisplayHeader` and `PsalmDisplayBody`

In scroll mode, consecutive psalms in the Psalmodie section get an extra `SizedBox(height: 18 * zoom/100)` before the 2nd, 3rd… psalm (not before the first, which already follows the "Psalmodie" title's own spacing) — see the indexed loop in each office view's `_buildScrollView`.

### `BiblicalReferenceButton`

Compact `TextButton.icon` (`tapTargetSize: shrinkWrap`, `minimumSize: zero`, `padding: horizontal 4 px`) so it adds no vertical gap when placed on its own line.

### `HymnsTabWidget` → `HymnSelectorWithTitle`

If multiple hymns: `DropdownButton` selector + title + author + `HymnContentDisplay`. If only one: direct display. `HymnContentDisplay` uses `paragraphSpacing: 15 * zoomValue/100`. `HymnsTabWidget` takes an optional `title` (default: `liturgyLabels['hymns']`/"Hymnes") — Mass's "Séquence" tab passes `title: 'Séquence'` to reuse this same selector/display for non-hymn code-referenced content (see `docs/mass.md`).

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
| `>line`, `>>line`… | Right indent, chainable (`YamlTextLine.indentLevel`, an int counting leading `>`); indent = fontSize × `rightIndentMultiplier` × indentLevel |
| `R/`, `V/` | Converted to ℟ / ℣ (red, bold) |
| `+`, `*` | Liturgical symbols (red, bold) |
| `'` | Typographic apostrophe ' |
| ` :` ` ;` ` !` ` ?` | Narrow non-breaking space before punctuation |

### `YamlTextWidget`

Renders a `List<YamlTextParagraph>` as a `Column`. Each paragraph is wrapped in `Padding(bottom: paragraphSpacing)`, **except the last one** — no trailing space is added after the final paragraph (it used to leave an invisible gap before whatever section followed).

Key parameters:
- `paragraphSpacing`: default 12 px (not zoomed inside `YamlTextWidget` itself)
- `textStyle`: provided by the caller, typically `fontSize: 16 * zoom/100, height: 1.2`
- `textAlign`: left or justified depending on context
- `rightIndentMultiplier`: default `1.5` (unchanged rendering for every caller that doesn't pass it); Mass's body-text widgets pass `0.75` for a tighter right indent — see `docs/mass.md`

### `YamlTextFromString`

Wrapper with parse cache (`didUpdateWidget` re-parses if content changes). Scales automatically via `context.watch<CurrentZoom>()`: `fontSize: 16 * zoom/100` and `paragraphSpacing: widget.paragraphSpacing * zoom/100` (default 12 × zoom/100).

---

## 8. SVG psalm tone

### `PsalmToneWidget`

Displays one or more psalm tone SVG scores, aligned like any other piece of prose content via `LiturgyRow(left: LiturgyRowLeft.indent)` — the left column stays empty (aligned with verse text), the score renders in the content column, left-aligned.

- The SVG is pre-processed by `preprocessPsalmSvg`: injection of text colour (according to theme), font (serif or not), and liturgical red colour
- Scale × 1 (`_svgScale`) relative to the natural SVG width, clamped to `screenWidth - liturgyRowIndentWidth(zoom) - 15` — the width actually available inside the `LiturgyRow`'s content column (`liturgyRowIndentWidth()`, in `lib/widgets/liturgy_row.dart`, is the same indent-width formula `LiturgyRow` and `verseIdPlaceholder` use)
- **1 SVG**: `SvgPicture.string` left-aligned inside the row, `Padding(vertical: 12)` (no horizontal padding — the `LiturgyRow` indent + fixed right gutter replace it)
- **N SVGs**: horizontal `PageView` fixed height 160 px + `SizedBox(8)` + animated dots indicator, same `LiturgyRow` wrapping

### Sticky mode (tab) — `PsalmToneSliverDelegate`

`PsalmToneSliverDelegate` is a `SliverPersistentHeaderDelegate` with fixed height (`minExtent == maxExtent`). Height is computed by `psalmToneSliverExtent(svgData, screenWidth, zoom)` from the SVG `width`/`height` attributes, using the same `liturgyRowIndentWidth(zoom)`-based available width as `PsalmToneWidget` (so the precomputed pinned-header height always matches what actually renders):
- 1 SVG: `targetWidth × (naturalHeight / naturalWidth) + 24`, `targetWidth = naturalWidth × 1.2 (_stickyScale)` clamped to the available width
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
| `AntiphonMarkerIcon` | SVG glyph ("Ant."/"Ant. 1"/"Année A"…) in the left column | 14 px height | — | `secondary` (letter + stroke) | ✓ |
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
| Verse numbers | `colorScheme.secondary` |
| Commentary left border | `colorScheme.secondary` |
| Tab bar background | `primaryColor` |
| Active tab indicator + label | `tabBarTheme.labelColor ?? colorScheme.secondary` |
| Inactive tab label | same at 70% opacity |
| Liturgical colour bar | `getLiturgicalColor()` — 6 px fixed height, radius 3 |
| Description box border | `dividerColor`, radius 12 |
| Long-press hint (forced feast) | `colorScheme.secondary` |
| Antiphon marker (SVG glyph + diagonal stroke) | `colorScheme.secondary`, via `preprocessPsalmSvg()` |

### Spacing conventions

**Horizontal paddings** — fixed 16 px everywhere, not scaled. Exception: `OfficeSectionTitle` still uses `16 * zoom/100` horizontally.

**Vertical spacings** — all zoom-scaled (`SizedBox(height: h * zoom/100)`):

| Location | Value at zoom 100 |
|---|---|
| Between an antiphon and the next (2nd/3rd) | 3 px |
| `YamlTextWidget` default paragraph spacing | 12 px |
| Hymn paragraph spacing (`HymnContentDisplay`) | 15 px |
| Antiphon block → psalm body gap | 12 px |
| Psalm body → closing antiphon gap | 20 px |
| Between antiphons in canticle | 12 px |
| `LiturgyPartTitle` top / bottom padding | 24 / 0 px |
| `LiturgyPartContentTitle` top / bottom | 10 / 2 px |
| `LiturgyPartCommentary` left border padding | 8 px (fixed) |
| Psalm title top padding — scroll mode | 4 px |
| `ScriptureWidget` title → text gap | 6 px (default) |
| `PsalmTabWidget` / `_XxxTab` ListView padding — scroll mode | 0 px (`EdgeInsets.zero`, both top and bottom) |
| Psalm-to-psalm gap in Psalmodie (scroll mode, before 2nd/3rd… psalm) | 18 px |
| `AntiphonMarkerIcon` height | 14 px |

**Chip spacing** — `spacing: 8 * zoom/100, runSpacing: 8 * zoom/100`.

**Notre Père (`ExpansionTile`)** — Morning and Vespers intercession (Compline: Confiteor). Wrapped in `Theme(data: theme.copyWith(dividerColor: Colors.transparent))` to suppress the default top/bottom dividers, and set `minTileHeight: 0` — otherwise Material's default one-line `ListTile` height floor (56 px) pads the collapsed header row regardless of the title's own natural height.
