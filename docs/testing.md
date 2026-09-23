# Testing

Two lanes, split by how fast they are and what they protect.

| Lane | Runs | Command | Time |
| --- | --- | --- | --- |
| Unit + widget (`test/`) | Every commit | `flutter test` (or `dart tool/test_runner.dart`) | ~15s |
| Integration (`integration_test/`) | Merge requests + `master` | `scripts/run_integration_tests.sh` | ~2.5min |

## Why this split

The offline liturgy (`offline_liturgy_*` views, the `offline_liturgy` package)
sits behind the `feature_offline_liturgy` flag, which is now **on by default**
("Lancer la nouvelle version de AELF" in the settings). Users who switch it off
get the online AELF API path — mass, the Divine Office hours and the liturgical
informations — and a lot of UI is shared by both.

So the tests exist mainly to answer one question: *did this change break the
online liturgy, or the widgets both liturgies share?* The unit lane answers it
in seconds on every commit; the integration lane confirms it against the real
app before a merge. Tests that need the online path seed the flag to `false`
explicitly rather than relying on the default.

## Unit and widget tests — every commit

`flutter test`. No device, no network, no emulator.

`flutter test` interleaves everything the app prints (API downloads, liturgy
state logs) with its progress lines. For a readable run, use the wrapper CI
uses:

```
dart tool/test_runner.dart                        # like `flutter test`
dart tool/test_runner.dart -- test/utils          # any flutter test args after --
dart tool/test_runner.dart --junit build/test-results/unit.xml -- --coverage
dart tool/test_runner.dart --verbose              # also echo every print
```

It prints nothing for passing tests; for each failure, the output captured
during *that* test, then the error and stack; then a per-file summary and the
`flutter test … --plain-name …` commands to rerun what failed. `--junit` writes
a JUnit XML report. It honours `FLUTTER` (e.g. `FLUTTER="fvm flutter"`).

```
test/
  fixtures/      AELF API payloads, shaped exactly as they reach the parsers
  parsers/       MassParser, OfficeParser, InformationParser, routing
  utils/         correctAelfHTML, settings defaults, share URLs, colours
  models/        OfficeHeaderInfo.fromApi (the drawer header)
  states/        FeatureFlagsState, CurrentZoom
  widgets/       extractVerses, drawer visibility, verse alignment, rendering
  data/          appSections integrity
```

The load-bearing ones:

- **`test/fixtures/`** — trimmed but structurally faithful captures of the
  online API. `LiturgyState._getAELFLiturgyOnWeb` strips every key but the
  requested type, so each fixture has a single top-level key. If a test reading
  one of these fails, the online rendering changed.
- **`parsers/`** — characterization tests over the three parsers that turn API
  payloads into liturgy tabs. Tab order, antiphon lookup, the répons stitching,
  the doxology, degraded payloads.
- **`widgets/online_liturgy_rendering_test.dart`** — the widest net: fixture
  JSON → `LiturgyParserService` → `LiturgyWidgetBuilder`, pumped the way
  `LiturgyFormatter` pumps it. Every tab must build without throwing.
- **`utils/settings_test.dart` + `states/feature_flags_state_test.dart`** — the
  offline flag is on on a fresh install (and the serif font too), and
  `FeatureFlagsState` agrees synchronously, before the async prefs load
  resolves, or with the value `main()` preloaded.
- **`widgets/left_menu_sections_test.dart`** — nothing offline is listed while
  the flag is off; every online office it replaces has an offline twin to step
  into when the flag is on. Mass and Bible never swap.
- **`widgets/verse_alignment_test.dart`** — the layout invariant from
  `CLAUDE.md`: `BibleVerseId`, `verseIdPlaceholder` and `liturgyRowIndentWidth`
  measure the same width at every zoom level, and the right gap stays 15px.

### Region, location and office coherence

The riskiest coupling between the online and offline liturgies is the region
pair, and it has its own tests.

The app carries two region notions of very different sizes:

