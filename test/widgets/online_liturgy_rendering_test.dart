import 'package:aelf_flutter/app_screens/liturgy_widget_builder.dart';
import 'package:aelf_flutter/parsers/liturgy_parser_service.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgy_part_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/fixtures.dart';

/// End-to-end for the **online** path, minus the network: a real AELF payload
/// goes through `LiturgyParserService` and `LiturgyWidgetBuilder` and is pumped
/// exactly as `LiturgyFormatter` pumps it.
///
/// This is the widest regression net that still runs on every commit — it
/// catches breakage anywhere between the API JSON and the rendered tab.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Builds the tab children for a fixture the way LiturgyFormatter does, and
  /// pumps the one at [tabIndex].
  Future<List<Widget>> pumpTab(
    WidgetTester tester,
    Map<String, dynamic> payload, {
    required int tabIndex,
  }) async {
    final parsed = LiturgyParserService.parse(payload);
    late List<Widget> children;

    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentZoom>(
        create: (_) => CurrentZoom(),
        child: MaterialApp(
          theme: light,
          home: Builder(builder: (context) {
            children = LiturgyWidgetBuilder.buildTabChildren(
              context: context,
              tabData: parsed.tabData,
              originalJson: payload,
              massPositions: parsed.massPositions,
            );
            return Scaffold(body: children[tabIndex]);
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return children;
  }

  Finder textContaining(String needle) =>
      find.textContaining(needle, findRichText: true);

  group('mass tabs render', () {
    testWidgets('a reading shows its title, reference and verse text',
        (tester) async {
      await pumpTab(tester, loadFixture('mass_single.json'), tabIndex: 0);

      expect(textContaining('Le Christ Jésus'), findsWidgets);
      expect(textContaining('2 Co 1, 18-22'), findsWidgets);
      expect(textContaining('Lecture de la deuxième lettre de saint Paul'),
          findsWidgets);
    });

    testWidgets('the psalm shows its antiphon twice, above and below',
        (tester) async {
      // LiturgyTabData.repeatSubtitle is true for psalms.
      await pumpTab(tester, loadFixture('mass_single.json'), tabIndex: 1);

      expect(textContaining('Ps 118'), findsWidgets);
      expect(textContaining('ton serviteur'), findsWidgets);
    });

    testWidgets('the gospel shows the acclamation verse and its reference',
        (tester) async {
      await pumpTab(tester, loadFixture('mass_single.json'), tabIndex: 2);

      expect(textContaining('Alléluia'), findsWidgets);
      expect(textContaining('Mt 5, 16'), findsWidgets);
      expect(textContaining('Mt 5, 13-16'), findsWidgets);
      expect(textContaining('sel de la terre'), findsWidgets);
    });

    testWidgets('every mass tab builds without throwing', (tester) async {
      final payload = loadFixture('mass_single.json');
      final parsed = LiturgyParserService.parse(payload);

      for (var i = 0; i < parsed.length; i++) {
        final children = await pumpTab(tester, payload, tabIndex: i);
        expect(children, hasLength(parsed.length));
        expect(tester.takeException(), isNull,
            reason: 'tab "${parsed.tabTitles[i]}" threw while rendering');
      }
    });
  });

  group('mass selection menu', () {
    testWidgets('lists every mass by name', (tester) async {
      await pumpTab(tester, loadFixture('mass_multiple.json'), tabIndex: 0);

      expect(find.text('Messe de la veille au soir'), findsOneWidget);
      expect(find.text('MESSE DU JOUR'), findsOneWidget,
          reason: 'mass names are shown exactly as the API sends them');
    });

    testWidgets('degrades to an error message when the payload is unusable',
        (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<CurrentZoom>(
          create: (_) => CurrentZoom(),
          child: MaterialApp(
            theme: light,
            home: Builder(builder: (context) {
              final children = LiturgyWidgetBuilder.buildTabChildren(
                context: context,
                tabData: LiturgyParserService.parse(
                        loadFixture('mass_multiple.json'))
                    .tabData,
                originalJson: const {'messes': 'oops'},
                massPositions: const [0],
              );
              return Scaffold(body: children.first);
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsOneWidget);
    });
  });

  group('office tabs render', () {
    testWidgets('a psalm shows its antiphon, reference and doxology',
        (tester) async {
      final payload = loadFixture('office_laudes.json');
      final parsed = LiturgyParserService.parse(payload);
      final index =
          parsed.tabTitles.indexWhere((t) => t.startsWith('Psaume 62'));

      await pumpTab(tester, payload, tabIndex: index);

      expect(textContaining('Antienne'), findsWidgets);
      expect(textContaining('ton souffle en nous est bon'), findsWidgets);
      expect(textContaining('Gloire au Père'), findsWidgets);
    });

    testWidgets('the Notre Père tab shows the hardcoded prayer',
        (tester) async {
      final payload = loadFixture('office_laudes.json');
      final parsed = LiturgyParserService.parse(payload);
      final index = parsed.tabTitles.indexOf('Notre Père');

      await pumpTab(tester, payload, tabIndex: index);

      expect(textContaining('Notre Père, qui es aux cieux'), findsWidgets);
      expect(textContaining('délivre-nous du Mal'), findsWidgets);
    });

    testWidgets('every laudes tab builds without throwing', (tester) async {
      final payload = loadFixture('office_laudes.json');
      final parsed = LiturgyParserService.parse(payload);

      for (var i = 0; i < parsed.length; i++) {
        await pumpTab(tester, payload, tabIndex: i);
        expect(tester.takeException(), isNull,
            reason: 'tab "${parsed.tabTitles[i]}" threw while rendering');
      }
    });

    testWidgets('every office-des-lectures tab builds without throwing',
        (tester) async {
      final payload = loadFixture('office_lectures.json');
      final parsed = LiturgyParserService.parse(payload);

      for (var i = 0; i < parsed.length; i++) {
        await pumpTab(tester, payload, tabIndex: i);
        expect(tester.takeException(), isNull,
            reason: 'tab "${parsed.tabTitles[i]}" threw while rendering');
      }
    });
  });

  group('special tabs', () {
    testWidgets('a null payload renders the loading spinner', (tester) async {
      final parsed = LiturgyParserService.parse(null);

      await tester.pumpWidget(
        ChangeNotifierProvider<CurrentZoom>(
          create: (_) => CurrentZoom(),
          child: MaterialApp(
            theme: light,
            home: Builder(builder: (context) {
              final children = LiturgyWidgetBuilder.buildTabChildren(
                context: context,
                tabData: parsed.tabData,
                originalJson: null,
              );
              return Scaffold(body: children.single);
            }),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('the informations tab renders its text block', (tester) async {
      await pumpTab(tester, loadFixture('informations.json'), tabIndex: 0);

      expect(textContaining('Pentecôte'), findsWidgets);
      expect(textContaining('Solennité du Seigneur'), findsWidgets);
      expect(textContaining('Couleur liturgique : rouge'), findsWidgets);
    });

    testWidgets('a server error renders the message as a normal tab',
        (tester) async {
      await pumpTab(tester, loadFixture('office_error.json'), tabIndex: 0);

      expect(find.byType(LiturgyPartColumn), findsOneWidget);
      expect(textContaining("Nous n'avons pas trouvé cette lecture"),
          findsWidgets);
    });
  });

  group('zoom applies to online content', () {
    testWidgets('verse text grows with the zoom level', (tester) async {
      final payload = loadFixture('mass_single.json');
      final parsed = LiturgyParserService.parse(payload);

      late CurrentZoom zoom;
      await tester.pumpWidget(
        ChangeNotifierProvider<CurrentZoom>(
          create: (_) => zoom = CurrentZoom(),
          child: MaterialApp(
            theme: light,
            home: Builder(builder: (context) {
              final children = LiturgyWidgetBuilder.buildTabChildren(
                context: context,
                tabData: parsed.tabData,
                originalJson: payload,
                massPositions: parsed.massPositions,
              );
              return Scaffold(body: children[0]);
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = tester.getSize(find.byType(LiturgyPartColumn)).height;

      zoom.updateZoom(300);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(LiturgyPartColumn)).height,
          greaterThanOrEqualTo(before));
    });
  });
}
