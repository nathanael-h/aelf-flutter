import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/canticle_language_button.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The Our Father's language toggle sits on [CollapsibleLiturgyText]'s title
/// row — the same row whose tap expands/collapses the text. This checks the
/// toggle's own tap is captured by the button rather than by the
/// ExpansionTile underneath it, and that it shares [CanticleLanguage] with
/// the evangelic canticles rather than having its own preference.
void main() {
  late _FakeLiturgyState liturgyState;

  Future<void> pump(WidgetTester tester) async {
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
            body: CollapsibleLiturgyText(
              title: 'Notre Père',
              content: 'Notre Père, qui es aux cieux',
              languageToggle: (z) => CanticleLanguageButton(zoom: z),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
      'tapping the toggle cycles the language without expanding the tile',
      (tester) async {
    await pump(tester);
    expect(liturgyState.canticleLanguage, CanticleLanguage.french);
    // Collapsed by default: the content isn't even built yet.
    expect(find.byType(HymnContentDisplay), findsNothing);
    expect(find.byType(CanticleLanguageButton), findsOneWidget);

    await tester.tap(find.byType(CanticleLanguageButton));
    await tester.pumpAndSettle();

    expect(liturgyState.canticleLanguage, CanticleLanguage.latin);
    // Still collapsed: the tap was captured by the pill, not the tile.
    expect(find.byType(HymnContentDisplay), findsNothing);

    // Tapping the title itself still expands the tile as usual.
    await tester.tap(find.text('Notre Père'));
    await tester.pumpAndSettle();

    expect(find.byType(HymnContentDisplay), findsOneWidget);
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