| | Count | Source |
| --- | --- | --- |
| Online regions | 8 | what `api.aelf.org` accepts |
| Offline locations | ~60 | the `offline_liturgy` tree: continents, countries, every French diocese |

Picking an offline location therefore has to be *translated* into an online
region, because Mass has no offline implementation and because the online path
is what everyone sees while the flag is off. `lib/utils/region_sync.dart` owns
that rule: walk the location up its parent chain until a known country is
reached, treat any id containing `africa` as `afrique`, and fall back to
`romain` at a root.

- **`test/utils/region_sync_test.dart`** runs it over the **real** location
  tree. The load-bearing assertion is that *every* node resolves to a region
  the API accepts — and to one `ShareHelper` accepts, so a share link cannot
  quietly point at the wrong calendar. A new diocese cannot slip through.
- **`test/utils/current_office_test.dart`** walks all 24 hours for a Sunday and
  a weekday, with the flag both ways, and checks every result is a section
  `appSections` defines *and* one `LeftMenu` lists for that flag state.
  Opening on a hidden section would strand the user.
- **`test/states/liturgy_state_coherence_test.dart`** builds a real
  `LiturgyState` and checks it applies all of that: startup defaults, an
  invalid stored region being replaced and written back, `selectOfflineLocation`
  syncing the online region, the two selections persisting independently, and
  the cache date arithmetic.

That last one needs a little setup, which the file does for you: `sqflite_ffi`
as the database factory and a mocked `path_provider` channel. Plugins that stay
unmocked (`device_info`, `connectivity`) are expected to fail there — the
production code degrades rather than throwing, and that degradation is itself
asserted.

### Shared widgets and the theme

A lot of the UI is used by *both* liturgies, so a change made while building
the offline one lands straight on the online one users see today:

| Shared | Used by | Test |
| --- | --- | --- |
| `theme_provider.dart` | every screen | `utils/theme_provider_test.dart` |
| `LeftMenuOfficeHeader` | online API + offline header | `widgets/shared_office_header_test.dart` |
| `LiturgyRow`, `LiturgyPartTitle` | all online parts + 10 offline widgets | `widgets/shared_liturgy_parts_test.dart` |
| `BibleVerseId`, `verseIdPlaceholder` | online content + offline psalms | `widgets/verse_alignment_test.dart` |
| drawer chrome | every section | `widgets/shared_drawer_chrome_test.dart` |
| `YamlTextParser` | shared titles + all offline text | `parsers/yaml_text_parser_test.dart` |

The theme's two `ThemeExtension`s are the subtle part. Widgets reach them
through `AelfLectureColors.of` / `AelfLiturgicalColors.of`, which **fall back
to a hardcoded palette** when the extension is missing rather than failing — so
forgetting to register one on a theme changes colours silently. The tests
assert both themes carry both extensions, and that `ThemeNotifier.currentTheme`
keeps them through its `copyWith`.

`LeftMenuOfficeHeader` is the clearest shared surface: the same widget renders
the header whether the office came from the API or from `offline_liturgy`,
because both are normalized through `OfficeHeaderInfo` first. One test renders
the same day from both sources and checks they come out identical; another
checks an English offline colour name resolves to the same colour as its French
API equivalent.

### Adding a fixture

Drop the JSON in `test/fixtures/`, keep a single top-level key, and load it
with `loadFixture('name.json')`. See `test/fixtures/README.md`.

## Integration tests — merge requests and `master`

They drive the real app on a real device or desktop, so they are slow and gate
merges rather than every push. They also run on a direct push to `master`.

```
scripts/run_integration_tests.sh                    # everything, on linux
scripts/run_integration_tests.sh linux              # same, explicit
scripts/run_integration_tests.sh emulator-5554      # on an Android device
scripts/run_integration_tests.sh linux integration_test/feature_flag_test.dart
```

Run one file at a time. `flutter test integration_test -d linux` starts a fresh
app instance per file and they race for the same debug connection — the script
exists to avoid that. Each file goes through `tool/test_runner.dart` and gets
its own report in `build/test-results/integration-<file>.xml`.

