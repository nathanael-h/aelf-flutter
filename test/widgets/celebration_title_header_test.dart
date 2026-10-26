import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CelebrationTitleHeader keeps the longest celebration name's height
/// whichever celebration is selected: switching from a one-line name to a
/// two-line one must not move the office's selectors below it.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final dataLoader = FileSystemDataLoader();
  CelebrationContext celebration(String title) => CelebrationContext(
        celebrationCode: title,
        celebrationTitle: title,
        date: DateTime(2027, 2, 5),
        isCelebrable: true,
        dataLoader: dataLoader,
      );

  final celebrations = {
    'agatha': celebration('Sainte Agathe'),
    'ferial': celebration('Vendredi de la quatrième semaine du temps '
        'ordinaire, après la fête de la Présentation du Seigneur'),
  };

  Future<double> headerHeight(WidgetTester tester, String selectedKey,
      {Map<String, CelebrationContext>? only}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 360,
                child: CelebrationTitleHeader(
                  celebrationMap: only ?? celebrations,
                  selectedKey: selectedKey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(CelebrationTitleHeader)).height;
  }

  testWidgets('a short name keeps the height of the longest one',
      (tester) async {
    final shortHeight = await headerHeight(tester, 'agatha');
    final longHeight = await headerHeight(tester, 'ferial');
    expect(shortHeight, longHeight);

    final visible = find.byWidgetPredicate(
        (w) => w is Visibility && w.visible && w.child is Text);
    expect(
        tester
            .widget<Text>(
                find.descendant(of: visible, matching: find.byType(Text)))
            .data,
        startsWith('Vendredi'));

    // Sanity check: alone, the short name takes less room — the long one
    // really wraps at this width, so the equality above means something.
    final aloneHeight = await headerHeight(tester, 'agatha',
        only: {'agatha': celebrations['agatha']!});
    expect(aloneHeight, lessThan(longHeight));
  });
}
