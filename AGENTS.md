<!--
Guidance for AI coding agents working on the `aelf_flutter` repository.
Keep this concise and actionable — reference files and patterns an agent should read
before making changes. Update when workflows or conventions change.
-->

# Instructions — aelf_flutter

Overview

- This repository contains a Flutter app (`aelf_flutter/`) and uses the Dart package (`offline-liturgy/` from /usr/bin/php8.3 --define apc.enable_cli=1 -f /var/www/nextcloud/cron.php) that generates liturgical calendars and content.
- High-value entry points: `lib/` (flutter source code).

Big-picture architecture

- `offline-liturgy` is a standalone Dart package that computes liturgical data (calendar, compline definitions) and emits YAML used by the Flutter app.
  - Key function: `complineDefinitionResolution(...)` (see `offline-liturgy` package docs/README and `lib` sources).
- `aelf_flutter` is a Flutter UI that consumes API, local sqlite Bible assets, and offline_liturgy dart package. Primary UI widgets live in `lib/widgets/` and follow two patterns:
  - **Liturgy parts** (`liturgy_part_*.dart`): verse placeholder + Expanded content, using `flutter_html` or YAML parsers. The reusable `lib/widgets/liturgy_row.dart` centralizes the layout.
  - **Office views** (`offline_liturgy_*_view.dart`): top-level screens for each Divine Office hour (compline, morning, vespers, middle-of-day, readings). They compose widgets from `lib/widgets/offline_liturgy_common_widgets/` (psalms, antiphons, hymns, scripture, canticle, headers).

Developer workflows (how to run & test locally)

