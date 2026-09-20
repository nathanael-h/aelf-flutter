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

  const offlineOffices = [
    'Lectures (nouveau)',
    'Laudes (nouveau)',
    'Tierce (nouveau)',
    'Sexte (nouveau)',
    'None (nouveau)',
    'Vêpres (nouveau)',
    'Complies (nouveau)',
  ];

  testWidgets('each offline office opens and renders something',
      (tester) async {
    await launchApp(tester, prefs: {keyFeatureOfflineLiturgy: true});

    for (final office in offlineOffices) {
      await tapSection(tester, office);
      await closeSectionMenu(tester);

      // Offline offices compute their content from the offline_liturgy
      // package, which can take a moment on first use.
      await settle(tester, duration: const Duration(seconds: 5));

      expect(currentSectionTitle(tester), office);
      expect(tester.takeException(), isNull,
          reason: '$office threw while rendering');
      expect(find.byType(Scaffold), findsWidgets,
          reason: '$office rendered nothing at all');
    }
  });

  testWidgets('the offline calendar opens', (tester) async {
    await launchApp(tester, prefs: {keyFeatureOfflineLiturgy: true});

    await tapSection(tester, 'Calendrier Liturgique');
    await closeSectionMenu(tester);
    await settle(tester, duration: const Duration(seconds: 5));

    expect(currentSectionTitle(tester), 'Calendrier Liturgique');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mass still comes from the online API with the flag on',
      (tester) async {
    // Mass has no offline implementation; it must keep working untouched.
    await launchApp(tester, prefs: {keyFeatureOfflineLiturgy: true});

    await tapSection(tester, 'Messe');
    await closeSectionMenu(tester);

    expect(currentSectionTitle(tester), 'Messe');
    expect(find.byTooltip('Partager'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
