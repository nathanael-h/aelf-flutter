# Left menu (drawer) header — native Android parity

Porting the aelf-dailyreadings (native Android) drawer headers to the Flutter
app's left menu. The native app swaps the drawer header per section:

- **Bible** → `navigation_drawer_header_bible.xml` (logo mask + "La Bible").
- **Offices / Mass** → `navigation_drawer_header_offices.xml` (AELF logo, day
  title, liturgical time, region spinner, per-office liturgical colour + degree).
- **Other** → the legacy Flutter `DrawerHeader` (AELF round icon + "AELF").

Reference screenshots live in `docs/native-android-screenshots/`.
Native source: `/home/nathanael/src/aelf-dailyreadings`.

---

## Current implementation

### Shared pieces

- **`AelfLectureColors`** theme extension (`lib/utils/theme_provider.dart`):
  the native "lecture" palette (`text`, `background`, `backgroundDarker`),
  registered on both `light` and `dark` `ThemeData`. Values from native
  `colors.xml`:
  - light: bg `#EFE3CE`, darker `#D6CBB8`, text `#5D451A`
  - dark: bg `#1D1E23`, darker `#1D1E23`, text `#F8F7FA`
- **`AelfLiturgicalColors`** theme extension: the liturgical colours from
  native `colors_liturgical.xml` (table below). `resolve(name)` maps both
  French (API) and English (offline) colour names; unknown → transparent.
- **`AelfDrawerHeaderBackground`** (`lib/widgets/aelf_drawer_header_background.dart`):
  radial gradient (native `drawer_header_bg_*.xml`: centre 0.2/0.2, r=300dp)
  and 1dp bottom rule, used by both headers.
- **`smallCapsSpan()`** (`lib/utils/small_caps.dart`): synthesized small caps
  instead of `FontFeature('smcp')`, because only Android's Roboto ships an
  `smcp` table. Elsewhere the title would silently render in plain lower case.

### Section → header (`LeftMenu._header()`, `lib/widgets/left_menu.dart`)

Mirrors native `setDrawerHeaderView`:

| Section | Header | Data source |
|---|---|---|
| `bible` | `LeftMenuHeader` | none ("La Bible" / "Traduction liturgique") |
| `offline_*` (except `offline_calendar`), offline feature **on** | `LeftMenuOfficeHeader` | offline calendar: `LiturgyState.offlineHeaderInfo()` |
| online offices and `messes`, or any office section with the offline feature **off** | `LeftMenuOfficeHeader` | online API: `OfficeHeaderInfo.fromApi(LiturgyState.informationsJson)` |
| everything else | legacy `DrawerHeader` (AELF round icon + "AELF") | none |

`_isMassSection()` only matches the legacy online `messes` section, which has
no offline data source. `offline_mass` ("Messe (nouveau)") is an `offline_*`
section like the others and uses the offline calendar.

### Bible header (`LeftMenuHeader`, `lib/widgets/left_menu_header.dart`)

Tinted logo mask (`assets/icons/ic_logo_bible_mask.png`) bleeding off the left
edge, title/subtitle block in a shared left column. Geometry from the native
layout dp values, cross-checked against `left_menu_dark_bible.png` (header
exactly 160dp). Title in small caps, Roboto `w500`; subtitle Roboto `w300`.
`_singleLine()` (`FittedBox`) shrinks a line only when it doesn't fit, like the
native `autoSizeTextType`.

### Offices / Mass header (`LeftMenuOfficeHeader`, `lib/widgets/left_menu_office_header.dart`)

Port of `navigation_drawer_header_offices.xml`. Text is sized in dp, with text
scaling disabled.

```
┌──────────────────────────────────────────┐
│ DAY TITLE (small caps, autosized, 1 line)│
│ [logo]  ■ degree or season/week (italic) │
│         Année Paire — Semaine II         │
│         region ▾                         │
└──────────────────────────────────────────┘
```

- **Day title** (`_day`): `info.day` in small caps (ratio 0.7), app body font
  `w500`, shrunk to fit one line within `maxHeight` 40dp. Shows "Chargement…"
  / "Erreur" while loading / on error.
- **AELF logo**: `assets/icons/aelf_logo.svg`, recoloured per theme by
  `_AelfLogoColorMapper` (red `#BF252A` → accent, glyph `#000000` → black/grey).
- **Degree line** (`_degree`): `info.degree`, or `info.seasonText` when there
  is no degree, in light italic, wrapping onto a second line if needed. The
  liturgical-colour square sits on its left (hidden when the colour is unknown).
- **Time line**: `OfficeHeaderInfo.timeText` → "Année … — Semaine …".
- **Region row**: online, a `PopupMenuButton` over the 8 regions in native
  order (`onRegionSelected` → `LiturgyState.updateRegion`). Offline,
  `onRegionTap` opens `showLocationSelector()`, the same nested location
  bottom sheet as the settings screen, and `regionLabel` shows the location's
  French name (`LiturgyState.offlineRegionLabel`, cached synchronously).
  Selection goes through `LiturgyState.selectOfflineLocation(id)`, shared with
  the settings screen.

