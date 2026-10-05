# Mass (Messe)

How the Mass feature works end to end: the YAML schema and `Mass`/`Masses` classes in the `offline_liturgy` package, the detection/export pipeline, and the Flutter view that displays it. Complements `docs/office_display.md` (which documents `MassOfficeDisplay`'s tab structure alongside the other offices) with the parts that are specific to Mass and don't fit the generic office pattern.

---

## Data model (`offline_liturgy` package)

### YAML schema

The `mass:` key appears in `ferial_days/*.yaml` and a handful of `sanctoral/*.yaml` files (major solemnities only — ordinary saints' days have no Mass data of their own and fall back to the ferial day). The `Common of Saints` files in `commons/` can carry one too (55 of them do so far). It's a list of Mass objects, since one day can define several distinct Masses (`DAY_MASS`, `EASTER_VIGIL`, `PROCESSION_WITH_PALMS`, `MASS_OF_THE_PASSION`, etc.):

```yaml
mass:
- massType: DAY_MASS          # translated for display by massTypeLabels
  name: Messe du jour
  entranceAntiphon: [...]     # List<MassAntiphon> — biblicalRef + content
  collect: [...]              # List<String> — opening prayer
  readingParts:
  - partType: READING         # READING | EPISTLE | PSALM | GOSPEL (canticles are PSALM parts)
    partContents:
    - biblicalRef: ...
      cycle: ['1']             # see below
      content: ...
  offeringPrayer: [...]
  prefaceList:                 # List<PrefaceEntry> — codes resolved from mass_missal/prefaces/ (not rendered yet)
  - ...
  eucharisticPrayerCommunicantes: ...  # code resolved from mass_missal/eucharistic_prayer_communicantes/ (not rendered yet)
  communionAntiphon: [...]
  prayerAfterCommunion: [...]
  prayerOnThePeople: [...]     # List<String> — "Prière sur le peuple", Lenten ferias only
  solemnBlessingList:          # List<HymnEntry> — code reference(s), resolved like a hymn (see below)
  - easter_blessing
  sequence:                    # List<HymnEntry> — proper sequence, same code-reference mechanism
  - victimae-paschali-laudes
```

### The `cycle` field

A single, deliberately neutral field (`List<String>?`) on `MassReading`/`MassPsalm`/`MassGospel`. Its meaning depends entirely on context — nothing in the YAML schema disambiguates it:

- Weekday Ordinary Time: `['1']` / `['2']` — the two-year weekday Lectionary cycle (Year I / Year II).
- Sunday / major feast: `['A']` / `['B']` / `['C']` — the three-year Sunday cycle.
- Free alternatives (e.g. Pentecost's choice of Gospel): reuses `A`/`B`/`C` for options that aren't really tied to the liturgical year, but the same resolution mechanism happens to pick one consistently.
- No `cycle` at all: universal, always kept (e.g. a weekday Gospel, or Good Friday's single Passion reading).

Resolving `cycle` is entirely the pipeline's job (see below) — the classes themselves are a raw mirror of the YAML.

### Classes (`lib/classes/mass_class.dart`)

`Mass` (one Mass: `massType`, `name`, `readingParts`, prayers) and `Masses` (container: `masses: List<Mass>`), both with `overlayWith`/`overlayWithCommon`/`isEmpty`, matching the convention used by `Morning`/`Vespers`/`Readings`/`MiddleOfDay`. Mass adds two methods of its own: `overlayPrayerFields` (overlays the prayer texts only, leaving `readingParts` alone, used for memorials) and `fillMissingReadingPartsFromCommon` (adds, type by type, the reading parts a Mass is missing).

`sequence` and `solemnBlessingList` are `List<HymnEntry>?`, `prefaceList` is `List<PrefaceEntry>?` and `eucharisticPrayerCommunicantes` an `EucharisticPrayerCommunicantesEntry?`: code references, not literal text. See "Hymn/blessing hydration" below.

`readingParts: List<MassReadingPart>` — each part has a `partType` and a list of typed `partContents` (`MassReading`, `MassPsalm`, or `MassGospel`, a sealed hierarchy). Sundays and the Easter Vigil can have several parts sharing the same `partType` (e.g. two `READING` parts for the 1st reading + epistle) — `Mass.overlayWith` replaces `readingParts` wholesale rather than merging per-partType, precisely to avoid silently collapsing those repeated entries.

## Package pipeline (`lib/offices/masses/`)

```
massDetection(calendar, date, dataLoader)
  -> Future<Map<String, CelebrationContext>>
     One map entry PER (celebration, Mass) pair — unlike every other office,
     a single day can yield several entries (vigil + day Mass, procession +
     Passion Mass), keyed "$celebrationTitle - $massName". Each context
     carries celebrationType: 'mass', massName (the massType) and
     hasFeastReadingParts (see below).

massExport(CelebrationContext)
  -> Future<Mass>
     1. Ferial base layer             (ferialMassResolution)
     2. Load the proper Mass file     (massExtract + dirPathForCode),
                                      only when celebrationCode != ferialCode
     3. Common overlay                (loadMassHierarchicalCommon)
     4. Proper overlay
          precedence <= 9 (Feasts/Solemnities) -> overlayWith: everything,
                                                   readingParts included
          precedence > 9 (memorials)           -> overlayPrayerFields: prayer
                                                   texts only, the day's
                                                   readingParts are kept
        (steps 3 and 4 use the same rule; Dec 26-28 always take the full
         overlay, since they have no ferial day underneath)
     5. Select the Mass matching context.massName
     5b. Memorial with useProperReadingsForMemorial: the proper's
         readingParts replace the day's, and any part type still missing
         (compared with the day's own set) is filled from the Common
     6. Filter readingParts to the current lectionary cycle:
          Sunday  -> liturgicalYear(year)                           (A/B/C)
          weekday -> weekdayLectionaryYear(year) + liturgicalYear(year)
        (a few Lenten weekdays key their Gospel off the Sunday letter; the
         two value sets never overlap). Entries without a cycle tag are
         always kept.
     7. Resolve sequence / solemnBlessingList / eucharisticPrayerCommunicantes /
        prefaceList codes into content (resolveOfficeContent)
```

`hasFeastReadingParts` is true when a non-ferial celebration has readingParts of its own, or its Common has some for the same `massType`. The view uses it to offer the choice between the day's readings and the feast's own (see below).

`CelebrationContext.liturgicalYear` (an `int`) is populated straight from `DayContent.liturgicalYear` in `detectCelebrations()` — the calendar already computes this reference year correctly, including the Advent shift (e.g. Advent 2026 carries `liturgicalYear: 2027`, matching the cycle that governs the whole liturgical year it starts). `weekdayLectionaryYear()` (`lib/tools/date_tools.dart`) is a one-line odd/even mapping on that same reference year: Year I in odd years, Year II in even years.

### Hymn/blessing hydration

Almost every piece of Mass content is literal text already in the YAML, not a code reference into a shared library. Four fields are the exception. The first two are resolved through the exact same mechanism every other office's `hymn:` field uses:

- `sequence` (the proper sequence, e.g. Victimae Paschali Laudes on Easter) — a code reference into `assets/hymns/`, same as any other hymn.
- `solemnBlessingList` — a code reference into `assets/mass_missal/blessings/` instead, but otherwise an identical title/content YAML shape.

Both are `List<HymnEntry>?` (the same class `hymn:` fields use elsewhere), hydrated by `massExport`'s final step: `resolveOfficeContent(hymns: selected.sequence, blessings: selected.solemnBlessingList, dataLoader: context.dataLoader)`. `resolveOfficeContent` (`lib/tools/resolve_office_content.dart`, shared across every office) gained the `blessings` parameter for this — it resolves each entry via `HymnsLibrary.getHymn(code, dataLoader, folder: 'mass_missal/blessings')`, writing the result into `HymnEntry.hymnData` exactly like `hymns` does. `HymnsLibrary.getHymn()` (`lib/assets/libraries/hymns_library.dart`) gained the optional `folder` parameter (default `'hymns'`) to make this possible, with its cache keyed on `'$folder/$code'` so a hymn and a blessing could never collide even if they happened to share a code. No parallel "blessings library" class was written — the title/content shape is identical, so the existing `Hymns` class and `HymnsLibrary` cache are reused as-is.

The other two have their own small libraries, on the same lazy-loading and caching pattern: `prefaceList` → `PrefacesLibrary` (`mass_missal/prefaces/`), and `eucharisticPrayerCommunicantes` → `EucharisticPrayerCommunicantesLibrary` (`mass_missal/eucharistic_prayer_communicantes/`).

`sequence` data currently exists for Easter Sunday, its Octave weekdays and Our Lady of Sorrows. `solemnBlessingList` is set in about 200 files.

## Flutter view (`lib/widgets/offline_liturgy_mass_view.dart`)

`MassView` / `MassOfficeDisplay`, built on the same `BaseOfficeViewState<W, T>` state machine as Morning/Vespers/Readings (see `docs/office_display.md` §1-2 for the shared loading/celebration-selection lifecycle and the tab-vs-scroll display modes). Tab structure is documented in `docs/office_display.md` §3.

Points worth calling out because they're Mass-specific, not just "another office":

- **Reading-part tabs are generated dynamically**, one per `MassReadingPart`, labelled by position within their family (`_readingPartLabels` in the widget file) rather than by a fixed list of tab names — necessary because the number and shape of reading parts varies a lot: a weekday has 1 reading + psalm + Gospel, a Sunday has 2 readings + psalm + Gospel, the Easter Vigil has several OT readings interleaved with psalms/canticles plus an epistle and Gospel.
- **Multiple Masses on the same day reuse the ordinary celebration selector.** `massDetection`'s one-entry-per-(celebration, Mass) map means Palm Sunday's procession and Passion Mass (or Easter's Vigil and day Mass) show up as two separate, independently selectable entries in `CelebrationChipsSelector` — the same widget every other office uses to let the user pick between competing celebrations. No dedicated "choose the Mass" UI was built; it wasn't needed. When a celebration has more than one Mass, `massDetection` sets `officeDescription` to the Mass's own label only (`massTypeLabels[massType]`, falling back to the YAML `name`), e.g. "Messe de la nuit". The celebration name is shown once above the chips by `_CelebrationTitleHeader`, so the chips don't repeat it. A single-Mass day keeps the plain celebration name.
- **Memorials can switch between the day's readings and their own.** When a memorial (not a Feast or Solemnity) is celebrated and `hasFeastReadingParts` is true, the "Office" tab shows a `_ReadingSourceChipsSelector` ("select-reading-source"). Picking the feast's readings calls `massExport` again with `useProperReadingsForMemorial: true` and swaps the displayed Mass (`_effectiveMassData`). The choice is not persisted: it resets to the day's readings when another celebration or Mass is selected. A memorial is never shown without its own prayer texts, so "Pas de commun" is not offered (`forceCommon`).
- **Reading/Gospel body text is left-aligned, not justified.** The shared `ScriptureWidget` (used by Morning's `_ReadingTab` and others) hardcodes `textAlign: TextAlign.justify` by design for those offices. Rather than change that shared widget, Mass has its own `_MassScriptureWidget` (private to `offline_liturgy_mass_view.dart`) — same title/reference/content layout, but left-aligned.
- **Psalm reference uses `biblicalRef`, not `refAbbr`.** `refAbbr` is a truncated abbreviation (e.g. `"31, 1…"`) meant for compact display elsewhere, not the reference shown alongside the responsorial psalm's text.
- **The Gospel's Alléluia/acclamation block comes *before* the "Évangile" title, not after.** Order in `_MassGospelContent`: `LiturgyPartTitle('Alléluia')` (or `'Acclamation de l'Évangile'` during `lent`/`holyweek`, `_noAlleluiaTimes`) + `_MassAcclamationText` (the fixed "Alléluia, alléluia. / `acclamationAntiphon` / Alléluia." framing, rubric-styled, at body size 16) + a `BiblicalReferenceButton` for `acclamationAntiphonReference` if present (the Alléluia verse can cite a different reference than the Gospel passage itself, e.g. Lc 2,10-11 for a Gospel read as Lc 2,1-14) — then, in scroll mode, the forme-brève pointer if any — then the "Évangile" title — then `headline` if present (italic, size 14, rendered inline with `YamlTextFromString`) — then the biblical reference button — then the "✝ Évangile de Jésus Christ selon saint X" announcement (`_MassGospelAnnouncement`, `evangelistName()` resolved from the biblical reference) — then the body text.
- **The forme brève (`shortBiblicalRef`/`shortContent` on `MassGospel`, `shortReadingRef`/`shortReadingContent` on `MassReading`) behaves differently in scroll vs tab mode.** `_shortFormPart()` builds a synthetic `MassReadingPart` holding only the short-form projection of each content that has one (for Gospel, this now also carries over `acclamationAntiphon`/`acclamationAntiphonReference` from the long form, not just `biblicalRef`/`content`/`headline`). In **scroll mode**, `_ShortFormAnnouncement` ("Une forme brève est proposée plus bas", tap-to-scroll) is shown right after the Alléluia block and before the "Évangile" title of the long form (`_MassGospelContent.shortFormAnnouncement`, threaded down from `_ReadingPartTab`) — and the forme-brève block further down does *not* repeat the Alléluia (`hideAlleluiaInShortForm: true`, the default), since it was just shown once, above, in the same continuous scroll. In **tab mode**, the forme brève gets its own tab right after the long form, labelled "… (forme brève)". It has no such pointer but *does* repeat the full Alléluia block (`hideAlleluiaInShortForm: false`), using the same acclamation text/reference as the long-form tab, so that tab reads as a complete, self-contained proclamation on its own. The evangelist announcement (`_MassGospelAnnouncement`) is shown for the forme brève in both modes — it used to be suppressed there, on the assumption it had already been shown once for the long form, which didn't hold once the two forms became separately navigable in tab mode.
- **The forme brève must live on the *same* `partContents` item as the long form, never as a second item in the list.** `MassGospel`/`MassReading` carry both the long-form fields (`biblicalRef`/`content`/...) and the short-form ones (`shortBiblicalRef`+`shortContent`, or `shortReadingRef`+`shortReadingContent`) together on one object. Nativity's `evening_mass` Gospel data used to model the forme brève as a *second* `partContents` entry instead (only `shortBiblicalRef`/`shortContent` set, everything else null) — since `_ReadingPartTab._buildPartContent` renders every `partContents` entry as a full alternative reading separated by "ou bien :", this produced a spurious "ou bien :" followed by a near-empty Gospel block (still showing an "Alléluia" heading with no acclamation text, and an empty "Évangile" title) between the long form's content and the forme-brève tab/block. Fixed by merging the two YAML items into one (see `offline-liturgy/docs/add_data_manual.md` § `mass` → `readingParts`, which documents this explicitly to prevent it recurring).
- **Empty prayers are hidden entirely, not shown as a placeholder.** `collect`, `offeringPrayer`, `prayerAfterCommunion`, `prayerOnThePeople`, and the resolved `solemnBlessingList` each hide their own title+text block when null/empty (they don't fall through to `buildOrationWidgets`' default "no oration" placeholder text, unlike other offices' orations). In tab mode, the Offrandes/Communion tabs themselves disappear entirely when they'd have nothing left to show (`_hasOfferingTab`/`_hasCommunionTab` on `MassOfficeDisplay`).
- **No separate "Bénédiction" tab.** `prayerOnThePeople` ("Prière sur le peuple", said instead of/alongside the final blessing on Lenten ferias) and the solemn blessing are appended at the end of the Communion tab instead, in liturgical order: communion antiphon → prayer after communion → prayer over the people → solemn blessing. Each block is independently hidden when its data is absent, so most days show none of the last two. `solemnBlessingList` is rendered by mapping each resolved `HymnEntry.hymnData?.content` to a string list and passing that to `buildOrationWidgets`, same as any other oration — the widget doesn't otherwise deal with `HymnEntry`.
- **The proper sequence gets its own conditional tab, "Séquence".** Shown only when `massData.sequence` is non-empty, which is rare (see "Hymn/blessing hydration" above). Positioned right before the Gospel (the last reading part — see `_readingPartLabels`'s doc comment), in both tab and scroll mode, since the sequence is sung after the second reading and before the Gospel acclamation. Rendered by `_MassSequenceTab` as a `CollapsibleLiturgyText` titled "Séquence — {title}".
- **The three Mass orations are left-aligned, not justified.** `buildOrationWidgets` (`office_common_widgets.dart`, shared by every office) gained an optional `textAlign` parameter, default `TextAlign.justify` — unchanged for every other office's `oration`. Mass's three call sites (`collect` in Ouverture, `offeringPrayer` in Offrandes, `prayerAfterCommunion` in Communion) pass `TextAlign.left`.
- **There is always a separate "Ouverture" tab, in both display modes.** `_buildIntroductionChildren()` (header, entrance antiphon, opening prayer) used to be prepended as `leading` widgets to the first reading-part tab in tab mode (skipping a dedicated Introduction tab whenever reading parts existed, which is virtually always). It now always renders as its own "Ouverture" tab (`_IntroductionTab`), ahead of the reading-part tabs — the `leading` parameter was removed from `_ReadingPartTab` entirely, along with the `_hasReadingParts`-based branching in `_calculateTabCount`/`_buildTabs`/`_buildTabViews`. Scroll mode was already unaffected (the Introduction always rendered as its own block there).
- **Right-indent (`>`) uses a smaller, Mass-specific multiplier and supports chaining.** `YamlTextLine.indentLevel` (an `int`, counting consecutive leading `>` characters — `>>` = level 2, etc.) replaced the old boolean `hasRightIndent` in the shared `YamlTextParser`/`YamlTextWidget` (`lib/parsers/yaml_text_parser.dart`), mirroring the pattern already used by `psalm_parser.dart`. The actual indent is `fontSize * rightIndentMultiplier * indentLevel`, with `rightIndentMultiplier` a new optional parameter defaulting to `1.5` (preserving the exact previous rendering for every other office, which don't pass it). Mass's three body-text call sites (`_MassScriptureWidget`, `_MassPsalmContent`, `_MassGospelContent`) pass `rightIndentMultiplier: 0.75` — a smaller indent than the rest of the app, since Mass's own biblical text uses `>` more often and at a tighter column width.

### Navigation wiring

`offline_mass` is a new entry in `app_sections.dart`, alongside (not replacing) the legacy AELF-web `"messes"` section — both are visible at once when `feature_offline_liturgy` is on. Wired through `LiturgyState.getOfflineMass()`/`offlineMass` and a `case "offline_mass"` in `liturgy_screen.dart`, exactly like every other `offline_*` office.

## Key files

| File | Role |
|---|---|
| `offline-liturgy/assets/calendar_data/ferial_days/*.yaml`, `sanctoral/*.yaml` | `mass:` data |
| `offline-liturgy/lib/classes/mass_class.dart` | `Mass`, `Masses`, `MassReadingPart`, `MassReading`, `MassPsalm`, `MassGospel`, `MassAntiphon`, `MassChorusEntry` |
| `offline-liturgy/lib/offices/masses/mass_detection.dart` | `massDetection()` |
| `offline-liturgy/lib/offices/masses/mass_export.dart` | `massExport()`, cycle filtering |
| `offline-liturgy/lib/offices/masses/ferial_mass_resolution.dart` | Per-season ferial resolution |
| `offline-liturgy/lib/tools/date_tools.dart` | `liturgicalYear()`, `weekdayLectionaryYear()` |
| `offline-liturgy/lib/tools/hierarchical_common_loader.dart` | `loadMassHierarchicalCommon()` |
| `offline-liturgy/lib/tools/resolve_office_content.dart` | `resolveOfficeContent()` — hymn/blessing/psalm hydration, shared across offices |
| `offline-liturgy/lib/assets/libraries/hymns_library.dart` | `HymnsLibrary.getHymn()` — folder-parametrized loader, shared by hymns and solemn blessings |
| `offline-liturgy/assets/hymns/*.yaml`, `assets/mass_missal/blessings/*.yaml` | title/content YAML for sequences and solemn blessings |
| `aelf-flutter/lib/widgets/offline_liturgy_mass_view.dart` | `MassView`, `MassOfficeDisplay` |
| `aelf-flutter/lib/states/liturgyState.dart` | `offlineMass`, `getOfflineMass()` |
| `aelf-flutter/lib/data/app_sections.dart` | `offline_mass` section entry |

## Related fix: `_text_` never meant italic

While checking why some Mass content wasn't rendering in italics, found that `YamlTextParser` only ever recognized `%text%` as the italic toggle (see `docs/office_display.md` §7) — `_text_` was never implemented and silently rendered as plain text with the surrounding underscores. This wasn't Mass-specific (a handful of Office content files had the same pattern), so it was fixed as a **data** migration (`offline-liturgy/scripts/underscore_to_percent_italic.py`, converting `_text_` to `%text%` inside YAML block-scalar bodies only) rather than by teaching the parser to also accept underscore — `_` is heavily used elsewhere in this data as an identifier separator (`ot_25_0`, `roman/josephine_bakhita_virgin`), so a parser-level change risked misfiring on unrelated text.

## Related fix: Mass could get stuck on "Loading mass..." forever

Investigating a report that Christmas Day (4 possible Masses) showed a blank screen stuck on "Loading mass..." traced back to two bugs upstream of everything documented above — not specific to Mass, but first noticed through it:

1. `LiturgyState.updateLiturgy()`'s `offline_*` fetches (`getOfflineMass()` and every sibling: complines, morning, readings, tierce/sexte/none, vespers) called `.then()` with no `.catchError()`. If anything in the chain threw, the callback never ran, the corresponding Map stayed empty, and `liturgy_screen.dart`'s loading guard (which only checks `Map.isEmpty`) showed the spinner forever with no visible error.
2. `LiturgyState._ensureCalendar()` had a pre-existing `TODO` noting that a failed calendar computation left the rejected `Future` cached in `_calendarFuture`, so every later caller (any office, any date) would await and re-throw that same stale rejection.

Fixed by wrapping `_ensureCalendar`'s computation in `try`/`finally`, and adding a shared `offlineLoadError` field + `onOfflineLoadError` handler attached via `.catchError()` to each fetch — see `docs/office_display.md` §0 for the resulting fetch/error flow. This didn't turn out to be the actual cause of the specific "stuck on Dec 25" report (`massDetection` reproduced fine outside the app for that date), but it closes a real gap: previously, no `offline_*` office could ever show *why* it failed to load, only that it never finished.

## Known limitations

- Ascension (`sanctoral/roman/ascension.yaml`) has no `mass:` data yet.
- `prefaceList` and `eucharisticPrayerCommunicantes` are resolved by the package but not rendered anywhere in `MassOfficeDisplay` yet: they are meant for a dedicated preface / Eucharistic Prayer display.
- `MassGospel.beforeAcclamationAntiphon` / `afterAcclamationAntiphon` are not used in the data and not displayed.
