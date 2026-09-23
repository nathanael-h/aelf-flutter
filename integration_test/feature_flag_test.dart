import 'package:aelf_flutter/utils/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_harness.dart';

/// The `feature_offline_liturgy` switch picks between the new (offline)
/// liturgy — the default — and the online API one. These tests drive it from
/// both ends: the menu must swap exactly one way when it is on, and exactly
/// the other way when it is off.
///
/// The swap is asserted on section *names*, not drawer labels: an offline
/// office is deliberately titled like the online one it replaces (both read
/// "Vêpres"), so only the name tells the two rows apart.
///
/// Only the menu is asserted here, not the offline office content — that is
/// still being built, and lives in `offline_liturgy_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const onlineOffices = [
    'messes',
    'lectures',
    'laudes',
    'tierce',
    'sexte',
    'none',
    'vepres',
    'complies',
    'informations',
  ];

  const offlineOffices = [
    'offline_mass',
    'offline_readings',
    'offline_morning',
    'offline_tierce',
    'offline_sexte',
    'offline_none',
    'offline_vespers',
    'offline_complines',
    'offline_calendar',
  ];

  testWidgets('on a fresh install, the menu shows the offline offices',
      (tester) async {
    // No stored flag: the new version is the default.
    await launchApp(tester);
    await openSectionMenu(tester);

    final listed = listedSectionNames(tester);

    for (final section in offlineOffices) {
      expect(listed, contains(section), reason: '"$section" is missing');
    }
    for (final section in onlineOffices) {
      expect(listed, isNot(contains(section)),
          reason: '"$section" is replaced by its offline twin');
    }

    expect(listed, contains('bible'),
        reason: 'the Bible is never swapped by the flag');

    // The labels a user actually reads: the offline offices borrow the online
    // titles, so nothing in the drawer announces itself as in-development.
    expect(listedSections(tester), containsAll(<String>['Messe', 'Vêpres']));
  });

  testWidgets('turning the switch on from settings swaps the menu over',
      (tester) async {
    // A user who switched the new version off earlier.
    await launchApp(tester, prefs: {keyFeatureOfflineLiturgy: false});

    // --- starts on the online offices -------------------------------------
    await openSectionMenu(tester);
    expect(listedSectionNames(tester), containsAll(onlineOffices));
    expect(
      listedSectionNames(tester).where((s) => s.startsWith('offline_')),
      isEmpty,
    );

    // --- the user opts in through the settings screen ---------------------
    await openSettings(tester);
    await toggleSwitch(tester, 'Lancer la nouvelle version de AELF');
    await goBack(tester);

    // --- the menu now offers the offline offices instead ------------------
    await openSectionMenu(tester);
    final afterOptIn = listedSectionNames(tester);

    expect(afterOptIn, containsAll(offlineOffices));
    for (final section in onlineOffices) {
      expect(afterOptIn, isNot(contains(section)), reason: section);
    }

    // --- and turning it back off restores the online offices --------------
    await openSettings(tester);
    await toggleSwitch(tester, 'Lancer la nouvelle version de AELF');
    await goBack(tester);

    await openSectionMenu(tester);
    final afterOptOut = listedSectionNames(tester);

    expect(afterOptOut, containsAll(onlineOffices));
    expect(afterOptOut.where((s) => s.startsWith('offline_')), isEmpty,
        reason: 'opting out must fully restore the online liturgy');
  });
}
