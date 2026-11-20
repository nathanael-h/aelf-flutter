import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/canticle_language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A canticle with Latin/Greek variants shows a toggle that cycles its
/// display through French/Latin/Greek, without changing the underlying
/// Psalm the app holds. Unlike the psalms/OT-NT canticles preference, this
/// toggle is shown regardless of "mode développé" / "mode simplifié".
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
          home:
              Scaffold(body: CanticleWidget(antiphons: const {}, psalm: psalm)),
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

  testWidgets('no Latin/Greek variant: no toggle, French text shown',
      (tester) async {
    await pump(
        tester,
        const Psalm(
            title: 'Cantique de Marie', content: 'Mon âme exalte le Seigneur'));
    expect(find.byType(CanticleLanguageButton), findsNothing);
    expect(shownContent(tester), 'Mon âme exalte le Seigneur');
    expect(shownTitle(tester), 'Cantique de Marie');
  });

  testWidgets(
      'with Latin/Greek variants: toggle cycles French -> Latin -> Greek -> French',
      (tester) async {
    await pump(
        tester,
        const Psalm(
          title: 'Cantique de Marie',
          content: 'Mon âme exalte le Seigneur',
          latin: Psalm(title: 'Magnificat', content: 'Magnificat anima mea'),
          greek: Psalm(title: 'Μεγαλύνει', content: 'Μεγαλύνει ἡ ψυχή μου'),
        ));
    expect(find.byType(CanticleLanguageButton), findsOneWidget);
    expect(shownContent(tester), 'Mon âme exalte le Seigneur');
    expect(liturgyState.canticleLanguage, CanticleLanguage.french);
    expect(shownFontFamily(tester), isNull);

    await tester.tap(find.byType(CanticleLanguageButton));
    await tester.pump();

    expect(liturgyState.canticleLanguage, CanticleLanguage.latin);
    expect(shownContent(tester), 'Magnificat anima mea');
    expect(shownTitle(tester), 'Magnificat');
    expect(shownFontFamily(tester), isNull);

    await tester.tap(find.byType(CanticleLanguageButton));
    await tester.pump();

    expect(liturgyState.canticleLanguage, CanticleLanguage.greek);
    expect(shownContent(tester), 'Μεγαλύνει ἡ ψυχή μου');
    expect(shownTitle(tester), 'Μεγαλύνει');
    expect(shownFontFamily(tester), 'Alegreya');

    await tester.tap(find.byType(CanticleLanguageButton));
    await tester.pump();

    expect(liturgyState.canticleLanguage, CanticleLanguage.french);
    expect(shownContent(tester), 'Mon âme exalte le Seigneur');
    expect(shownFontFamily(tester), isNull);
  });

  testWidgets(
      'simplified mode (not "mode développé"): toggle still shown and '
      'works', (tester) async {
    await pump(
      tester,
      const Psalm(
        title: 'Cantique de Marie',
        content: 'Mon âme exalte le Seigneur',
        latin: Psalm(title: 'Magnificat', content: 'Magnificat anima mea'),
        greek: Psalm(title: 'Μεγαλύνει', content: 'Μεγαλύνει ἡ ψυχή μου'),
      ),
      advancedMode: false,
    );

    expect(find.byType(CanticleLanguageButton), findsOneWidget);

    await tester.tap(find.byType(CanticleLanguageButton));
    await tester.pump();

    expect(liturgyState.canticleLanguage, CanticleLanguage.latin);
    expect(shownContent(tester), 'Magnificat anima mea');
  });
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  CanticleLanguage canticleLanguage = CanticleLanguage.french;

  @override
  void cycleCanticleLanguage() {
    canticleLanguage = canticleLanguage.next;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
