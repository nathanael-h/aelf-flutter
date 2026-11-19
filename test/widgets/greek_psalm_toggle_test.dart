import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/greek_toggle_button.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hebrew_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:provider/provider.dart';

/// An Old/New Testament canticle with a Greek variant shows an independent
/// toggle that switches its display between French and Greek, separate
/// from the Hebrew psalm toggle.
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
  String? shownFontFamily(WidgetTester tester) => tester
      .widget<PsalmFromMarkdown>(find.byType(PsalmFromMarkdown))
      .verseStyle
      ?.fontFamily;

  testWidgets('no Greek variant: no toggle', (tester) async {
    await pump(tester, const Psalm(title: 'Cantique', content: 'Texte français'));
    expect(find.byType(GreekToggleButton), findsNothing);
  });

  testWidgets('with a Greek variant: toggle switches text and font, '
      'independent of the Hebrew toggle', (tester) async {
    await pump(tester, const Psalm(
      title: 'Cantique des Éphésiens',
      content: 'Béni soit Dieu',
      greek: Psalm(title: 'Εὐλογητὸς', content: 'Εὐλογητὸς ὁ θεὸς'),
    ));

    expect(find.byType(GreekToggleButton), findsOneWidget);
    expect(find.byType(HebrewToggleButton), findsNothing);
    expect(shownContent(tester), 'Béni soit Dieu');
    expect(liturgyState.useGreekPsalm, isFalse);
    expect(shownFontFamily(tester), isNull);

    await tester.tap(find.byType(GreekToggleButton));
    await tester.pump();

    expect(liturgyState.useGreekPsalm, isTrue);
    expect(liturgyState.useHebrewPsalm, isFalse);
    expect(shownContent(tester), 'Εὐλογητὸς ὁ θεὸς');
    expect(shownTitle(tester), 'Εὐλογητὸς');
    expect(shownFontFamily(tester), 'GentiumPlus');
  });
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  bool useGreekPsalm = false;
  @override
  bool useHebrewPsalm = false;

  @override
  void updateGreekPsalm(bool enabled) {
    if (useGreekPsalm == enabled) return;
    useGreekPsalm = enabled;
    notifyListeners();
  }

  @override
  void updateHebrewPsalm(bool enabled) {
    if (useHebrewPsalm == enabled) return;
    useHebrewPsalm = enabled;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
