import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hebrew_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:provider/provider.dart';

/// A psalm with a Hebrew variant shows a toggle that switches its display
/// between French and Hebrew (right-to-left), without changing the
/// underlying Psalm the app holds.
void main() {
  late _FakeLiturgyState liturgyState;

  Future<void> pump(WidgetTester tester, Psalm psalm) async {
    liturgyState = _FakeLiturgyState();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider<LiturgyState>.value(value: liturgyState),
        ],
        child: MaterialApp(
          home: Scaffold(body: PsalmDisplayWidget(psalm: psalm)),
        ),
      ),
    );
    await tester.pump();
  }

  String shownContent(WidgetTester tester) =>
      tester.widget<PsalmFromMarkdown>(find.byType(PsalmFromMarkdown)).content;
  String? shownTitle(WidgetTester tester) =>
      tester.widget<LiturgyPartTitle>(find.byType(LiturgyPartTitle)).content;
  TextDirection? shownDirection(WidgetTester tester) => tester
      .widget<PsalmFromMarkdown>(find.byType(PsalmFromMarkdown))
      .textDirection;

  testWidgets('no Hebrew variant: no toggle, French text shown left-to-right',
      (tester) async {
    await pump(tester, const Psalm(title: 'Psaume 1', content: 'Heureux est l\'homme'));

    expect(find.byType(HebrewToggleButton), findsNothing);
    expect(shownContent(tester), 'Heureux est l\'homme');
    expect(shownTitle(tester), 'Psaume 1');
    expect(shownDirection(tester), isNull);
  });

  testWidgets('with a Hebrew variant: toggle switches text and direction',
      (tester) async {
    await pump(tester, const Psalm(
      title: 'Psaume 1',
      content: 'Heureux est l\'homme',
      hebrew: Psalm(title: 'Psaume 1', content: 'אשרי האיש'),
    ));

    expect(find.byType(HebrewToggleButton), findsOneWidget);
    expect(shownContent(tester), 'Heureux est l\'homme');
    expect(liturgyState.useHebrewPsalm, isFalse);
    expect(shownDirection(tester), isNull);

    await tester.tap(find.byType(HebrewToggleButton));
    await tester.pump();

    expect(liturgyState.useHebrewPsalm, isTrue);
    expect(shownContent(tester), 'אשרי האיש');
    expect(shownDirection(tester), TextDirection.rtl);

    await tester.tap(find.byType(HebrewToggleButton));
    await tester.pump();

    expect(liturgyState.useHebrewPsalm, isFalse);
    expect(shownContent(tester), 'Heureux est l\'homme');
    expect(shownDirection(tester), isNull);
  });
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  bool useHebrewPsalm = false;

  @override
  void updateHebrewPsalm(bool enabled) {
    if (useHebrewPsalm == enabled) return;
    useHebrewPsalm = enabled;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
