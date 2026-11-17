import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/localSolemnitiesState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_mass_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A memorial celebrated at Mass lets the reader pick, in one place, among
/// three combined choices for its texts — see offline_liturgy_mass_view.dart
/// (_MassTextsChoiceSelector): the day's readings with no Common at all (the
/// default used by simplified mode), the day's readings with the Common,
/// or — only when it would make a difference — all of it from the proper
/// and the Common. Simplified mode hides the choice entirely.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final date = DateTime(2027, 11, 15);
  final definition = CelebrationContext(
    celebrationCode: 'roman/some_bishop',
    celebrationTitle: 'roman/some_bishop',
    officeDescription: 'Un évêque',
    ferialCode: 'ot_32_1',
    date: date,
    precedence: 10,
    commonList: const ['pastors', 'doctors'],
    commonTitles: const {
      'pastors': 'Commun des pasteurs',
      'doctors': 'Commun des docteurs',
    },
    isCelebrable: true,
    dataLoader: FileSystemDataLoader(),
  );

  // Mutable record of the last callback each received, read after a tap.
  final readingSourceCalls = <MassReadingSource>[];
  final commonCalls = <String?>[];

  Future<void> pump(
    WidgetTester tester, {
    required bool advancedMode,
    String? selectedCommon,
    List<MassReadingSource> massReadingSources = const [
      MassReadingSource.day,
      MassReadingSource.all,
    ],
  }) async {
    tester.view.physicalSize = const Size(800, 20000);
    addTearDown(tester.view.resetPhysicalSize);
    readingSourceCalls.clear();
    commonCalls.clear();
    final massDefinition =
        definition.copyWith(massReadingSources: massReadingSources);
    final featureFlags = FeatureFlagsState();
    await featureFlags.setAdvancedModeEnabled(advancedMode);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => SelectedCelebrationState()),
          ChangeNotifierProvider(create: (_) => LocalSolemnitiesState()),
          ChangeNotifierProvider<LiturgyState>.value(
              value: _ScrollLiturgyState()),
          ChangeNotifierProvider.value(value: featureFlags),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MassOfficeDisplay(
              celebrationKey: 'day',
              massDefinition: massDefinition,
              massData: Mass(),
              selectedCommon: selectedCommon,
              massList: {'day': massDefinition},
              onCelebrationChanged: (_) {},
              onCommonChanged: commonCalls.add,
              onPrecedenceOverridden: (_, __) {},
              readingSource: MassReadingSource.day,
              onReadingSourceChanged: readingSourceCalls.add,
              calendar: Calendar(),
              date: date,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('mode développé', () {
    testWidgets('shows the three choices', (tester) async {
      await pump(tester, advancedMode: true, selectedCommon: 'pastors');
      expect(find.text('Lectures du jour et propre du saint'), findsOneWidget);
      expect(find.text('Lectures du jour, propre et commun du saint'),
          findsOneWidget);
      expect(find.text('Toutes les lectures de la mémoire'), findsOneWidget);
      // The Common itself is a separate, second choice below
      expect(find.text('Commun des pasteurs'), findsOneWidget);
      expect(find.text('Commun des docteurs'), findsOneWidget);
      expect(find.text('Pas de commun'), findsNothing);
    });

    testWidgets('picking "day, no Common" clears the Common', (tester) async {
      await pump(tester, advancedMode: true, selectedCommon: 'pastors');
      await tester.tap(find.text('Lectures du jour et propre du saint'));
      expect(readingSourceCalls, [MassReadingSource.day]);
      expect(commonCalls, [null]);
    });

    testWidgets('picking "all" keeps the Common already chosen',
        (tester) async {
      await pump(tester, advancedMode: true, selectedCommon: 'pastors');
      await tester.tap(find.text('Toutes les lectures de la mémoire'));
      expect(readingSourceCalls, [MassReadingSource.all]);
      expect(commonCalls, ['pastors']);
    });

    testWidgets('picking "day, with Common" from "no Common" picks the first',
        (tester) async {
      await pump(tester, advancedMode: true, selectedCommon: null);
      await tester
          .tap(find.text('Lectures du jour, propre et commun du saint'));
      expect(readingSourceCalls, [MassReadingSource.day]);
      expect(commonCalls, ['pastors']);
    });
  });

  group('mode développé — propre complet sans besoin du commun', () {
    // e.g. sainte Élisabeth de Hongrie (17 nov.): sa messe propre a déjà ses
    // 3 lectures, donc le commun ne complète rien (pas de
    // MassReadingSource.all) — seul MassReadingSource.proper est offert.
    const sources = [MassReadingSource.day, MassReadingSource.proper];

    testWidgets('still shows the third choice', (tester) async {
      await pump(tester,
          advancedMode: true,
          selectedCommon: 'pastors',
          massReadingSources: sources);
      expect(find.text('Lectures du jour et propre du saint'), findsOneWidget);
      expect(find.text('Lectures du jour, propre et commun du saint'),
          findsOneWidget);
      expect(find.text('Toutes les lectures de la mémoire'), findsOneWidget);
    });

    testWidgets('picking it uses MassReadingSource.proper, not .all',
        (tester) async {
      await pump(tester,
          advancedMode: true,
          selectedCommon: null,
          massReadingSources: sources);
      await tester.tap(find.text('Toutes les lectures de la mémoire'));
      expect(readingSourceCalls, [MassReadingSource.proper]);
      expect(commonCalls, ['pastors']);
    });
  });

  testWidgets(
      'when the proper has no readings of its own, the third choice is gone',
      (tester) async {
    await pump(tester,
        advancedMode: true,
        selectedCommon: 'pastors',
        massReadingSources: const [MassReadingSource.day]);
    expect(find.text('Toutes les lectures de la mémoire'), findsNothing);
  });

  testWidgets('mode simplifié hides the choice entirely', (tester) async {
    await pump(tester, advancedMode: false, selectedCommon: null);
    expect(find.text('Lectures du jour et propre du saint'), findsNothing);
    expect(
        find.text('Lectures du jour, propre et commun du saint'), findsNothing);
    expect(find.text('Toutes les lectures de la mémoire'), findsNothing);
    expect(find.text('Commun des pasteurs'), findsNothing);
  });
}

class _ScrollLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  bool get useScrollMode => true;

  @override
  bool get isFullScreen => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