| File | What it protects | CI |
| --- | --- | --- |
| `app_launch_test.dart` | the app boots, the shell renders, navigation works | blocking |
| `online_liturgy_test.dart` | with the flag off, every online office opens; nothing offline leaks in | blocking |
| `feature_flag_test.dart` | fresh install is on the offline offices; the menu swaps correctly both ways | blocking |
| `offline_liturgy_test.dart` | the in-development offline offices | non-blocking |

`offline_liturgy_test.dart` is `allow_failure: true`: a half-finished offline
office should report itself without holding up a merge request that only
touches the online liturgy.

### Conventions

Two rules keep the suite stable — `integration_test/helpers/app_harness.dart`
has the details:

1. **One app launch per file**, inside a single `testWidgets`. The app owns
   timers, a connectivity listener and in-flight AELF requests; relaunching it
   in the same process stacks those and leaks errors between tests.
2. **No assertions on liturgy text.** These tests assert navigation and
   feature-flag behaviour, so they pass with or without a reachable AELF API.
   Content correctness belongs in the unit lane.

The harness also handles the two things that otherwise break every run:

- `launchApp()` calls `runAelfApp()`, not `main()` — `main()` installs a
  binding and the integration binding is already installed.
- It seeds `keyLastVersionInstalled` so the "what's new" dialog does not open;
  its modal barrier swallows every tap. Pass `showWhatsNew: true` to test it.

`pumpAndSettle` is unusable here: the app keeps a one-minute periodic timer
alive, so the frame queue never drains. Use `settle()`, `waitFor()` or
`waitForStableTitle()` from the harness instead.

### flutter drive

`test_driver/integration_test.dart` exists for the cases `flutter test` cannot
cover — screenshots, or a device only the driver can reach:

```
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/online_liturgy_test.dart \
  -d linux
```

## Marionette

`marionette_flutter` is wired into `main()` in debug builds and exposes the
running app to an MCP client for interactive exploration — inspecting the
widget tree, tapping, entering text, hot reload. It is a **development** tool,
not part of CI: it needs an app someone already started, and it has no
assertions.

Use it to work out how to reach a screen, then encode what you learned as an
`integration_test/` case.

```
flutter run -d linux            # note the VM service URI it prints
```

Most widgets carry no `ValueKey`, so Marionette matches them by text or type.
Add keys where you need reliable targeting.

## CI

`.gitlab-ci.yml`, `test` stage:

| Job | When | Blocking |
| --- | --- | --- |
| `format` | branch push + MR | no (pre-existing) |
| `analyze` | branch push + MR | yes (`--no-fatal-infos`) |
| `unit-test` | branch push + MR | yes |
| `integration-test` | MR + `master` | yes |
| `integration-test-offline` | MR + `master` | no |

`analyze` passes `--no-fatal-infos` because the tree carries pre-existing style
lints; new warnings and errors still fail the job.

The integration jobs install the GTK toolchain and run the suite under Xvfb on
a `saas-linux-medium-amd64` runner (apt output goes to `apt.log` and is only
printed if the install fails).

### Test reports

`unit-test` and both integration jobs upload their JUnit files
(`build/test-results/*.xml`, also kept as artifacts for a week, pass or fail)
as `artifacts:reports:junit`. GitLab shows them in the pipeline's **Tests** tab
and in the merge request's **Test summary**, compared against `master`. Each
test case carries the output captured while it ran, so a failure's app logs are
one click away rather than somewhere in the job log.

### One pipeline per ref

Feature branches only run in merge request pipelines: pushing a branch without
an MR runs nothing, and opening the MR starts its single pipeline. `master` and
tags run on push, and **Build > Pipelines > Run pipeline** still works on any
branch (e.g. for a manual `build-android` without an MR). Pipelines superseded
by a newer commit are auto-cancelled (`interruptible: true` by default;
`deploy-ios` opts out).

Don't go back to keying branch pipelines on `$CI_OPEN_MERGE_REQUESTS`: pushing
a branch and opening its MR right after races, and runs both pipelines.
