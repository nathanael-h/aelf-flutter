import 'package:aelf_flutter/utils/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_harness.dart';

/// The `feature_offline_liturgy` switch is what keeps the in-development
/// offline liturgy away from users. These tests drive it from both ends: the
/// menu must swap exactly one way when it is on, and exactly the other way
/// when it is off.
///
/// Only the menu is asserted here, not the offline office content — that is
/// still being built, and lives in `offline_liturgy_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const onlineOffices = [
    'Lectures',
    'Laudes',
    'Tierce',
    'Sexte',
    'None',
    'Vêpres',
    'Complies',
    'Informations',
  ];

  const offlineOffices = [
    'Lectures (nouveau)',
    'Laudes (nouveau)',
    'Tierce (nouveau)',
    'Sexte (nouveau)',
    'None (nouveau)',
    'Vêpres (nouveau)',
    'Complies (nouveau)',
    'Calendrier Liturgique',
  ];

  testWidgets('with the flag already on, the menu shows the offline offices',
      (tester) async {
    await launchApp(tester, prefs: {keyFeatureOfflineLiturgy: true});
    await openSectionMenu(tester);

    final listed = listedSections(tester);

    for (final section in offlineOffices) {
      expect(listed, contains(section), reason: '"$section" is missing');
    }
    for (final section in onlineOffices) {
      expect(listed, isNot(contains(section)),
          reason: '"$section" is replaced by its offline twin');
    }

    // Mass has no offline implementation yet, so it never swaps.
    expect(listed, contains('Messe'));
    expect(listed, contains('Bible'));
  });

  testWidgets('turning the switch on from settings swaps the menu over',
      (tester) async {
    await launchApp(tester);

    // --- starts on the online offices -------------------------------------
    await openSectionMenu(tester);
    expect(listedSections(tester), containsAll(onlineOffices));
    expect(
      listedSections(tester).where((s) => s.contains('nouveau')),
      isEmpty,
    );

    // --- the user opts in through the settings screen ---------------------
    await openSettings(tester);
    await toggleSwitch(tester, 'Lancer la nouvelle version de AELF');
    await goBack(tester);

    // --- the menu now offers the offline offices instead ------------------
    await openSectionMenu(tester);
    final afterOptIn = listedSections(tester);

    expect(afterOptIn, containsAll(offlineOffices));
    for (final section in onlineOffices) {
      expect(afterOptIn, isNot(contains(section)), reason: section);
    }
    expect(afterOptIn, contains('Messe'),
        reason: 'Mass stays on the online API either way');

    // --- and turning it back off restores the online offices --------------
    await openSettings(tester);
    await toggleSwitch(tester, 'Lancer la nouvelle version de AELF');
    await goBack(tester);

    await openSectionMenu(tester);
    final afterOptOut = listedSections(tester);

    expect(afterOptOut, containsAll(onlineOffices));
    expect(afterOptOut.where((s) => s.contains('nouveau')), isEmpty,
        reason: 'opting out must fully restore the online liturgy');
  });
}
