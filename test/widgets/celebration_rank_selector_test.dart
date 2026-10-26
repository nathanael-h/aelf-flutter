import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CelebrationRankSelector raises the selected celebration from its own
/// rank up to a solemnity (e.g. a patronal feast): a memorial offers
/// "Mémoire (rang originel)", "Fête" and "Solennité", a feast "Fête (rang
/// originel)" and "Solennité", a solemnity or the ferial day nothing.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final dataLoader = FileSystemDataLoader();
  CelebrationContext celebration(String code, int precedence) =>
      CelebrationContext(
        celebrationCode: code,
        ferialCode: 'ot_4_5',
        date: DateTime(2027, 2, 5),
        precedence: precedence,
        isCelebrable: true,
        dataLoader: dataLoader,
      );

  Future<List<(String, int?)>> pumpRank(WidgetTester tester,
      CelebrationContext selected, SelectedCelebrationState state) async {
    final calls = <(String, int?)>[];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider.value(value: state),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CelebrationRankSelector(
              celebrationMap: {'saint': selected},
              selectedKey: 'saint',
              onPrecedenceOverridden: (key, precedence) =>
                  calls.add((key, precedence)),
            ),
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('a memorial can become a feast or a solemnity', (tester) async {
    final calls = await pumpRank(
        tester,
        celebration('roman/agatha_of_sicily_virgin', 10),
        SelectedCelebrationState());
    expect(find.text('Changer le rang de la célébration :'), findsOneWidget);
    expect(find.text('Mémoire (rang originel)'), findsOneWidget);
    expect(find.text('Fête'), findsOneWidget);

    await tester.tap(find.text('Solennité'));
    await tester.tap(find.text('Fête'));
    // The selected rank, its own, does nothing
    await tester.tap(find.text('Mémoire (rang originel)'));
    expect(calls, [('saint', 4), ('saint', 8)]);
  });

  testWidgets('a raised feast comes back to its own rank', (tester) async {
    final state = SelectedCelebrationState()..setPrecedenceOverride('saint', 4);
    final calls =
        await pumpRank(tester, celebration('roman/luke_evangelist', 7), state);
    expect(find.text('Mémoire (rang originel)'), findsNothing);

    await tester.tap(find.text('Fête (rang originel)'));
    expect(calls, [('saint', null)]);
  });

  testWidgets('nothing for a solemnity nor the ferial day', (tester) async {
    await pumpRank(tester, celebration('paris/genevieve_of_paris_virgin', 4),
        SelectedCelebrationState());
    expect(find.text('Changer le rang de la célébration :'), findsNothing);

    await pumpRank(
        tester, celebration('ot_4_5', 13), SelectedCelebrationState());
    expect(find.text('Changer le rang de la célébration :'), findsNothing);
  });
}