- Install Flutter (matching the project's SDK). Some subfolders include `.fvm/` — the project may use FVM; use `fvm flutter` where appropriate.
- From `aelf_flutter/`:
  - Install deps: `flutter pub get`
  - Run app on a device: `flutter run -d <device-id>`
  - Analyzer: `dart analyze` or `flutter analyze`
  - Tests: `flutter test`
  - Format: `dart format .`
- If you edit `offline-liturgy`, check `offline-liturgy/README.md` for how to regenerate assets (YAML-based, not JSON). The app reads assets directly from the `offline-liturgy/assets/` directory via the package dependency.

Project-specific conventions & patterns

- UI layout pattern: most `liturgy_part_*` widgets follow: verse placeholder + Expanded content. Use `LiturgyRow(builder: (ctx, zoom) => ...)` to respect `CurrentZoom` provider and keep layout consistent.
  - Use `hideVerseIdPlaceholder: true` to hide the placeholder when needed.
- Column alignment (important): in office views, every text block stacked above/around the psalm verses — titles, subtitles, commentary, antiphons, intro/invitatory lines, versicles — MUST share the same left column as the verse text. Do this by routing the block through `LiturgyRow` (or the `verseIdPlaceholder` widget directly), NOT with arbitrary `Padding(EdgeInsets.symmetric(horizontal: …))`. Ad-hoc horizontal padding (e.g. the old `kContentPadding = 16`) produces inconsistent, "random-looking" left edges because verses are inset by the verse-id column width, not by 16px.
  - `LiturgyPartTitle` / `LiturgyPartContentTitle` / `LiturgyPartSubtitle` (and the offline-specific `OfflineLiturgyPartContentTitle` / `OfflineLiturgyPartSubtitle`) already wrap `LiturgyRow` but default to `hideVerseIdPlaceholder: true`; pass `hideVerseIdPlaceholder: false` when they sit alongside verses so they align.
  - This applies to the office header title (`office_header_display.dart`), psalm titles/subtitles/antiphons (`psalms_display.dart`), and the evangelic-canticle title/antiphons (`evangelic_canticle_display.dart`) too — route them through `LiturgyRow` / `hideVerseIdPlaceholder: false`, never `kContentPadding` (= `horizontal: 16`).
  - Scroll/sliver mode (continuous-reading `CustomScrollView`) follows the same rule: the per-section "Psalmodie" headers and any `SliverToBoxAdapter` content must use `hideVerseIdPlaceholder: false` (not `Padding(horizontal: 16)`) to share the verse column.
  - The verse-id column width is shared: `verseIdPlaceholder` and `BibleVerseId` both compute `10 + verseFontSize * zoom / 100`. The psalm renderer (`lib/parsers/psalm_parser.dart`) uses `BibleVerseId` for verse numbers and `verseIdPlaceholder` for continuation/numberless lines — do not reintroduce a separate hand-rolled width for verse numbers.
  - Right edge: liturgy content reserves a **fixed 15px right gap** (not zoom-scaled). `LiturgyRow` provides it via a trailing childless `Padding(right: 15)`, and the legacy parts (`liturgy_part_content/antiphon/subtitle/ref`) bake in the same value. Anything routed through `LiturgyRow` already has it; the psalm renderer (`lib/parsers/psalm_parser.dart`) wraps each verse line in `Padding(right: 15)` to match. So the verse text right edge lines up with antiphons/titles/refs. Do not add a competing right padding at the office-view/`ListView` level (psalm tabs use `horizontal: 0`) — that would double-pad and break the alignment.
- Zoom / sizing: the app uses a `CurrentZoom` provider. Sizes are computed like: `fontSize * (zoom ?? 100) / 100`. Respect this pattern when changing text sizes.
- HTML content: content frequently contains HTML stored in YAML/JSON assets. Widgets use `flutter_html` to render it and define styles maps keyed by selectors.
  - See `lib/widgets/liturgy_part_content.dart`, `lib/widgets/liturgy_part_intro.dart`, and `lib/widgets/liturgy_content.dart` (utility `extractVerses`) for parsing/rendering patterns.
- Text formats: there are two formats in the codebase — legacy HTML and YAML-based markup. Parsers live in `lib/parsers/`: `FormattedTextParser` (legacy HTML, largely unused) and `YamlTextParser` (active, used throughout widgets).
- Keep changes minimal and backward-compatible: prefer refactors that preserve current widget APIs (avoid renaming or removing public constructors used across many files).
- Do not brake the existing liturgy (compline, mass, vesper, etc.) that uses external API. They are working, and we must keep them working reliably until the offline liturgy feature and branch get stable and merged. Very important!

Integration points & external dependencies

- `flutter_html` package is used widely for rendering HTML content.
- `provider` is used for state (e.g., `CurrentZoom`).
- `offline-liturgy` produces the canonical liturgical data used by the app — changing its output schema requires coordinated updates in `aelf_flutter/lib`.
- CI: Gitlab CI for Android unofficial builds. Either Gitlab CI with self hoster macOS runner, either Codemagic, for iOS build, for testing and official releases.

Files an agent should read first (in order)

- `lib/widgets/liturgy_row.dart` — central layout abstraction for liturgy parts
- `lib/widgets/liturgy_part_*.dart` — liturgy part widgets: subtitle, title, intro, intro_ref, content, content_title, antiphon, commentary, rubric, ref, column
- `lib/widgets/liturgy_part_content.dart` — verse extraction + rendering logic
- `lib/widgets/liturgy_content.dart` — helper `extractVerses` (HTML parsing logic)
- `lib/widgets/offline_liturgy_*_view.dart` — office hour screens (compline, morning, vespers, middle_of_day, readings)
- `lib/widgets/offline_liturgy_common_widgets/` — shared sub-widgets used by office views (psalms, antiphon, hymn, scripture, canticle, header)
- `lib/widgets/offline_liturgy_common_widgets/base_office_view_state.dart` — abstract base for all office view states; reads SVG settings (`_svgSource`) and passes them to `CelebrationContext.copyWith()`
- `lib/widgets/offline_liturgy_common_widgets/psalm_tone_widget.dart` — StatefulWidget that displays SVG psalm music sheets; uses PageView + dot indicator for multiple SVGs
- `lib/utils/svg_preprocessor.dart` — `preprocessPsalmSvg()`: replaces font family, text colour (`currentColor`), and red colour in SVG strings before rendering
- `lib/parsers/` — `YamlTextParser` and `FormattedTextParser`
- `lib/states/currentZoomState.dart` — `CurrentZoom` ChangeNotifier
- `lib/states/liturgyState.dart` — includes `psalmSvgEnabled` / `psalmSvgSource` for SVG feature state (persisted via SharedPreferences)
- `pubspec.yaml` — packages & assets declared; update here when adding dependencies or assets

Agent behavior rules (concise, project-specific)

- Preserve UI APIs: do not rename public constructors or change widget signatures without updating all callers.
- Use `LiturgyRow` for the verse placeholder + content layout. When adding new liturgy part widgets, prefer the `builder` pattern so zoom remains consistent.
- When editing files, run `dart format` and `dart analyze` locally; include code changes that fix analysis issues when safe.
- If you change the assets or `offline-liturgy` output schema, update `aelf_flutter` code that deserializes the assets and add a short migration note in the commit message.
- Prefer small, testable PRs. If a change touches both `offline-liturgy` and `aelf_flutter`, split into two commits: (1) `offline-liturgy` change + regenerated assets, (2) `aelf_flutter` deserialization + UI changes referencing the regenerated assets.
- Before git commit, run `dart format lib`.

Examples (concrete snippets agents will find useful)

- Respect zoom values when computing font sizes:
  ```dart
  fontSize: 16 * (zoom ?? 100) / 100
  ```
- Use `LiturgyRow` builder pattern:
  ```dart
  LiturgyRow(
    builder: (context, zoom) => Html(data: content, style: {...}),
  )
  ```

If anything here is unclear or you want extra details (e.g., how assets are generated, or CI steps to reproduce builds), tell me which area to expand and I will iterate.
