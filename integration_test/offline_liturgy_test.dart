import 'package:aelf_flutter/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_harness.dart';

/// The in-development offline liturgy, exercised with the flag on.
///
/// This file is the one part of the suite that covers work in progress, so the
/// CI job running it is non-blocking (`allow_failure: true` in
/// `.gitlab-ci.yml`): a half-finished offline office should report itself
/// without holding up a merge request that only touches the online liturgy.
/// Everything that protects the online path is blocking instead.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Sections are addressed by name: with the flag on, an offline office is
  // titled exactly like the online one it replaces ("Vêpres", "Messe"), so the
  // label alone would not say which of the two opened.
  const offlineOffices = [
    'offline_readings',
    'offline_morning',
    'offline_tierce',
    'offline_sexte',
    'offline_none',
    'offline_vespers',
    'offline_complines',
  ];

  testWidgets('each offline office opens and renders something',
      (tester) async {
    await launchApp(tester, prefs: {keyFeatureOfflineLiturgy: true});

    for (final office in offlineOffices) {
      await tapSectionByName(tester, office);
      await closeSectionMenu(tester);

      // Offline offices compute their content from the offline_liturgy
      // package, which can take a moment on first use.
      await settle(tester, duration: const Duration(seconds: 5));

      expect(currentSectionTitle(tester), sectionTitle(office));
      expect(tester.takeException(), isNull,
          reason: '$office threw while rendering');
      expect(find.byType(Scaffold), findsWidgets,
          reason: '$office rendered nothing at all');
    }
  });

  testWidgets('the offline calendar opens', (tester) async {
    await launchApp(tester, prefs: {keyFeatureOfflineLiturgy: true});

    await tapSectionByName(tester, 'offline_calendar');
    await closeSectionMenu(tester);
    await settle(tester, duration: const Duration(seconds: 5));

    expect(currentSectionTitle(tester), 'Calendrier Liturgique');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mass opens its offline twin with the flag on', (tester) async {
    // Mass swaps like every other office now: with the flag on, the drawer's
    // "Messe" row is `offline_mass`. The online Mass is covered with the flag
    // off, in online_liturgy_test.dart.
    await launchApp(tester, prefs: {keyFeatureOfflineLiturgy: true});

    await tapSectionByName(tester, 'offline_mass');
    await closeSectionMenu(tester);
    await settle(tester, duration: const Duration(seconds: 5));

    expect(currentSectionTitle(tester), 'Messe');
    expect(find.byTooltip('Partager'), findsOneWidget,
        reason: 'ShareHelper.slugFor("offline_mass") resolves to "messe"');
    expect(tester.takeException(), isNull);
  });
}
