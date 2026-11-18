import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/latin_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:provider/provider.dart';

/// A canticle with a Latin variant shows a toggle that switches its display
/// between the two, without changing the underlying Psalm the app holds.
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
          home: Scaffold(
            body: CanticleWidget(antiphons: const {}, psalm: psalm),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  String shownContent(WidgetTester tester) =>
      tester.widget<PsalmFromMarkdown>(find.byType(PsalmFromMarkdown)).content;
  String? shownTitle(WidgetTester tester) =>
      tester.widget<LiturgyPartTitle>(find.byType(LiturgyPartTitle)).content;

  testWidgets('no Latin variant: no toggle, French text shown', (tester) async {
    await pump(
        tester,
        const Psalm(
            title: 'Cantique de Marie', content: 'Mon âme exalte le Seigneur'));

    expect(find.byType(LatinToggleButton), findsNothing);
    expect(shownContent(tester), 'Mon âme exalte le Seigneur');
    expect(shownTitle(tester), 'Cantique de Marie');
  });

  testWidgets('Latin variant: toggle switches the displayed text and title',
      (tester) async {
    await pump(
        tester,
        const Psalm(
          title: 'Cantique de Marie',
          content: 'Mon âme exalte le Seigneur',
          latin: Psalm(title: 'Magnificat', content: 'Magnificat anima mea'),
        ));

    expect(find.byType(LatinToggleButton), findsOneWidget);
    expect(shownContent(tester), 'Mon âme exalte le Seigneur');
    expect(shownTitle(tester), 'Cantique de Marie');
    expect(liturgyState.useLatinCanticle, isFalse);

    await tester.tap(find.byType(LatinToggleButton));
    await tester.pump();

    expect(liturgyState.useLatinCanticle, isTrue);
    expect(shownContent(tester), 'Magnificat anima mea');
    expect(shownTitle(tester), 'Magnificat');

    await tester.tap(find.byType(LatinToggleButton));
    await tester.pump();

    expect(liturgyState.useLatinCanticle, isFalse);
    expect(shownContent(tester), 'Mon âme exalte le Seigneur');
  });
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  bool useLatinCanticle = false;

  @override
  void updateLatinCanticle(bool enabled) {
    if (useLatinCanticle == enabled) return;
    useLatinCanticle = enabled;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
