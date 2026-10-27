import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/localSolemnitiesState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A memorial or a feast may be celebrated as a local solemnity (e.g. the
/// titular of the place), in one step: a long press on its row in the
/// celebration selector, or — for a feast alone, with no selector — the
/// checkbox below its title. Again brings it back to its own rank. At
/// Vespers, tomorrow's memorials and feasts are offered too, for their
/// First Vespers.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final dataLoader = FileSystemDataLoader();
  CelebrationContext celebration(String code, int precedence,
          {DateTime? date}) =>
      CelebrationContext(
        celebrationCode: code,
        officeDescription: code,
        ferialCode: 'ot_29_1',
        date: date ?? DateTime(2027, 10, 18),
        precedence: precedence,
        isCelebrable: true,
        dataLoader: dataLoader,
      );

  Future<List<(String, int?)>> pump(WidgetTester tester,
      Widget Function(void Function(String, int?) onPrecedenceOverridden) build,
      {LocalSolemnitiesState? state}) async {
    final calls = <(String, int?)>[];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => SelectedCelebrationState()),
          ChangeNotifierProvider.value(value: state ?? LocalSolemnitiesState()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: build((key, precedence) => calls.add((key, precedence))),
          ),
        ),
      ),
    );
    return calls;
  }

  group('LocalSolemnityButton', () {
    testWidgets('makes a feast a local solemnity', (tester) async {
      final calls = await pump(
          tester,
          (onPrecedenceOverridden) => LocalSolemnityButton(
                celebrationMap: {'luke': celebration('luke', 7)},
                selectedKey: 'luke',
                onPrecedenceOverridden: onPrecedenceOverridden,
              ));
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      await tester.tap(find.text('Solennité locale'));
      expect(calls, [('luke', 4)]);
    });

    testWidgets('brings a local solemnity back to its own rank',
        (tester) async {
      final calls = await pump(
          tester,
          (onPrecedenceOverridden) => LocalSolemnityButton(
                // As the evening offices detect it: at its new rank
                celebrationMap: {'luke': celebration('luke', 4)},
                selectedKey: 'luke',
                onPrecedenceOverridden: onPrecedenceOverridden,
              ),
          state: LocalSolemnitiesState()..raise(celebration('luke', 7)));
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      await tester.tap(find.text('Solennité locale'));
      expect(calls, [('luke', null)]);
    });

    testWidgets('nothing for a solemnity', (tester) async {
      await pump(
          tester,
          (onPrecedenceOverridden) => LocalSolemnityButton(
                celebrationMap: {'saint': celebration('saint', 4)},
                selectedKey: 'saint',
                onPrecedenceOverridden: onPrecedenceOverridden,
              ));
      expect(find.text('Solennité locale'), findsNothing);
    });
  });

  testWidgets("each celebration's rank below its name", (tester) async {
    await pump(
        tester,
        (onPrecedenceOverridden) => CelebrationSelector(
              celebrationMap: {
                'charles': celebration('charles', 10),
                'saint': celebration('saint', 12),
                'luke': celebration('luke', 7),
                'day': celebration('ot_29_1', 13),
              },
              selectedKey: 'saint',
              onCelebrationChanged: (_) {},
              onPrecedenceOverridden: onPrecedenceOverridden,
            ),
        state: LocalSolemnitiesState()..raise(celebration('luke', 7)));
    expect(find.text('Mémoire obligatoire'), findsOneWidget);
    expect(find.text('Mémoire facultative'), findsOneWidget);
    expect(find.text('Solennité forcée'), findsOneWidget);
  });

  testWidgets('a long press on a memorial makes it a local solemnity',
      (tester) async {
    final calls = await pump(
        tester,
        (onPrecedenceOverridden) => CelebrationSelector(
              celebrationMap: {
                'saint': celebration('saint', 12),
                'day': celebration('ot_29_1', 13),
              },
              selectedKey: 'saint',
              onCelebrationChanged: (_) {},
              onPrecedenceOverridden: onPrecedenceOverridden,
            ));
    expect(
        find.text('Appui long : passage en solennité locale'), findsOneWidget);

    await tester.longPress(find.text('saint'));
    // The ferial day can't be raised
    await tester.longPress(find.text('ot_29_1'));
    expect(calls, [('saint', 4)]);
  });

  testWidgets("tomorrow's memorials and feasts, shown on demand",
      (tester) async {
    final calls = await pump(
        tester,
        (onPrecedenceOverridden) => CelebrationSelector(
              celebrationMap: {
                'day': celebration('ot_29_0', 6, date: DateTime(2027, 10, 17)),
                'ignatius':
                    celebration('ignatius', 10, date: DateTime(2027, 10, 17)),
              },
              selectedKey: 'day',
              onCelebrationChanged: (_) {},
              onPrecedenceOverridden: onPrecedenceOverridden,
              eveCandidates: {
                'I Vespers: luke': celebration('luke', 7)
                    .copyWith(celebrationType: 'vespers1', isCelebrable: false),
              },
            ));
    expect(find.text('luke'), findsNothing);

    await tester.tap(find.text('Afficher les fêtes et mémoires de demain'));
    await tester.pump();
    expect(find.text('luke'), findsOneWidget);

    await tester.longPress(find.text('luke'));
    expect(calls, [('I Vespers: luke', 4)]);
  });

  group('LocalSolemnitiesState', () {
    final luke = celebration('roman/luke_evangelist', 7);
    final peter = celebration('roman/peter_of_alcantara', 12);

    test('one local solemnity at a time', () {
      final state = LocalSolemnitiesState()
        ..raise(luke)
        ..raise(peter);
      expect(state.isLocalSolemnity(luke), isFalse);
      expect(state.isLocalSolemnity(peter), isTrue);
      expect(
          state.precedenceOverride(
              DateTime(2027, 10, 18, 19), 'roman/peter_of_alcantara'),
          4);
      expect(
          state.precedenceOverride(
              DateTime(2027, 10, 19), 'roman/peter_of_alcantara'),
          isNull);

      // Tomorrow's, raised at this evening's Vespers, replaces it too
      final allSaints =
          celebration('lyon/all_saints', 10, date: DateTime(2027, 10, 19));
      state.raise(allSaints);
      expect(state.isLocalSolemnity(peter), isFalse);
      expect(state.isLocalSolemnity(allSaints), isTrue);

      state.lower(allSaints);
      expect(state.isLocalSolemnity(allSaints), isFalse);
    });

    test('kept across launches, for 36 hours', () async {
      var now = DateTime(2027, 10, 17, 18);
      LocalSolemnitiesState(now: () => now).raise(luke);
      await pumpEventQueue();

      final relaunched = LocalSolemnitiesState(now: () => now);
      await pumpEventQueue();
      expect(relaunched.isLocalSolemnity(luke), isTrue);

      now = now.add(const Duration(hours: 37));
      expect(relaunched.isLocalSolemnity(luke), isFalse);
    });
  });
}
