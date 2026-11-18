import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/localSolemnitiesState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/choice_selectors.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simplified mode hides CelebrationSelector entirely (BaseOfficeViewState
/// resolves the day's celebration silently) — except when several
/// obligatory memorials collide the same day, where the choice between
/// them still has to be made. An optional memorial never takes part in it.
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

  Future<List<String>> pump(
      WidgetTester tester, Map<String, CelebrationContext> celebrationMap,
      {required String selectedKey}) async {
    final chosen = <String>[];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => LocalSolemnitiesState()),
          // Simplified mode: FeatureFlagsState defaults to advancedModeEnabled: false
          ChangeNotifierProvider(create: (_) => FeatureFlagsState()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CelebrationSelector(
              celebrationMap: celebrationMap,
              selectedKey: selectedKey,
              onCelebrationChanged: chosen.add,
            ),
          ),
        ),
      ),
    );
    return chosen;
  }

  testWidgets('a single obligatory memorial offers no choice', (tester) async {
    await pump(
        tester,
        {
          'day': celebration('ot_29_1', 13),
          'saint': celebration('saint', 11),
        },
        selectedKey: 'saint');
    expect(find.byType(ChoiceList), findsNothing);
  });

  testWidgets('two colliding obligatory memorials offer a choice',
      (tester) async {
    final chosen = await pump(
        tester,
        {
          'day': celebration('ot_29_1', 13),
          'first': celebration('first', 10),
          'second': celebration('second', 11),
        },
        selectedKey: 'first');
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);

    await tester.tap(find.text('second'));
    expect(chosen, ['second']);
  });

  testWidgets(
      'an optional memorial never takes part in the choice, even among '
      'several obligatory ones', (tester) async {
    await pump(
        tester,
        {
          'day': celebration('ot_29_1', 13),
          'first': celebration('first', 10),
          'second': celebration('second', 11),
          'optional': celebration('optional', 12),
        },
        selectedKey: 'first');
    expect(find.text('optional'), findsNothing);
  });
}
