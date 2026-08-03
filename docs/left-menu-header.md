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

## Status

### Done

- **`AelfLectureColors` theme extension** (`lib/utils/theme_provider.dart`) —
  the native "lecture" palette (`colorLectureText`, `colorLectureBackground`,
  `colorLectureBackgroundDarker`). Registered on both `light` and `dark`
  `ThemeData` via `extensions:`. Values verified against native `colors.xml`:
  - light: bg `#EFE3CE`, darker `#D6CBB8`, text `#5D451A`
  - dark:  bg `#1D1E23`, darker `#1D1E23`, text `#F8F7FA`
- **`LeftMenuHeader`** (`lib/widgets/left_menu_header.dart`) — the Bible header.
  - Radial gradient bg (native `drawer_header_bg_*.xml`: centre 0.2/0.2,
    r=300dp), tinted logo mask bleeding off the left edge, title/subtitle block
    in a shared left column, 1dp bottom rule.
  - Geometry taken from the native layout dp values and cross-checked against
    `left_menu_dark_bible.png` (density 3.0, header exactly 160dp).
  - **Small caps** synthesized (`_smallCaps`) instead of `FontFeature('smcp')`,
    because only Android's Roboto ships an `smcp` table — elsewhere the title
    would silently render plain lower-case. Ratio 19.3/24.3 measured from the
    reference PNG.
  - **Single-line fit** (`_singleLine` → `FittedBox`) mirrors the native offices
    header's `autoSizeTextType`; nothing scales while the line fits.
- **`LeftMenu` per-section header** (`lib/widgets/left_menu.dart`) — `_header()`
  chooses `LeftMenuHeader` for the `bible` section, legacy `DrawerHeader`
  otherwise. Mirrors native `setDrawerHeaderView`.
- Asset `assets/icons/ic_logo_bible_mask.png` copied from native drawables,
  declared in `pubspec.yaml`.

### Done (this task — offices/mass header)

1. **`AelfLiturgicalColors` theme extension** (`theme_provider.dart`) — the 7
   liturgical colours from native `colors_liturgical.xml`, per theme, registered
   on `light`/`dark`. `resolve(name)` maps both French (API) and English
   (offline) colour names to a `Color`; unknown → transparent.
2. **AELF logo asset** — `assets/icons/aelf_logo.svg` (ported from
   `aelf_logo_{light,dark}.xml`, two paths), declared in `pubspec.yaml`.
   Recoloured per theme by `_AelfLogoColorMapper` in `LeftMenuOfficeHeader`
   (red `#BF252A`→accent, glyph `#000000`→black/grey).
3. **`OfficeHeaderInfo` model** (`lib/models/office_header_info.dart`) —
   `day`, `liturgicalYear`, `psalterWeek`, `region`, `options` (a **list** of
   `OfficeLiturgyOption {name, degree, colorName}`), + `isLoading`/`isError`.
   `timeText` builds "Année … — Semaine …". Factories `fromApi(Map)` and
   `fromOffline(CelebrationContext)` (the latter typed `dynamic` to avoid a
   compile dependency on offline_liturgy). All fields optional; the widget
   hides empty rows.
4. **`LeftMenuOfficeHeader` widget** (`lib/widgets/left_menu_office_header.dart`)
   — full port of `navigation_drawer_header_offices.xml` +
   `..._liturgical_options_fragment.xml` (logo, autosized day title, time,
   region selector, colour-square options list). Native dp values as named
   constants; text scaling disabled.
5. **Region selector** — `PopupMenuButton` over the 8 regions in native dropdown
   order. `onRegionSelected` callback wired in `LeftMenu` to `updateRegion`
   (online) / `updateOfflineRegion` (offline).
6. **Shared background** (`lib/widgets/aelf_drawer_header_background.dart`) —
   extracted the radial gradient + 1dp bottom rule; both `LeftMenuHeader` and
   `LeftMenuOfficeHeader` now use it.
7. **Wired into `LeftMenu._header()`** — `bible`→`LeftMenuHeader`, mass/offices
   (+`offline_*` except calendar)→`LeftMenuOfficeHeader`, rest→legacy header.

`dart format` + `dart analyze lib` clean (no new errors/warnings; only
pre-existing infos remain).

### Done (live data wiring)

1. **Corrected `OfficeHeaderInfo.fromApi`** — the sandbox factory read AELF v1
   mass fields (`jour_liturgique_nom`, `annee`, `semaine`, `couleur`, `degre`),
   but the app fetches the **epitre.co** office endpoint
   (`api.app.epitre.co/82/office/informations/{date}.json`), whose block uses
   `liturgical_day`, `liturgical_year`, `psalter_week` (int → Roman), `zone`,
   and `liturgy_options[]` of `{liturgical_name, liturgical_degree,
   liturgical_color}`. Verified against the live JSON and native
   `OfficeInformations` / `OfficeLiturgyOption` moshi models.
