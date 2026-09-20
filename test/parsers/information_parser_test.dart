import 'package:aelf_flutter/parsers/information_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixtures.dart';

/// Regression net for the online "Informations" tab, over real responses from
/// `api.app.epitre.co/82/office/informations/{date}.json`.
void main() {
  group('InformationParser — a solemnity (Pentecost, 2025-06-08)', () {
    test('produces a single "Informations" tab', () {
      final result = InformationParser.parse(loadFixture('informations.json'));
      expect(result.tabTitles, ['Informations']);
      expect(result.tabData, hasLength(1));
    });

    test('omits the year/week line entirely when psalter_week is null', () {
      // Real behaviour on a solemnity: the API sends psalter_week: null and
      // liturgical_week: null, and _buildSubtitle returns "" for a null week —
      // so the year is dropped with it, even though liturgical_year is "c".
      final result = InformationParser.parse(loadFixture('informations.json'));
      final lines = result.tabData.single.content.trim().split('\n');

      expect(lines, [
        'Pentecôte',
        '---',
        'Couleur liturgique : rouge',
        'Pentecôte',
        'Solennité du Seigneur',
        '---',
      ]);
    });
  });

  group('InformationParser — a ferial day (Tuesday, 2025-06-10)', () {
    test('renders day, year/psalter week and the liturgy option', () {
      final result =
          InformationParser.parse(loadFixture('informations_weekday.json'));
      final lines = result.tabData.single.content.trim().split('\n');

      expect(lines, [
        'Mardi',
        'Année impaire - Semaine II',
        '---',
        'Couleur liturgique : vert',
        '10ème Semaine du Temps Ordinaire',
        'Férie',
        '---',
      ]);
    });

    test('the weekday name is capitalized, the rest lower-cased', () {
      // liturgical_day arrives as "mardi".
      final result =
          InformationParser.parse(loadFixture('informations_weekday.json'));
      expect(result.tabData.single.content, startsWith('Mardi\n'));
    });
  });

  group('InformationParser — psalter week', () {
    test('is romanized', () {
      for (final entry in {1: 'I', 2: 'II', 3: 'III', 4: 'IV'}.entries) {
        final result = InformationParser.parse({
          'informations': {
            'liturgical_day': 'lundi',
            'liturgical_year': 'B',
            'psalter_week': entry.key,
          }
        });
        expect(
            result.tabData.single.content, contains('Semaine ${entry.value}'),
            reason: 'week ${entry.key}');
      }
    });

    test('an out-of-range week degrades to an empty week label', () {
      final result = InformationParser.parse({
        'informations': {
          'liturgical_day': 'lundi',
          'liturgical_year': 'B',
          'psalter_week': 9,
        }
      });
      expect(result.tabData.single.content, contains('Année B - Semaine '));
    });
  });

  test('a missing "informations" key yields an error tab', () {
    final result = InformationParser.parse({'laudes': {}});
    expect(result.tabTitles, ['Erreur']);
    expect(result.tabData.single.content, 'Informations non disponibles');
  });
}
