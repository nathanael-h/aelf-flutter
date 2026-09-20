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

  group('OfficeHeaderInfo.fromApi', () {
    test('maps day, year, psalter week and region', () {
      final info = informationsBlock();
      final header = OfficeHeaderInfo.fromApi(info, region: 'france');

      expect(header.day, 'Dimanche');
      expect(header.liturgicalYear, 'C');
      expect(header.psalterWeek, 'III');
      expect(header.region, 'france');
      expect(header.isLoading, isFalse);
      expect(header.isError, isFalse);
    });

    test('falls back to the payload zone when no region is passed', () {
      final header = OfficeHeaderInfo.fromApi(informationsBlock());
      expect(header.region, 'france');
    });

    test('builds the subtitle as "Année X — Semaine Y"', () {
      final header = OfficeHeaderInfo.fromApi(informationsBlock());
      expect(header.timeText, 'Année C — Semaine III');
    });

    test('omits the missing half of the subtitle', () {
      expect(
        OfficeHeaderInfo.fromApi({'liturgical_year': 'B'}).timeText,
        'Année B',
      );
      expect(
        OfficeHeaderInfo.fromApi({'psalter_week': 2}).timeText,
        'Semaine II',
      );
      expect(OfficeHeaderInfo.fromApi({}).timeText, isEmpty);
    });

    test('capitalizes every liturgy option name and keeps degree + colour', () {
      final header = OfficeHeaderInfo.fromApi(informationsBlock());

      expect(header.options, hasLength(2));
      expect(header.options[0].name, 'Dimanche de la Pentecôte');
      expect(header.options[0].degree, 'Solennité');
      expect(header.options[0].colorName, 'rouge');
      expect(header.options[1].name, 'Saint Médard, évêque');
      expect(header.options[1].colorName, 'blanc');
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
      expect(
        OfficeHeaderInfo.fromApi({'liturgy_options': 'oops'}).options,
        isEmpty,
      );
    });

    test('psalter_week accepts both an int and a numeric string', () {
      expect(OfficeHeaderInfo.fromApi({'psalter_week': 4}).psalterWeek, 'IV');
      expect(OfficeHeaderInfo.fromApi({'psalter_week': '2'}).psalterWeek, 'II');
    });

    test('an out-of-range psalter week falls back to the raw number', () {
      expect(OfficeHeaderInfo.fromApi({'psalter_week': 7}).psalterWeek, '7');
    });

    test('blank strings are normalized to null so rows are hidden', () {
      final header = OfficeHeaderInfo.fromApi({
        'liturgical_day': '   ',
        'liturgical_year': '',
        'zone': '',
      });
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
