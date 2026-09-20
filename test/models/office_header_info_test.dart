import 'package:aelf_flutter/models/office_header_info.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixtures.dart';

/// `OfficeHeaderInfo.fromApi` builds the offices/mass drawer header from the
/// online `informations` block. Mass has no offline twin, and every section
/// falls back to this path when the offline flag is off, so it must keep
/// working regardless of the offline liturgy work.
void main() {
  Map<dynamic, dynamic> informationsBlock() =>
      loadFixture('informations.json')['informations'] as Map<dynamic, dynamic>;

  group('OfficeHeaderInfo.fromApi — a solemnity (Pentecost)', () {
    test('maps day, year and region; psalter week is absent', () {
      final header =
          OfficeHeaderInfo.fromApi(informationsBlock(), region: 'france');

      // liturgical_day is the feast name here, not a weekday.
      expect(header.day, 'Pentecôte');
      // liturgical_year arrives lower-case ("c") and is capitalized.
      expect(header.liturgicalYear, 'C');
      // A solemnity carries no psalter week.
      expect(header.psalterWeek, isNull);
      expect(header.region, 'france');
      expect(header.isLoading, isFalse);
      expect(header.isError, isFalse);
    });

    test('falls back to the payload zone when no region is passed', () {
      expect(OfficeHeaderInfo.fromApi(informationsBlock()).region, 'france');
    });

    test('the subtitle drops the missing week half', () {
      expect(OfficeHeaderInfo.fromApi(informationsBlock()).timeText, 'Année C');
    });

    test('keeps the single liturgy option with its degree and colour', () {
      final header = OfficeHeaderInfo.fromApi(informationsBlock());

      expect(header.options, hasLength(1));
      expect(header.options.single.name, 'Pentecôte');
      expect(header.options.single.degree, 'Solennité du Seigneur');
      expect(header.options.single.colorName, 'rouge');
    });
  });

  group('OfficeHeaderInfo.fromApi — a ferial day (Tuesday)', () {
    Map<dynamic, dynamic> weekday() =>
        loadFixture('informations_weekday.json')['informations']
            as Map<dynamic, dynamic>;

    test('maps weekday, year and romanized psalter week', () {
      final header = OfficeHeaderInfo.fromApi(weekday(), region: 'france');

      expect(header.day, 'Mardi');
      expect(header.liturgicalYear, 'Impaire');
      expect(header.psalterWeek, 'II');
    });

    test('builds the full subtitle', () {
      expect(OfficeHeaderInfo.fromApi(weekday()).timeText,
          'Année Impaire — Semaine II');
    });

    test('capitalizes the option name', () {
      final header = OfficeHeaderInfo.fromApi(weekday());
      expect(header.options.single.name, '10ème Semaine du Temps Ordinaire');
      expect(header.options.single.degree, 'Férie');
      expect(header.options.single.colorName, 'vert');
    });
  });

  group('OfficeHeaderInfo.fromApi — edge cases', () {
    test('omits the missing half of the subtitle', () {
      expect(OfficeHeaderInfo.fromApi({'liturgical_year': 'B'}).timeText,
          'Année B');
      expect(
          OfficeHeaderInfo.fromApi({'psalter_week': 2}).timeText, 'Semaine II');
      expect(OfficeHeaderInfo.fromApi({}).timeText, isEmpty);
    });

    test('drops nameless options and a non-list liturgy_options', () {
      expect(
        OfficeHeaderInfo.fromApi({
          'liturgy_options': [
            {'liturgical_name': ''},
            {'liturgical_name': 'férie'},
          ]
        }).options.map((o) => o.name),
        ['Férie'],
      );
      expect(OfficeHeaderInfo.fromApi({'liturgy_options': 'oops'}).options,
          isEmpty);
    });

    test('psalter_week accepts both an int and a numeric string', () {
      expect(OfficeHeaderInfo.fromApi({'psalter_week': 4}).psalterWeek, 'IV');
      expect(OfficeHeaderInfo.fromApi({'psalter_week': '2'}).psalterWeek, 'II');
    });

    test('an out-of-range psalter week falls back to the raw number', () {
      expect(OfficeHeaderInfo.fromApi({'psalter_week': 7}).psalterWeek, '7');
    });

    test('blank strings are normalized to null so rows are hidden', () {
      final header = OfficeHeaderInfo.fromApi(
          {'liturgical_day': '   ', 'liturgical_year': '', 'zone': ''});
      expect(header.day, isNull);
      expect(header.liturgicalYear, isNull);
      expect(header.region, isNull);
      expect(header.timeText, isEmpty);
    });

    test('an empty payload does not throw', () {
      final header = OfficeHeaderInfo.fromApi({});
      expect(header.day, isNull);
      expect(header.psalterWeek, isNull);
      expect(header.options, isEmpty);
    });
  });

  group('OfficeHeaderInfo states', () {
    test('loading and error carry their flags and nothing else', () {
      const loading = OfficeHeaderInfo.loading();
      expect(loading.isLoading, isTrue);
      expect(loading.isError, isFalse);
      expect(loading.options, isEmpty);

      const error = OfficeHeaderInfo.error();
      expect(error.isError, isTrue);
      expect(error.isLoading, isFalse);
    });
  });

  group('OfficeLiturgyOption.squareColor', () {
    testWidgets('resolves French API colour names against the theme',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        theme: light,
        home: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ));

      expect(
        const OfficeLiturgyOption(name: 'x', colorName: 'rouge')
            .squareColor(ctx),
        AelfLiturgicalColors.lightColors.red,
      );
      expect(
        const OfficeLiturgyOption(name: 'x', colorName: 'blanc')
            .squareColor(ctx),
        AelfLiturgicalColors.lightColors.white,
      );
    });

    testWidgets('an unknown or missing colour hides the square (null)',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        theme: light,
        home: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ));

      expect(
        const OfficeLiturgyOption(name: 'x', colorName: 'fuchsia')
            .squareColor(ctx),
        isNull,
      );
      expect(const OfficeLiturgyOption(name: 'x').squareColor(ctx), isNull);
    });
  });
}
