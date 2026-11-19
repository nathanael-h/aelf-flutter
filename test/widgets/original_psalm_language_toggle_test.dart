import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/offline_liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/original_language_toggle_button.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_icon.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A psalm or Old/New Testament canticle with a Hebrew or Greek variant
/// (never both) shows a toggle switching [LiturgyState.useOriginalPsalmLanguage]
/// — a single preference shared by every psalm/canticle, each resolving its
/// own original language (Hebrew or Greek, whichever it has) independently.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late _FakeLiturgyState liturgyState;

  Future<void> pump(WidgetTester tester, Psalm psalm,
      {bool advancedMode = true}) async {
    liturgyState = _FakeLiturgyState();
    final featureFlags = FeatureFlagsState();
    await featureFlags.setAdvancedModeEnabled(advancedMode);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider<LiturgyState>.value(value: liturgyState),
          ChangeNotifierProvider.value(value: featureFlags),
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
  TextDirection? shownDirection(WidgetTester tester) => tester
      .widget<PsalmFromMarkdown>(find.byType(PsalmFromMarkdown))
      .textDirection;

  testWidgets('no Hebrew/Greek variant: no toggle, French text shown',
      (tester) async {
    await pump(tester,
        const Psalm(title: 'Psaume 1', content: 'Heureux est l\'homme'));

    expect(find.byType(OriginalLanguageToggleButton), findsNothing);
    expect(shownContent(tester), 'Heureux est l\'homme');
    expect(shownTitle(tester), 'Psaume 1');
    expect(shownDirection(tester), isNull);
  });

  testWidgets('with a Hebrew variant: toggle switches text, direction and font',
      (tester) async {
    await pump(
        tester,
        const Psalm(
          title: 'Psaume 1',
          content: 'Heureux est l\'homme',
          hebrew: Psalm(title: 'Psaume 1', content: 'אשרי האיש'),
        ));

    expect(find.byType(OriginalLanguageToggleButton), findsOneWidget);
    expect(shownContent(tester), 'Heureux est l\'homme');
    expect(liturgyState.useOriginalPsalmLanguage, isFalse);
    expect(shownDirection(tester), isNull);

    await tester.tap(find.byType(OriginalLanguageToggleButton));
    await tester.pump();

    expect(liturgyState.useOriginalPsalmLanguage, isTrue);
    expect(shownContent(tester), 'אשרי האיש');
    expect(shownDirection(tester), TextDirection.rtl);
    expect(shownFontFamily(tester), 'EzraSIL');

    await tester.tap(find.byType(OriginalLanguageToggleButton));
    await tester.pump();

    expect(liturgyState.useOriginalPsalmLanguage, isFalse);
    expect(shownContent(tester), 'Heureux est l\'homme');
    expect(shownDirection(tester), isNull);
  });

  testWidgets(
      'with a Greek variant (NT canticle): toggle switches text and font, '
      'stays left-to-right', (tester) async {
    await pump(
        tester,
        const Psalm(
          title: 'Cantique des Éphésiens',
          content: 'Béni soit Dieu',
          greek: Psalm(title: 'Εὐλογητὸς', content: 'Εὐλογητὸς ὁ θεὸς'),
        ));

    expect(find.byType(OriginalLanguageToggleButton), findsOneWidget);
    expect(shownFontFamily(tester), isNull);

    await tester.tap(find.byType(OriginalLanguageToggleButton));
    await tester.pump();

    expect(liturgyState.useOriginalPsalmLanguage, isTrue);
    expect(shownContent(tester), 'Εὐλογητὸς ὁ θεὸς');
    expect(shownTitle(tester), 'Εὐλογητὸς');
    expect(shownFontFamily(tester), 'GentiumPlus');
    expect(shownDirection(tester), isNull);
  });

  testWidgets(
      'OT canticle: Hebrew variant has no subtitle/commentary, both stay '
      'in French, toggle stays visible and tappable back to French',
      (tester) async {
    await pump(
        tester,
        const Psalm(
          title: 'Cantique de Moïse',
          subtitle: 'À Dieu, libérateur de son peuple',
          commentary: 'Commentaire français',
          shortReference: 'AT 1',
          content: 'Je veux chanter au Seigneur',
          // Generated Hebrew/Greek variants never carry a subtitle or a
          // commentary — both are French-only annotations.
          hebrew: Psalm(title: 'שירת משה', content: 'אשירה ליהוה'),
        ));

    expect(find.byType(OriginalLanguageToggleButton), findsOneWidget);
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

    await tester.tap(find.byType(OriginalLanguageToggleButton));
    await tester.pump();

    expect(liturgyState.useOriginalPsalmLanguage, isTrue);
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
    expect(find.byType(OriginalLanguageToggleButton), findsOneWidget);

    await tester.tap(find.byType(OriginalLanguageToggleButton));
    await tester.pump();

    expect(liturgyState.useOriginalPsalmLanguage, isFalse);
    expect(shownContent(tester), 'Je veux chanter au Seigneur');
  });

  testWidgets(
      'simplified mode (not "mode développé"): toggle hidden even with a '
      'Hebrew or Greek variant', (tester) async {
    await pump(
      tester,
      const Psalm(
        title: 'Psaume 1',
        content: 'Heureux est l\'homme',
        hebrew: Psalm(title: 'Psaume 1', content: 'אשרי האיש'),
      ),
      advancedMode: false,
    );

    // The widget is still mounted (the data has a Hebrew variant) but
    // renders nothing: outside advanced mode, this control has no place.
    expect(find.byType(LanguageToggleIcon), findsNothing);
    expect(shownContent(tester), 'Heureux est l\'homme');
  });

  testWidgets(
      'the shared toggle keeps each text in its own original language: a '
      'Hebrew-only psalm and a Greek-only NT canticle shown together',
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
    liturgyState = _FakeLiturgyState();
    final featureFlags = FeatureFlagsState();
    await featureFlags.setAdvancedModeEnabled(true);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider<LiturgyState>.value(value: liturgyState),
          ChangeNotifierProvider.value(value: featureFlags),
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

    // Turn the single shared toggle on from the Hebrew psalm's own button.
    await tester.tap(find.byType(OriginalLanguageToggleButton).first);
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
    expect(bodies[1].verseStyle?.fontFamily, 'GentiumPlus');
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
