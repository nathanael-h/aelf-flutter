import 'package:aelf_flutter/models/office_header_info.dart';
import 'package:aelf_flutter/utils/region_sync.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/left_menu_office_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
/// Counts how many times the logo asset is read from the bundle.
class _LogoLoadCounter extends CachingAssetBundle {
  int logoLoads = 0;

  @override
  Future<ByteData> load(String key) {
    if (key.endsWith('aelf_logo.svg')) logoLoads++;
    return rootBundle.load(key);
  }
}

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

    testWidgets('does not list the API liturgy options', (tester) async {
      await tester.pumpWidget(host(LeftMenuOfficeHeader(
        info: fromRealApi(),
        selectedRegion: 'france',
        onRegionSelected: (_) {},
      )));
      await tester.pump();

      expect(find.textContaining('Autres célébrations'), findsNothing);
      expect(find.text('10ème Semaine du Temps Ordinaire'), findsNothing);
      expect(find.text('Férie'), findsNothing);
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

      expect(find.text('PENTECÔTE'), findsOneWidget);
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
        degree: 'Fête',
        colorName: 'white',
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
      expect(find.text('Fête'), findsOneWidget);
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
      const english = OfficeHeaderInfo(colorName: 'red');
      const french = OfficeHeaderInfo(colorName: 'rouge');

      late BuildContext ctx;
      await tester.pumpWidget(host(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      expect(english.squareColor(ctx), french.squareColor(ctx));
      expect(english.squareColor(ctx), AelfLiturgicalColors.lightColors.red);
    });
  });

  group('the logo', () {
    testWidgets('is not reloaded when the header rebuilds', (tester) async {
      final bundle = _LogoLoadCounter();
      late StateSetter rebuild;
      var rebuilds = 0;

      await tester.pumpWidget(DefaultAssetBundle(
        bundle: bundle,
        child: host(StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          // A fresh widget and info on every pass, as LeftMenu hands over.
          return LeftMenuOfficeHeader(
            info: OfficeHeaderInfo(day: 'jeudi', seasonText: 'Pass $rebuilds'),
          );
        })),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      expect(bundle.logoLoads, 1);

      for (var i = 0; i < 3; i++) {
        rebuild(() => rebuilds++);
        await tester.pump();
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
      }

      expect(bundle.logoLoads, 1,
          reason: 'each reload re-reads and re-parses the SVG in an isolate');
    });
  });

  group('the header layout', () {
    testWidgets('the title spans above the logo, the details sit to its right',
        (tester) async {
      await tester.pumpWidget(host(Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 304,
          child: LeftMenuOfficeHeader(
            info: OfficeHeaderInfo.fromOfflineDay(
              day: 'jeudi',
              seasonText: 'Temps Ordinaire',
              liturgicalYear: 'impaire',
              psalterWeek: 1,
            ),
          ),
        ),
      )));
      await tester.pump();

      final logo = tester.getRect(find.byType(SvgPicture));
      final title = tester.getRect(find.text('JEUDI'));
      final time = tester.getRect(find.textContaining('Année'));

      expect(title.bottom, lessThanOrEqualTo(logo.top),
          reason: 'the title is entirely above the logo');
      expect(title.left, lessThan(logo.right),
          reason: 'the title runs over the logo column, not beside it');
      expect(time.left, greaterThanOrEqualTo(logo.right),
          reason: 'the other fields stay to the right of the logo');
    });
  });

  group('the degree / season line', () {
    // The drawer's width: narrow enough for the long season text to wrap.
    Future<void> pumpDrawerHeader(WidgetTester tester) async {
      await tester.pumpWidget(host(Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 304,
          child: LeftMenuOfficeHeader(
            info: OfficeHeaderInfo.fromOfflineDay(
              day: 'jeudi',
              seasonText: '25ème semaine du Temps Ordinaire',
              colorName: 'green',
              liturgicalYear: 'impaire',
              psalterWeek: 1,
            ),
          ),
        ),
      )));
      await tester.pump();
    }

    /// The global y of each line's baseline in the paragraph showing [text].
    List<double> baselines(WidgetTester tester, String text) {
      final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
          of: find.textContaining(text), matching: find.byType(RichText)));
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
      )..layout(maxWidth: paragraph.size.width);
      final top = paragraph.localToGlobal(Offset.zero).dy;
      return [for (final l in painter.computeLineMetrics()) top + l.baseline];
    }

    testWidgets('a wrapped line is tighter than the gap to the next line',
        (tester) async {
      await pumpDrawerHeader(tester);

      final season = baselines(tester, 'Ordinaire');
      final time = baselines(tester, 'Année');
      expect(season.length, greaterThan(1),
          reason: 'the season text must wrap for this to mean anything');

      final interline = season[1] - season[0];
      final gap = time.first - season.last;
      expect(interline, lessThan(gap));
    });

    testWidgets("the colour square sits on the first line's baseline",
        (tester) async {
      await pumpDrawerHeader(tester);

      final square = tester.getRect(find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 9 && w.height == 9));
      expect(square.bottom, closeTo(baselines(tester, 'Ordinaire').first, 1));
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
          degree: 'Férie',
          colorName: 'fuchsia',
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
