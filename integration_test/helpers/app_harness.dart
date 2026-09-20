import 'package:aelf_flutter/app_screens/aelf_home_page.dart';
import 'package:aelf_flutter/main.dart' as app;
import 'package:aelf_flutter/utils/settings.dart';
import 'package:aelf_flutter/widgets/left_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared plumbing for the integration suite.
///
/// These tests drive the real app on a real device/desktop, so they are slow
/// and are wired to run on merge requests only (see `.gitlab-ci.yml`).
///
/// Two conventions keep the suite stable:
///
/// 1. **One app launch per file.** The app owns timers, a connectivity
///    listener and in-flight AELF requests; relaunching it inside the same
///    process stacks those and leaks errors across tests. Each file therefore
///    boots once, inside a single `testWidgets`, and walks through its steps.
/// 2. **No assertions on liturgy text.** Content correctness is covered by the
///    fast unit tests over `test/fixtures/`. These tests assert navigation and
///    feature-flag behaviour, so they pass with or without a reachable API.

/// Boots the app with a seeded preferences store and waits until the startup
/// office selection has landed.
///
/// [prefs] seeds SharedPreferences before the app reads them, which is how a
/// test picks the state of `feature_offline_liturgy`.
///
/// Calls `runAelfApp()` rather than `main()`: the integration binding is
/// already installed by the time a test runs, and `main()` would install a
/// second one and trip an assertion in `BindingBase`.
Future<void> launchApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool showWhatsNew = false,
}) async {
  final seeded = <String, Object>{...prefs};

  // AelfHomePageState._showAboutPopUp() opens the "what's new" dialog whenever
  // the stored version differs from the running one — which is always true for
  // a freshly mocked preference store. Its modal barrier swallows every tap, so
  // unless a test is specifically about that dialog, record the running version
  // up front and start on the home page.
  if (!showWhatsNew && !seeded.containsKey(keyLastVersionInstalled)) {
    final info = await PackageInfo.fromPlatform();
    seeded[keyLastVersionInstalled] = '${info.version}.${info.buildNumber}';
  }

  SharedPreferences.setMockInitialValues(seeded);
  app.runAelfApp();

  await waitFor(tester, find.byType(AelfHomePage));

  // Belt and braces: if the dialog appeared anyway (a version string we could
  // not predict), close it so the drawer is reachable.
  await dismissWhatsNew(tester);

  // AelfHomePageState._computeCurrentOffice() picks the office for the current
  // time asynchronously and then jumps the PageView. Wait for the title to stop
  // moving, otherwise it lands after the test's first tap and overwrites it.
  await waitForStableTitle(tester);
}

/// Closes the "what's new" dialog if it is on screen. No-op otherwise.
Future<void> dismissWhatsNew(WidgetTester tester) async {
  await settle(tester, duration: const Duration(milliseconds: 800));

  final validate = find.widgetWithText(TextButton, 'Valider');
  if (validate.evaluate().isEmpty) return;

  await tester.tap(validate.first);
  await settle(tester);
}

/// Pumps until [finder] matches, or fails after [timeout].
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail(
      'Timed out after $timeout waiting for: ${finder.describeMatch(Plurality.one)}');
}

/// Pumps for a bounded time, then a little longer, and returns.
///
/// `pumpAndSettle` is unusable here: the app keeps a one-minute periodic timer
/// and a connectivity subscription alive, so the frame queue never drains.
Future<void> settle(
  WidgetTester tester, {
  Duration duration = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps until the AppBar title stops changing, so asynchronous startup
/// navigation cannot race the next interaction.
Future<void> waitForStableTitle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  String? previous;
  var stableFor = 0;

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    final current = currentSectionTitle(tester);
    if (current == previous) {
      if (++stableFor >= 10) return; // ~1s unchanged
    } else {
      previous = current;
      stableFor = 0;
    }
  }
}

/// Makes the section menu visible.
///
/// Above 800px wide the home page shows [LeftMenu] as a permanent side panel;
/// below that it lives in a [Drawer]. Handles both so the suite runs on a
/// phone, a tablet and a desktop window alike.
Future<void> openSectionMenu(WidgetTester tester) async {
  if (find.byType(LeftMenu).evaluate().isNotEmpty) return;

  tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
  await settle(tester);

  expect(find.byType(LeftMenu), findsOneWidget,
      reason: 'the section menu should be on screen');
}

/// Closes the drawer if one is open. No-op on wide layouts.
Future<void> closeSectionMenu(WidgetTester tester) async {
  final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
  if (scaffold.isDrawerOpen) {
    scaffold.closeDrawer();
    await settle(tester);
  }
}

/// Taps a section by its drawer label and waits for the page to switch.
Future<void> tapSection(WidgetTester tester, String title) async {
  await openSectionMenu(tester);

  final entry = find.widgetWithText(ListTile, title);
  expect(entry, findsOneWidget, reason: 'no drawer entry named "$title"');

  await tester.tap(entry);
  await settle(tester);
}

/// The drawer labels currently listed, in order.
List<String> listedSections(WidgetTester tester) {
  final menu = find.descendant(
    of: find.byType(LeftMenu),
    matching: find.byType(ListTile),
  );
  return menu
      .evaluate()
      .map((e) => ((e.widget as ListTile).title as Text).data!)
      .toList();
}

/// The current AppBar title, i.e. the section the user is looking at.
String currentSectionTitle(WidgetTester tester) {
  final title = find.descendant(
    of: find.byType(AppBar),
    matching: find.byType(Text),
  );
  if (title.evaluate().isEmpty) return '';
  return tester.widget<Text>(title.first).data ?? '';
}

/// Opens the settings screen through the app bar's 3-dot menu, the way a user
/// reaches it.
Future<void> openSettings(WidgetTester tester) async {
  await closeSectionMenu(tester);

  await tester.tap(find.byIcon(Icons.more_vert).first);
  await settle(tester);

  await tester.tap(find.text('Paramètres').last);
  await settle(tester);
}

/// Flips a [SwitchListTile] found by its label and waits for the rebuild.
Future<void> toggleSwitch(WidgetTester tester, String label) async {
  final tile = find.widgetWithText(SwitchListTile, label);
  expect(tile, findsOneWidget, reason: 'no switch labelled "$label"');

  await tester.ensureVisible(tile);
  await settle(tester, duration: const Duration(milliseconds: 500));
  await tester.tap(tile);
  await settle(tester);
}

/// Returns to the previous screen (e.g. from settings back to the home page).
///
/// Not `tester.pageBack()`: that matches the back button by its localized
/// tooltip, which differs between the app's en_US and fr_FR locales.
Future<void> goBack(WidgetTester tester) async {
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
  } else {
    Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
  }
  await settle(tester);
}