2. **`LiturgyState.informationsJson`** + `_loadInformations()` — loads the
   `informations` block for the current date+region (DB-first, then web, with a
   stale-response guard), fired from `updateLiturgy()`'s online branch so it
   tracks date/region/type changes. Purely additive: never touches `aelfJson`
   or offline data. Also fixed the documented dead-`type`-param bug in
   `_getAELFLiturgy` (only caller passed the field value, so behaviour is
   unchanged) so `informations` can be fetched by type.
3. **`LiturgyState.primaryOfflineCelebration`** — the first celebrable
   `CelebrationContext` of the active offline office (the offline views'
   default), for `OfficeHeaderInfo.fromOffline`. Offline carries a psalter week
   and season but no A/B/C year letter, so the offline time line shows the week
   only (never "Année …").
4. **`LeftMenu._header()`** now builds `fromApi` (online) / `fromOffline`
   (offline) instead of region-only.

### Verified (marionette, light + dark)

- **Online Messe** header: "Jeudi" / "Année Paire — Semaine I" / region + two
  liturgical options (green *Férie* + white *Mémoire facultative*), matching
  `left_menu_light_liturgy.png` / `left_menu_dark_liturgy.png`.
- **Region dropdown** matches `left_menu_light_liturgy_dropdown.png` (8 regions,
  native order, current highlighted); picking one reloads the header live.
- **Offline** header (Sexte): logo + "Semaine I" + region + green square +
  celebration title.
- **Dark theme**: background, logo recolour (grey glyph + brighter red), light
  text, dark-palette squares.
- **Bible header** unchanged: synthesized small caps hold on desktop too.

### Done (header data source rules)

`LeftMenu._header()` now chooses the header's data source explicitly, gated on
the offline-liturgy feature flag rather than only the section name:

- **Offline data** (`LiturgyState.offlineHeaderInfo`, calendar-computed) is used
  **only** when the offline feature is on **and** the section is an `offline_*`
  office twin.
- **Online API** (`OfficeHeaderInfo.fromApi`, the `informations` block — same
  fields as `lib/parsers/information_parser.dart`: `liturgical_day`,
  `liturgical_year`, `psalter_week`, `zone`, `liturgy_options[]`) is used for
  everything else: the online offices, **every** section when the setting is
  off, and **Mass**.
- **Mass is not yet available in the offline liturgy.** It will be part of the
  feature later; in the meantime `_isMassSection()` forces the Mass header onto
  the online API regardless of the offline setting (and the guard already covers
  a future `offline_messes` section).

Verified live: offline **off** → online office "None" shows the API header + the
8-region popup; Mass (offline on) uses the API header + popup; offline office →
offline header + location sheet.

### Done (offline-mode header parity)

Three offline-only improvements, all shipped and verified live (marionette,
offline mode + online guardrail). **The online `informations` path
(`OfficeHeaderInfo.fromApi`) and all API-based liturgy stayed untouched.**

- **§1 Location sheet** — `LeftMenuOfficeHeader` gained `regionLabel` +
  `onRegionTap`; offline routes the region row to the existing
  `showLocationSelector` bottom sheet, online keeps the 8-region popup.
  `LiturgyState.selectOfflineLocation(id)` shares settings' persist-and-infer
  flow; `offlineRegionLabel` caches the location's French name synchronously.
- **§2 One square/line per feast** — `LiturgyState.offlineCelebrations` returns
  every celebrable `CelebrationContext` of the active office; the header builder
  maps each to an `OfficeLiturgyOption`. `primaryOfflineCelebration` kept as
  `offlineCelebrations.first`.
- **§3 Weekday + année** — `LiturgyState.offlineHeaderInfo` fills the weekday
  title (French, from the date) and "Année paire/impaire" (from
  `offlineCalendar.getDayContent(date).liturgicalYear`, even→paire), plus the
  Roman psalter week and degrees (`_offlineDegree(precedence)`, ferial→"Férie").
  New `OfficeHeaderInfo.fromOfflineDay(...)` factory does the Roman/capitalise.

Verified: offline "None (nouveau)" shows "Lundi / Année Paire — Semaine II /
diocèse de Bayonne" + green square "…du Temps ordinaire" / *Férie*; the location
sheet opens, selects, persists, and updates the label live; online "Messe" is
unchanged and still opens the 8-region popup.

The plan that produced this is preserved below for reference.

### Planned (offline-mode header parity)

Three offline-only improvements. **Guardrail: the online `informations` path
(`OfficeHeaderInfo.fromApi`) and all API-based liturgy stay untouched.** Every
change is gated on offline mode / `offline_*` sections.

