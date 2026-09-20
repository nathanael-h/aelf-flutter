import 'package:aelf_flutter/app_screens/aelf_home_page.dart';
import 'package:aelf_flutter/widgets/left_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_harness.dart';

/// Smoke test: the real app boots, renders its shell and lets the user move
/// between sections. Anything failing here is broken for every user, so this
/// runs first and the rest of the suite can assume a working shell.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the app boots and its shell works', (tester) async {
    await launchApp(tester);

    // --- boots to the home page -------------------------------------------
    expect(find.byType(AelfHomePage), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byType(AppBar), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'threw during startup');

    // --- opens on one of the app's own sections ---------------------------
    final startupSection = currentSectionTitle(tester);
    expect(startupSection, isNotEmpty);

    // --- the section menu lists sections ----------------------------------
    await openSectionMenu(tester);
    expect(find.byType(LeftMenu), findsOneWidget);

    final sections = listedSections(tester);
    expect(sections, isNotEmpty);
    expect(sections, contains('Bible'));
    expect(sections, contains(startupSection),
        reason: 'the section shown at startup must be listed in the menu');

    // --- navigating works both ways ---------------------------------------
    await tapSection(tester, 'Bible');
    expect(currentSectionTitle(tester), 'Bible');
    expect(tester.takeException(), isNull);

    await tapSection(tester, 'Messe');
    expect(currentSectionTitle(tester), 'Messe');
    expect(tester.takeException(), isNull);
  });
}
