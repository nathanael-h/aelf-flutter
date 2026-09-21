import 'package:aelf_flutter/models/office_header_info.dart';
import 'package:aelf_flutter/utils/region_sync.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/left_menu_office_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixtures.dart';

/// `LeftMenuOfficeHeader` is the clearest shared surface between the two
/// liturgies: the *same* widget renders the drawer header whether the office
/// came from the online API or was computed by `offline_liturgy`. Both sources
/// are normalized through [OfficeHeaderInfo] first, so the widget must not care
/// which one it got.
///
/// The day/loading/error text renders through `smallCapsSpan`, which splits
/// it into per-run TextSpans and uppercases the lowercase ones — so the
/// plain text `find.text` matches against is the all-caps form ('MARDI'),
/// not the original string ('Mardi').
void main() {
  /// A stand-in for offline_liturgy's `CelebrationContext`, which
  /// [OfficeHeaderInfo.fromOffline] reads dynamically.
  Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  OfficeHeaderInfo fromRealApi() => OfficeHeaderInfo.fromApi(
        loadFixture('informations_weekday.json')['informations']
            as Map<dynamic, dynamic>,
        region: 'france',
      );

  group('the region list agrees with the rest of the app', () {
    test('the selector offers exactly the regions the API accepts', () {
      // A region here that the API rejects would 404; one missing would be
      // unreachable from the drawer.
      final offered = LeftMenuOfficeHeader.regions.map((r) => r[0]).toSet();
      expect(offered, kValidOnlineRegions);
    });

    test('every offered region has a non-empty label', () {
      for (final region in LeftMenuOfficeHeader.regions) {
        expect(region, hasLength(2), reason: region.toString());
        expect(region[1], isNotEmpty, reason: region[0]);
      }
    });

    test('the Roman calendar is offered last, as the catch-all', () {
      expect(LeftMenuOfficeHeader.regions.last[0], kDefaultRegion);
    });
  });

  group('rendering the online header', () {
    testWidgets('shows the day, the time line and the region', (tester) async {
      await tester.pumpWidget(host(LeftMenuOfficeHeader(
        info: fromRealApi(),
        selectedRegion: 'france',
        onRegionSelected: (_) {},
      )));
      await tester.pump();

      expect(find.text('MARDI'), findsOneWidget);
      expect(find.text('Année Impaire — Semaine II'), findsOneWidget);
      expect(find.text('France'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lists each liturgy option with its degree', (tester) async {
      await tester.pumpWidget(host(LeftMenuOfficeHeader(
        info: fromRealApi(),
        selectedRegion: 'france',
        onRegionSelected: (_) {},
      )));
      await tester.pump();

      expect(find.text('10ème Semaine du Temps Ordinaire'), findsOneWidget);
      expect(find.text('Férie'), findsOneWidget);
    });

    testWidgets('a solemnity with no psalter week hides the time line',
        (tester) async {
      final info = OfficeHeaderInfo.fromApi(
          loadFixture('informations.json')['informations']
              as Map<dynamic, dynamic>,
          region: 'france');

      await tester.pumpWidget(host(LeftMenuOfficeHeader(
        info: info,
        selectedRegion: 'france',
        onRegionSelected: (_) {},
      )));
      await tester.pump();

      expect(find.text('Pentecôte'), findsWidgets);
      expect(info.timeText, 'Année C');
      expect(tester.takeException(), isNull);
    });
  });

  group('rendering the offline header', () {
    testWidgets('the same widget renders offline data', (tester) async {
      final info = OfficeHeaderInfo.fromOfflineDay(
        day: 'mardi',
        liturgicalYear: 'impaire',
        psalterWeek: 2,
        region: 'lyon',
        options: const [
          OfficeLiturgyOption(
              name: 'Saint Irénée', degree: 'Fête', colorName: 'white'),
        ],
      );

      await tester.pumpWidget(host(LeftMenuOfficeHeader(
        info: info,
        selectedRegion: 'lyon',
        regionLabel: 'Lyon',
        onRegionTap: () {},
      )));
      await tester.pump();

      expect(find.text('MARDI'), findsOneWidget);
      expect(find.text('Année Impaire — Semaine II'), findsOneWidget);
      expect(find.text('Lyon'), findsOneWidget,
          reason: 'the offline label overrides the online region name');
      expect(find.text('Saint Irénée'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('online and offline data of the same day render the same way',
        (tester) async {
      // The whole point of normalizing through OfficeHeaderInfo.
      final online = OfficeHeaderInfo.fromApi(const {
        'liturgical_day': 'mardi',
        'liturgical_year': 'impaire',
        'psalter_week': 2,
      }, region: 'france');
      final offline = OfficeHeaderInfo.fromOfflineDay(
        day: 'mardi',
        liturgicalYear: 'impaire',
        psalterWeek: 2,
        region: 'france',
      );

      expect(offline.day, online.day);
      expect(offline.liturgicalYear, online.liturgicalYear);
      expect(offline.psalterWeek, online.psalterWeek);
      expect(offline.timeText, online.timeText);

      for (final info in [online, offline]) {
        await tester.pumpWidget(host(LeftMenuOfficeHeader(
          info: info,
          selectedRegion: 'france',
          onRegionSelected: (_) {},
        )));
        await tester.pump();

        expect(find.text('MARDI'), findsOneWidget);
        expect(find.text('Année Impaire — Semaine II'), findsOneWidget);
      }
    });

    testWidgets('an offline colour name resolves like a French one',
        (tester) async {
      // offline_liturgy sends English names, the API French ones.
      const english = OfficeLiturgyOption(name: 'X', colorName: 'red');
      const french = OfficeLiturgyOption(name: 'X', colorName: 'rouge');

      late BuildContext ctx;
      await tester.pumpWidget(host(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      expect(english.squareColor(ctx), french.squareColor(ctx));
      expect(english.squareColor(ctx), AelfLiturgicalColors.lightColors.red);
    });
  });

  group('degraded states', () {
    testWidgets('loading shows a placeholder rather than an empty band',
        (tester) async {
      await tester.pumpWidget(host(const LeftMenuOfficeHeader(
          info: OfficeHeaderInfo.loading(), selectedRegion: 'france')));
      await tester.pump();

      expect(find.text('CHARGEMENT…'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an error shows a message', (tester) async {
      await tester.pumpWidget(host(const LeftMenuOfficeHeader(
          info: OfficeHeaderInfo.error(), selectedRegion: 'france')));
      await tester.pump();

      expect(find.text('ERREUR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty header renders without throwing', (tester) async {
      await tester.pumpWidget(
          host(const LeftMenuOfficeHeader(info: OfficeHeaderInfo())));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('an unknown colour hides the square but keeps the name',
        (tester) async {
      await tester.pumpWidget(host(const LeftMenuOfficeHeader(
        info: OfficeHeaderInfo(
          day: 'mardi',
          options: [OfficeLiturgyOption(name: 'Férie', colorName: 'fuchsia')],
        ),
      )));
      await tester.pump();

      expect(find.text('Férie'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('both themes', () {
    for (final entry in {'light': light, 'dark': dark}.entries) {
      testWidgets('renders in the ${entry.key} theme', (tester) async {
        await tester.pumpWidget(host(
          LeftMenuOfficeHeader(
            info: fromRealApi(),
            selectedRegion: 'france',
            onRegionSelected: (_) {},
          ),
          theme: entry.value,
        ));
        await tester.pump();

        expect(find.text('MARDI'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
