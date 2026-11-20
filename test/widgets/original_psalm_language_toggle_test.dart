import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/offline_liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:provider/provider.dart';

/// A psalm or Old/New Testament canticle with a Hebrew or Greek variant
/// (never both) follows [LiturgyState.useOriginalPsalmLanguage] — a single
/// preference for the whole office (set from the "Langues anciennes" menu
/// entry, see popup_menu_choices.dart, not from a button next to each
/// text), each resolving its own original language independently.
void main() {
  late _FakeLiturgyState liturgyState;

  Future<void> pump(WidgetTester tester, Psalm psalm,
      {bool useOriginalPsalmLanguage = false}) async {
    liturgyState = _FakeLiturgyState()
      ..useOriginalPsalmLanguage = useOriginalPsalmLanguage;
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
  double? shownFontSize(WidgetTester tester) => tester
      .widget<PsalmFromMarkdown>(find.byType(PsalmFromMarkdown))
      .verseStyle
      ?.fontSize;
  TextDirection? shownDirection(WidgetTester tester) => tester
      .widget<PsalmFromMarkdown>(find.byType(PsalmFromMarkdown))
      .textDirection;

  testWidgets('no Hebrew/Greek variant: French text shown regardless',
      (tester) async {
    await pump(
      tester,
      const Psalm(title: 'Psaume 1', content: 'Heureux est l\'homme'),
      useOriginalPsalmLanguage: true,
    );

    expect(shownContent(tester), 'Heureux est l\'homme');
    expect(shownTitle(tester), 'Psaume 1');
    expect(shownDirection(tester), isNull);
  });

  testWidgets(
      'with a Hebrew variant: the preference switches text, direction and font',
      (tester) async {
    final psalm = const Psalm(
      title: 'Psaume 1',
      content: 'Heureux est l\'homme',
      hebrew: Psalm(title: 'Psaume 1', content: 'אשרי האיש'),
    );

    await pump(tester, psalm);
    expect(shownContent(tester), 'Heureux est l\'homme');
    expect(shownDirection(tester), isNull);

    await pump(tester, psalm, useOriginalPsalmLanguage: true);
    expect(shownContent(tester), 'אשרי האיש');
    expect(shownDirection(tester), TextDirection.rtl);
    expect(shownFontFamily(tester), 'EzraSIL');
    // One point smaller than the French/Greek size (16.0) — Ezra SIL
    // reads a touch large next to them at the same nominal size.
    expect(shownFontSize(tester), 15.0);

    await pump(tester, psalm);
    expect(shownContent(tester), 'Heureux est l\'homme');
    expect(shownDirection(tester), isNull);
  });

  testWidgets(
      'with a Greek variant (NT canticle): the preference switches text and '
      'font, stays left-to-right', (tester) async {
    final psalm = const Psalm(
      title: 'Cantique des Éphésiens',
      content: 'Béni soit Dieu',
      greek: Psalm(title: 'Εὐλογητὸς', content: 'Εὐλογητὸς ὁ θεὸς'),
    );

    await pump(tester, psalm);
    expect(shownFontFamily(tester), isNull);

    await pump(tester, psalm, useOriginalPsalmLanguage: true);
    expect(shownContent(tester), 'Εὐλογητὸς ὁ θεὸς');
    expect(shownTitle(tester), 'Εὐλογητὸς');
    expect(shownFontFamily(tester), 'Alegreya');
    expect(shownFontSize(tester), 16.0);
    expect(shownDirection(tester), isNull);
  });

  testWidgets(
      'OT canticle: Hebrew variant has no subtitle/commentary, both stay '
      'in French', (tester) async {
    final psalm = const Psalm(
      title: 'Cantique de Moïse',
      subtitle: 'À Dieu, libérateur de son peuple',
      commentary: 'Commentaire français',
      shortReference: 'AT 1',
      content: 'Je veux chanter au Seigneur',
      // Generated Hebrew/Greek variants never carry a subtitle or a
      // commentary — both are French-only annotations.
      hebrew: Psalm(title: 'שירת משה', content: 'אשירה ליהוה'),
    );

    await pump(tester, psalm, useOriginalPsalmLanguage: true);

    expect(shownContent(tester), 'אשירה ליהוה');
    // Subtitle and commentary keep showing the French original.
    expect(
        tester
            .widget<OfflineLiturgyPartSubtitle>(
                find.byType(OfflineLiturgyPartSubtitle))
            .content,
        'À Dieu, libérateur de son peuple');
    expect(
        tester
            .widget<LiturgyPartCommentary>(find.byType(LiturgyPartCommentary))
            .content,
        'Commentaire français');

    await pump(tester, psalm);
    expect(shownContent(tester), 'Je veux chanter au Seigneur');
  });

  testWidgets(
      'the shared preference keeps each text in its own original language: '
      'a Hebrew-only psalm and a Greek-only NT canticle shown together',
      (tester) async {
    const hebrewPsalm = Psalm(
      title: 'Psaume 1',
      content: 'Heureux est l\'homme',
      hebrew: Psalm(title: 'Psaume 1', content: 'אשרי האיש'),
    );
    const greekCanticle = Psalm(
      title: 'Cantique des Éphésiens',
      content: 'Béni soit Dieu',
      greek: Psalm(title: 'Εὐλογητὸς', content: 'Εὐλογητὸς ὁ θεὸς'),
    );
    liturgyState = _FakeLiturgyState()..useOriginalPsalmLanguage = true;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider<LiturgyState>.value(value: liturgyState),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                PsalmDisplayWidget(psalm: hebrewPsalm),
                PsalmDisplayWidget(psalm: greekCanticle),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final bodies = tester
        .widgetList<PsalmFromMarkdown>(find.byType(PsalmFromMarkdown))
        .toList();

    expect(bodies[0].content, 'אשרי האיש');
    expect(bodies[0].textDirection, TextDirection.rtl);
    expect(bodies[0].verseStyle?.fontFamily, 'EzraSIL');

    // The Greek-only canticle must show Greek — never a French fallback
    // rendered with the Hebrew psalm's leftover RTL direction/font.
    expect(bodies[1].content, 'Εὐλογητὸς ὁ θεὸς');
    expect(bodies[1].textDirection, isNull);
    expect(bodies[1].verseStyle?.fontFamily, 'Alegreya');
  });
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  bool useOriginalPsalmLanguage = false;

  @override
  void updateOriginalPsalmLanguage(bool enabled) {
    if (useOriginalPsalmLanguage == enabled) return;
    useOriginalPsalmLanguage = enabled;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