#### 1. Nested location selector instead of the 8-region popup

Offline liturgy is not one of the 8 online regions — it is a location in the
full offline hierarchy (continent › country › diocese › …). The app already has
the right UI: `showLocationSelector(...)` in
`lib/widgets/location_selector_widget.dart` — a depth-indented `LocationNode`
tree in a `DraggableScrollableSheet` bottom sheet (the same one settings'
`_buildLocalisationSection` opens when offline is enabled).

- In `LeftMenuOfficeHeader`, when offline, the region row opens
  `showLocationSelector` instead of the `PopupMenuButton` (the popup stays for
  the online path).
- Selection must go through the **same** flow settings uses in
  `_onLocationSelected`: `LocationService.setSelectedLocation(id)` +
  `LiturgyState.updateOfflineRegion(id)` + `inferOnlineRegion(id)` →
  `updateRegion(...)`. Extract that into a shared
  `LiturgyState.selectOfflineLocation(id)` so settings and the header share one
  path and can't drift.
- Region **label**: show the location's French name, not an online-region label.
  `LiturgyState.locationDisplayLabel` already returns it but is a `Future`; cache
  it as a synchronous `offlineRegionLabel` field (updated in
  `updateOfflineRegion` / init) so the header renders without a `FutureBuilder`.
- `LeftMenuOfficeHeader` gains `regionLabel` + an `onRegionTap` callback (or a
  `useLocationSheet` bool); online passes the popup, offline passes the sheet.

#### 2. One colour square + line per feast (offline)

The widget already loops `info.options`, so this is a **data-only** change: the
offline builder currently emits a single option (`primaryOfflineCelebration`).

- Add `LiturgyState.offlineCelebrations` → **all** `isCelebrable`
  `CelebrationContext`s of the active offline office (generalises
  `primaryOfflineCelebration`, which stays as the "first" for other callers).
- Map each to an `OfficeLiturgyOption` (name = `celebrationTitle`,
  colorName = `liturgicalColor`, degree from `precedence`, see §3).

#### 3. Missing weekday + liturgical year (offline)

Currently the offline header shows no big day title and no "Année …" line.

- **Weekday** (big title, e.g. "Vendredi"): derive the French weekday from the
  celebration/selected date (`['lundi'…'dimanche'][date.weekday-1]`, capitalised).
  Fills the `day` field that `fromOffline` left empty.
- **Année paire/impaire**: `CelebrationContext` has no year, but
  `offlineCalendar.getDayContent(date).liturgicalYear` (int) does. Even →
  "paire", odd → "impaire" (verified against the live API: 2026-07-30 → "Paire",
  2026 is even). Feeds `liturgicalYear`; `timeText` then renders
  "Année Paire — Semaine {roman breviaryWeek}", matching the online layout.
  Note: this is the weekday 2-year cycle — offline data carries no A/B/C Sunday
  cycle, so Sundays show paire/impaire rather than A/B/C (acceptable; offline
  targets the Divine Office).
- **Degree**: `getCelebrationTypeLabel(precedence)` gives
  `(Solennité)`/`(Fête)`/`(Mémoire …)`; strip the parentheses, and map the empty
  ferial case (precedence 13) to "Férie" to match the online wording.
- Build this richer offline info in `LiturgyState` (it holds both the calendar
  and the office maps) via a new `OfficeHeaderInfo.fromOfflineDay(...)` /
  builder; `LeftMenu._header()` reads it for `offline_*` sections.

#### Files & verification

- Touch: `lib/states/liturgyState.dart`, `lib/models/office_header_info.dart`,
  `lib/widgets/left_menu_office_header.dart`, `lib/widgets/left_menu.dart`.
  No online-path code changes.
- Verify (marionette, offline enabled): location sheet opens & persists; header
  shows weekday + "Année …" + week + one square/line per feast; then toggle
  offline **off** and confirm the online Messe header is unchanged.

### To do (later)

- **Check the offices day-title font** — native uses
  `sans-serif-condensed-medium`; the port uses Roboto `w500` (no condensed
  variant bundled). Decide whether to bundle Roboto Condensed.

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

`LiturgyState._validOnlineRegions`: france, belgique, luxembourg, suisse,
canada, monaco, afrique, romain. Offline uses location ids with overrides
(`belgique→belgium`, `suisse→switzerland`) already handled in `LiturgyState`.

### Data source seam

- **Offline**: `CelebrationContext` (offline_liturgy package) — `celebrationTitle`,
  `liturgicalTime`, `breviaryWeek`, `liturgicalColor`, `celebrationType`.
- **API**: liturgy `informations` block (day, semaine, annee, couleur, degre,
  fete/jour_liturgique).

`OfficeHeaderInfo` normalizes both so `LeftMenuOfficeHeader` stays source-agnostic.
