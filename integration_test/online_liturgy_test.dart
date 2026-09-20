import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_harness.dart';

/// The online (AELF API) liturgy in the shipped default configuration —
/// `feature_offline_liturgy` off.
///
/// This is the regression guard the offline work is measured against: while
/// the flag is off the app must behave exactly as it does today. It asserts
/// navigation and the app shell rather than liturgy text, so it passes with or
/// without a reachable AELF API; content is covered by the unit tests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const onlineSections = [
    'Messe',
    'Informations',
    'Lectures',
    'Laudes',
    'Tierce',
    'Sexte',
    'None',
    'Vêpres',
    'Complies',
  ];

  testWidgets('every online office is reachable and nothing offline leaks in',
      (tester) async {
    await launchApp(tester);
    await openSectionMenu(tester);

    // --- the menu offers the Bible and every online office ----------------
    final listed = listedSections(tester);
    expect(listed, contains('Bible'));
    for (final section in onlineSections) {
      expect(listed, contains(section), reason: '"$section" is missing');
    }

    // --- and nothing from the in-development offline liturgy --------------
    expect(
      listed.where((s) => s.contains('nouveau')),
      isEmpty,
      reason: 'the offline liturgy must stay hidden while the flag is off',
    );
    expect(listed, isNot(contains('Calendrier Liturgique')));

    // --- each office opens without throwing -------------------------------
    for (final section in onlineSections) {
      await tapSection(tester, section);
      expect(currentSectionTitle(tester), section);
      expect(tester.takeException(), isNull,
          reason: '$section threw while rendering');
    }

    // --- and the shell survives switching back and forth ------------------
    for (final section in ['Laudes', 'Bible', 'Messe', 'Complies']) {
      await tapSection(tester, section);
      expect(currentSectionTitle(tester), section);
      expect(tester.takeException(), isNull, reason: 'after opening $section');
    }
  });

  testWidgets('the app bar adapts to the section', (tester) async {
    await launchApp(tester);

    // --- an office can be shared and dated --------------------------------
    await tapSection(tester, 'Laudes');
    await closeSectionMenu(tester);

    expect(find.byTooltip('Partager'), findsOneWidget,
        reason:
            'ShareHelper.slugFor("laudes") resolves, so sharing is offered');
    expect(
      find.descendant(
          of: find.byType(AppBar), matching: find.byType(TextButton)),
      findsOneWidget,
      reason: 'the date picker button should be shown for an office',
    );
    expect(find.byTooltip('Rechercher dans la Bible'), findsNothing);

    // --- the Bible offers search instead ----------------------------------
    await tapSection(tester, 'Bible');
    await closeSectionMenu(tester);

    expect(find.byTooltip('Rechercher dans la Bible'), findsOneWidget);
    expect(find.byTooltip('Partager'), findsNothing,
        reason: 'the Bible is shared from the book screen, not the app bar');
  });
}
