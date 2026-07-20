# Mass (Messe)

How the Mass feature works end to end: the YAML schema and `Mass`/`Masses` classes in the `offline_liturgy` package, the detection/export pipeline, and the Flutter view that displays it. Complements `docs/office_display.md` (which documents `MassOfficeDisplay`'s tab structure alongside the other offices) with the parts that are specific to Mass and don't fit the generic office pattern.

---

## Data model (`offline_liturgy` package)

### YAML schema

The `mass:` key appears in `ferial_days/*.yaml` and a handful of `sanctoral/*.yaml` files (major solemnities only — ordinary saints' days have no Mass data of their own and fall back to the ferial day). It's a list of Mass objects, since one day can define several distinct Masses (`day_mass`, `easter_vigil`, `procession_with_palms`, `mass_of_the_passion`, etc.):

```yaml
mass:
- massType: day_mass
  name: Messe du jour
  entranceAntiphon: [...]     # List<MassAntiphon> — biblicalRef + content
  collect: [...]              # List<String> — opening prayer
  readingParts:
  - partType: READING         # READING | EPISTLE | PSALM | CANTICLE | GOSPEL
    partContents:
    - biblicalRef: ...
      cycle: ['1']             # see below
      content: ...
  offeringPrayer: [...]
  prefaceList: [...]           # preface reference IDs — not rendered by MassOfficeDisplay, reserved for a separate display
  communionAntiphon: [...]
  prayerAfterCommunion: [...]
  solemnBlessingList: [...]
```

### The `cycle` field

A single, deliberately neutral field (`List<String>?`) on `MassReading`/`MassPsalm`/`MassGospel`. Its meaning depends entirely on context — nothing in the YAML schema disambiguates it:

- Weekday Ordinary Time: `['1']` / `['2']` — the two-year weekday Lectionary cycle (Year I / Year II).
- Sunday / major feast: `['A']` / `['B']` / `['C']` — the three-year Sunday cycle.
- Free alternatives (e.g. Pentecost's choice of Gospel): reuses `A`/`B`/`C` for options that aren't really tied to the liturgical year, but the same resolution mechanism happens to pick one consistently.
- No `cycle` at all: universal, always kept (e.g. a weekday Gospel, or Good Friday's single Passion reading).

Resolving `cycle` is entirely the pipeline's job (see below) — the classes themselves are a raw mirror of the YAML.

### Classes (`lib/classes/mass_class.dart`)

`Mass` (one Mass: `massType`, `name`, `readingParts`, prayers) and `Masses` (container: `masses: List<Mass>`), both with `overlayWith`/`overlayWithCommon`/`isEmpty`, matching the convention used by `Morning`/`Vespers`/`Readings`/`MiddleOfDay`. `overlayWithCommon` was added for structural parity even though no "Common of Saints" Mass texts exist in the data yet (see Limitations).

`readingParts: List<MassReadingPart>` — each part has a `partType` and a list of typed `partContents` (`MassReading`, `MassPsalm`, or `MassGospel`, a sealed hierarchy). Sundays and the Easter Vigil can have several parts sharing the same `partType` (e.g. two `READING` parts for the 1st reading + epistle) — `Mass.overlayWith` replaces `readingParts` wholesale rather than merging per-partType, precisely to avoid silently collapsing those repeated entries.

## Package pipeline (`lib/offices/masses/`)

```
massDetection(calendar, date, dataLoader)
  -> Future<Map<String, CelebrationContext>>
     One map entry PER (celebration, Mass) pair — unlike every other office,
     a single day can yield several entries (vigil + day Mass, procession +
     Passion Mass), keyed "$celebrationTitle - $massName". Each context
     carries celebrationType: 'mass' and massName set.

massExport(CelebrationContext)
  -> Future<Mass>
     1. Ferial base layer            (ferialMassResolution)
     2. Proper celebration overlay   (massExtract + dirPathForCode)
     3. Common overlay               (loadMassHierarchicalCommon;
                                       overlayWithCommon if precedence > 7,
                                       else overlayWith)
     4. Proper overlay reapplied
     5. Select the Mass matching context.massName
     6. Filter readingParts to the current lectionary cycle:
          Sunday/feast -> liturgicalYear(context.liturgicalYear)      (A/B/C)
          weekday      -> weekdayLectionaryYear(context.liturgicalYear) (I/II)
        Entries without a cycle tag are always kept.
```

`CelebrationContext.liturgicalYear` (an `int`) is populated straight from `DayContent.liturgicalYear` in `detectCelebrations()` — the calendar already computes this reference year correctly, including the Advent shift (e.g. Advent 2026 carries `liturgicalYear: 2027`, matching the cycle that governs the whole liturgical year it starts). `weekdayLectionaryYear()` (`lib/tools/date_tools.dart`) is a one-line odd/even mapping on that same reference year: Year I in odd years, Year II in even years.

No hymn or psalm-library hydration step exists for Mass (unlike `resolveOfficeContent` for the Office) — every piece of Mass content is literal text already in the YAML, not a code reference into a shared library.

## Flutter view (`lib/widgets/offline_liturgy_mass_view.dart`)

`MassView` / `MassOfficeDisplay`, built on the same `BaseOfficeViewState<W, T>` state machine as Morning/Vespers/Readings (see `docs/office_display.md` §1-2 for the shared loading/celebration-selection lifecycle and the tab-vs-scroll display modes). Tab structure is documented in `docs/office_display.md` §3.

Points worth calling out because they're Mass-specific, not just "another office":

- **Reading-part tabs are generated dynamically**, one per `MassReadingPart`, labelled by position within their family (`_readingPartLabels` in the widget file) rather than by a fixed list of tab names — necessary because the number and shape of reading parts varies a lot: a weekday has 1 reading + psalm + Gospel, a Sunday has 2 readings + psalm + Gospel, the Easter Vigil has several OT readings interleaved with psalms/canticles plus an epistle and Gospel.
- **Multiple Masses on the same day reuse the ordinary celebration selector.** `massDetection`'s one-entry-per-(celebration, Mass) map means Palm Sunday's procession and Passion Mass (or Easter's Vigil and day Mass) show up as two separate, independently selectable entries in `CelebrationChipsSelector` — the same widget every other office uses to let the user pick between competing celebrations. No dedicated "choose the Mass" UI was built; it wasn't needed. `massDetection` disambiguates these entries by appending the Mass's `name` in parentheses to `officeDescription` (e.g. "Nativité du Seigneur (Messe de la nuit)") whenever the celebration has more than one Mass — a single-Mass day keeps the plain celebration name. Before this, every entry for a multi-Mass day rendered with an identical label (chips and the office header both read straight `officeDescription`), making the choices indistinguishable in the UI even though the underlying data and selection mechanism were already correct.
- **Reading/Gospel body text is left-aligned, not justified.** The shared `ScriptureWidget` (used by Morning's `_ReadingTab` and others) hardcodes `textAlign: TextAlign.justify` by design for those offices. Rather than change that shared widget, Mass has its own `_MassScriptureWidget` (private to `offline_liturgy_mass_view.dart`) — same title/reference/content layout, but left-aligned.
- **Psalm reference uses `biblicalRef`, not `refAbbr`.** `refAbbr` is a truncated abbreviation (e.g. `"31, 1…"`) meant for compact display elsewhere, not the reference shown alongside the responsorial psalm's text.
- **The Gospel's Alléluia/acclamation block comes *before* the "Évangile" title, not after.** Order is: `LiturgyPartTitle('Alléluia')` (or `'Acclamation de l'Évangile'` during `lent`/`holyweek`, since Alléluia is never said then) + `_MassAcclamationText` (the fixed "Alléluia, alléluia. / `acclamationAntiphon` / Alléluia." framing, rubric-styled) + a `BiblicalReferenceButton` for `acclamationAntiphonReference` if present (the Alléluia verse can cite a different reference than the Gospel passage itself, e.g. Lc 2,10-11 for a Gospel read as Lc 2,1-14) — then the "Évangile" title + biblical reference — then, if present, `headline` via `_MassHeadlineCommentary` — then the "✝ Évangile de Jésus Christ selon saint X" announcement (`_MassGospelAnnouncement`, `evangelistName()` resolved from the biblical reference) — then the body text. `_MassAcclamationText`/`_MassHeadlineCommentary` mimic the structure of the shared `OfflineLiturgyPartSubtitle`/`LiturgyPartCommentary` (italic text; commentary keeps the left border) but with Mass-specific tweaks the shared widgets don't parametrize: acclamation at normal body size (16) instead of the subtitle's 14, headline at a tighter line-height (1.2) instead of the commentary's 1.4 — so they're separate, self-contained widgets, not reuses of the originals. `MassGospel.beforeAcclamationAntiphon`/`afterAcclamationAntiphon` are unused in the data (0 occurrences across the whole corpus) and are not displayed.
- **The forme brève (`shortBiblicalRef`/`shortContent` on `MassGospel`, `shortReadingRef`/`shortReadingContent` on `MassReading`) behaves differently in scroll vs tab mode.** `_shortFormPart()` builds a synthetic `MassReadingPart` holding only the short-form projection of each content that has one (for Gospel, this now also carries over `acclamationAntiphon`/`acclamationAntiphonReference` from the long form, not just `biblicalRef`/`content`/`headline`). In **scroll mode**, `_ShortFormAnnouncement` ("Une forme brève est proposée plus bas", tap-to-scroll) is shown right after the Alléluia block and before the "Évangile" title of the long form (`_MassGospelContent.shortFormAnnouncement`, threaded down from `_ReadingPartTab`) — and the forme-brève block further down does *not* repeat the Alléluia (`hideAlleluiaInShortForm: true`, the default), since it was just shown once, above, in the same continuous scroll. In **tab mode**, the forme-brève tab has no such pointer (it's its own separate, independently-reachable tab) but *does* repeat the full Alléluia block (`hideAlleluiaInShortForm: false`), using the same acclamation text/reference as the long-form tab, so that tab reads as a complete, self-contained proclamation on its own. The evangelist announcement (`_MassGospelAnnouncement`) is shown for the forme brève in both modes — it used to be suppressed there, on the assumption it had already been shown once for the long form, which didn't hold once the two forms became separately navigable in tab mode.
- **The forme brève must live on the *same* `partContents` item as the long form, never as a second item in the list.** `MassGospel`/`MassReading` carry both the long-form fields (`biblicalRef`/`content`/...) and the short-form ones (`shortBiblicalRef`+`shortContent`, or `shortReadingRef`+`shortReadingContent`) together on one object. Nativity's `evening_mass` Gospel data used to model the forme brève as a *second* `partContents` entry instead (only `shortBiblicalRef`/`shortContent` set, everything else null) — since `_ReadingPartTab._buildPartContent` renders every `partContents` entry as a full alternative reading separated by "ou bien :", this produced a spurious "ou bien :" followed by a near-empty Gospel block (still showing an "Alléluia" heading with no acclamation text, and an empty "Évangile" title) between the long form's content and the forme-brève tab/block. Fixed by merging the two YAML items into one (see `offline-liturgy/docs/add_data_manual.md` § `mass` → `readingParts`, which documents this explicitly to prevent it recurring).
- **Empty prayers are hidden entirely, not shown as a placeholder.** `collect`, `offeringPrayer`, and `prayerAfterCommunion` each hide their own title+text block when null/empty (they don't fall through to `buildOrationWidgets`' default "no oration" placeholder text, unlike other offices' orations). In tab mode, the Offrandes/Communion tabs themselves disappear entirely when they'd have nothing left to show (`_hasOfferingTab`/`_hasCommunionTab` on `MassOfficeDisplay`). There is no "Bénédiction" tab at all — deliberately dropped, not just conditionally hidden.
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

- No "Common of Saints" Mass texts exist anywhere in the data yet — `overlayWithCommon` is wired up on both `Mass` and the pipeline but is currently a no-op in practice.
- Nativity, Epiphany, Baptism of the Lord, and Holy Family now have `mass:` data (entrance/communion antiphons, collect, offering prayer, prayer after communion). Nativity's `readingParts` are now complete for all four Masses (`evening_mass`, `night_mass`, `dawn_mass`, `day_mass`); Epiphany, Baptism of the Lord, and Holy Family still have `readingParts: null` — no Liturgy of the Word (readings/psalm/Gospel) renders for those yet. Ascension still has no `mass:` data at all. Palm Sunday's procession Gospel is an empty stub (`readingParts` present but unpopulated).
- Three Lyon sanctoral files use an older, incompatible `mass:` shape (`wordLiturgy`/`firstReading` or a bare `collect:`) that doesn't parse with the current `Mass`/`Masses` classes — predates this work, not yet migrated.
- `prefaceList` is not rendered anywhere in `MassOfficeDisplay` — it was removed from the Offrandes tab (it used to show as a raw reference string, with no preface-text library to resolve it into actual content) to make room for a dedicated preface display elsewhere in the app. The data (`Mass.prefaceList`) and the YAML content are untouched, only the Mass-view rendering was dropped.
