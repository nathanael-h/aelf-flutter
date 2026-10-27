import 'package:aelf_flutter/states/currentZoomState.dart';
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
/// checkbox below its title. Again brings it back to its own rank.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final dataLoader = FileSystemDataLoader();
  CelebrationContext celebration(String code, int precedence) =>
      CelebrationContext(
        celebrationCode: code,
        officeDescription: code,
        ferialCode: 'ot_29_1',
        date: DateTime(2027, 10, 18),
        precedence: precedence,
        isCelebrable: true,
        dataLoader: dataLoader,
      );

  Future<List<(String, int?)>> pump(WidgetTester tester,
      Widget Function(void Function(String, int?) onPrecedenceOverridden) build,
      {SelectedCelebrationState? state}) async {
    final calls = <(String, int?)>[];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider.value(
              value: state ?? SelectedCelebrationState()),
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
                celebrationMap: {'luke': celebration('luke', 7)},
                selectedKey: 'luke',
                onPrecedenceOverridden: onPrecedenceOverridden,
              ),
          state: SelectedCelebrationState()..setPrecedenceOverride('luke', 4));
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
}