### `OfficeHeaderInfo` (`lib/models/office_header_info.dart`)

Fields: `day`, `degree`, `seasonText`, `colorName`, `liturgicalYear`,
`psalterWeek` (Roman numeral), `region`, `isLoading`, `isError`. All optional;
the widget hides empty rows.

- **`fromApi(informations)`**: reads the epitre.co `informations` block
  (`api.app.epitre.co/82/office/informations/{date}.json`, loaded into
  `LiturgyState.informationsJson` by `_loadInformations()`, DB first then web):
  `liturgical_day`, `liturgical_year`, `psalter_week` (int → Roman), `zone`.
  `liturgy_options` is ignored, so the online header has no degree line and no
  colour square.
- **`fromOfflineDay(...)`**: built by `LiturgyState.offlineHeaderInfo()` from
  primitives it has already resolved (capitalisation and Roman numerals stay in
  the model).
- `fromOffline(CelebrationContext)` is an older, simpler factory that is no
  longer called.

### Offline header content (`LiturgyState.offlineHeaderInfo()`)

The primary celebration comes from `resolvePrimaryCelebration()`: the
celebration currently selected in `SelectedCelebrationState` when it is still
valid for the day and not lower in priority than this office's own default,
otherwise the top celebrable entry. That way the header names what is actually
on screen.

| Day type | `day` (title) | Line under the title |
|---|---|---|
| Named feast | the feast's title | degree from `_offlineDegree(precedence)` ("Solennité", "Fête", "Mémoire obligatoire", "Mémoire facultative") |
| Sunday (title contains "dimanche") | short title, e.g. "Vingt-cinquième Dimanche" | season name from `liturgicalTimeLabels` |
| Plain ferial day (`isPlainFerial`) | French weekday | `ferialSeasonText()`: "25ème semaine du Temps Ordinaire", or the season name alone when it has no numbered weeks |

`isPlainFerial` is true for precedence 13, and also for the privileged
ferials of Lent and Advent 17–24 (precedence 9) when the ferial itself is
celebrated. Ash Wednesday, Holy Week and the octaves keep their own titles.

The colour square uses the primary celebration's `liturgicalColor`. The time
line uses `offlineCalendar.getDayContent(date)`: "Année paire/impaire" (even
year → paire; offline data has no A/B/C Sunday cycle) and the breviary week.

### To do

- **Offices day-title font**: native uses `sans-serif-condensed-medium`; the
  port uses the app's body font in `w500` small caps. Decide whether a
  condensed font is worth bundling.

---

## Native reference values

### Liturgical colours (`colors_liturgical.xml`)

| name    | light      | dark       |
|---------|------------|------------|
| white   | `#FFFFFF`  | `#FFFFFF`  |
| green   | `#319464`  | `#27754F`  |
| red     | `#BF2529`  | `#D7464E`  |
| purple  | `#991E66`  | `#991E66`  |
| pink    | `#EB3FC5`  | `#EB3FC5`  |
| black   | `#050505`  | `#050505`  |
| unknown | `#00000000`| `#00000000`|

### Offices header layout (`navigation_drawer_header_offices.xml`)

- Container: min-height 160dp, padding H 16dp / top 24dp / bottom 16dp, radial
  gradient bg.
- Logo: `?attr/drawableAelfLogo` (69×69dp), `translationX=-8dp`, top-left.
- Day title: right of logo, `marginLeft=2dp`, `marginTop=-8dp`,
  `sans-serif-condensed-medium`, 34sp, autosize 16–34dp, `maxHeight=40dp`,
  `gravity=bottom`.
- Time: below day, `marginTop=-4dp`, `sans-serif-light` 14sp.
- Region spinner: below time, `sans-serif-light` 14sp.
- Liturgical options block: below the logo, `paddingTop=16dp`, vertical,
  `showDividers=middle`. Each entry (`..._liturgical_options_fragment.xml`):
  - 9×9dp colour `View`, `marginTop=6dp`, bg = liturgical colour.
  - Title `TextView`, `marginLeft=8dp`, 14sp.
  - Degree `TextView`, `marginTop=-4dp`, `sans-serif-light` 12sp italic.

### Region list

`kValidOnlineRegions` (`lib/utils/region_sync.dart`): france, belgique,
luxembourg, suisse, canada, monaco, afrique, romain. Offline uses location ids;
the two spellings differ only for `belgique→belgium` and `suisse→switzerland`
(`kOnlineRegionToLocationId`). `inferOnlineRegion()` walks an offline location
up its parent chain to the nearest online region, falling back to `romain`.

### Data source seam

- **Offline**: `CelebrationContext` (offline_liturgy package): `celebrationTitle`,
  `celebrationCode`, `ferialCode`, `precedence`, `liturgicalTime`,
  `breviaryWeek`, `liturgicalColor`; plus `DayContent.liturgicalYear` from the
  offline calendar.
- **API**: the `informations` block: `liturgical_day`, `liturgical_year`,
  `psalter_week`, `zone`.

`OfficeHeaderInfo` normalizes both so `LeftMenuOfficeHeader` stays source-agnostic.
