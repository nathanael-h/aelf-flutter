<!--
Guidance for AI coding agents working on the `aelf_flutter` repository.
Keep this concise and actionable — reference files and patterns an agent should read
before making changes. Update when workflows or conventions change.
-->

# Copilot instructions — aelf_flutter

Overview
- This repository contains a Flutter app (`aelf_flutter/`) and a helper Dart package (`offline-liturgy/`) that generates liturgical calendars and content.
- High-value entry points: `aelf_flutter/lib/` (UI), `offline-liturgy/lib/` (calendar & data generation), and `assets/` (precomputed JSON, hymn/psalm YAML).

Big-picture architecture
- `offline-liturgy` is a standalone Dart package that computes liturgical data (calendar, compline definitions) and emits JSON/YAML used by the Flutter app.
  - Key function: `complineDefinitionResolution(...)` (see `offline-liturgy` package docs/README and `lib` sources).
- `aelf_flutter` is a Flutter UI that consumes the generated assets. Primary UI widgets live in `aelf_flutter/lib/widgets/` and follow a consistent pattern:
  - Liturgy parts are implemented as `liturgy_part_*.dart` widgets which render content using `flutter_html` or YAML/multiline parsers.
  - Common layout: verse placeholder + right-side content. The reusable component `lib/widgets/liturgy_row.dart` centralizes that pattern.

Developer workflows (how to run & test locally)
- Install Flutter (matching the project's SDK). Some subfolders include `.fvm/` — the project may use FVM; use `fvm flutter` where appropriate.
- From `aelf_flutter/`:
  - Install deps: `flutter pub get`
  - Run app on a device: `flutter run -d <device-id>`
  - Analyzer: `dart analyze` or `flutter analyze`
  - Tests: `flutter test`
  - Format: `dart format .`
- If you edit `offline-liturgy`, rebuild the assets JSON used by the app (check `scripts/` or README.md in `offline-liturgy/`). The app expects generated files under `assets/` (e.g. `assets/calendar.json`, `assets/libraries/*`).

Project-specific conventions & patterns
- UI layout pattern: most `liturgy_part_*` widgets follow: verse placeholder + Expanded content. Use `LiturgyRow(builder: (ctx, zoom) => ...)` to respect `CurrentZoom` provider and keep layout consistent.
  - Use `hideVerseIdPlaceholder: true` to hide the placeholder when needed.
- Zoom / sizing: the app uses a `CurrentZoom` provider. Sizes are computed like: `fontSize * (zoom ?? 100) / 100`. Respect this pattern when changing text sizes.
- HTML content: content frequently contains HTML stored in YAML/JSON assets. Widgets use `flutter_html` to render it and define styles maps keyed by selectors.
  - See `lib/widgets/liturgy_part_content.dart`, `lib/widgets/liturgy_part_intro.dart`, and `lib/widgets/liturgy_content.dart` (utility `extractVerses`) for parsing/rendering patterns.
- Text formats: there are two formats in the codebase — legacy HTML and YAML-based markup. `liturgy_part_formatted_text.dart` detects format and dispatches to appropriate parsers (`FormattedTextParser` / `YamlTextParser`).
- Keep changes minimal and backward-compatible: prefer refactors that preserve current widget APIs (avoid renaming or removing public constructors used across many files).

Integration points & external dependencies
- `flutter_html` package is used widely for rendering HTML content.
- `provider` is used for state (e.g., `CurrentZoom`).
- `offline-liturgy` produces the canonical liturgical data used by the app — changing its output schema requires coordinated updates in `aelf_flutter/lib`.
- CI: README references Bitrise and GitLab CI. Releases and distribution may be handled by Bitrise; for iOS builds you need a macOS environment with Xcode and CocoaPods.

Files an agent should read first (in order)
- `aelf_flutter/lib/widgets/liturgy_row.dart` — central layout abstraction for liturgy parts
- `aelf_flutter/lib/widgets/liturgy_part_*.dart` — examples of how UI pieces are composed (subtitle, title, intro, content, antiphon, commentary)
- `aelf_flutter/lib/widgets/liturgy_part_content.dart` — verse extraction + rendering logic
- `aelf_flutter/lib/widgets/liturgy_content.dart` — helper `extractVerses` (HTML parsing logic)
- `offline-liturgy/README.md` and `offline-liturgy/lib/` — calendar generation and schema for liturgical data
- `pubspec.yaml` (root) — packages & assets declared; update here when adding dependencies or assets

Agent behavior rules (concise, project-specific)
- Preserve UI APIs: do not rename public constructors or change widget signatures without updating all callers.
- Use `LiturgyRow` for the verse placeholder + content layout. When adding new liturgy part widgets, prefer the `builder` pattern so zoom remains consistent.
- When editing files, run `dart format` and `dart analyze` locally; include code changes that fix analysis issues when safe.
- If you change the assets or `offline-liturgy` output schema, update `aelf_flutter` code that deserializes the assets and add a short migration note in the commit message.
- Prefer small, testable PRs. If a change touches both `offline-liturgy` and `aelf_flutter`, split into two commits: (1) `offline-liturgy` change + regenerated assets, (2) `aelf_flutter` deserialization + UI changes referencing the regenerated assets.

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
