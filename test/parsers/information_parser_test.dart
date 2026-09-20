import 'package:aelf_flutter/parsers/information_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixtures.dart';

/// Regression net for the online "Informations" tab, built from the
/// `82/office/informations/{date}.json` endpoint on api.app.epitre.co.
void main() {
  group('InformationParser', () {
    test('produces a single "Informations" tab', () {
      final result = InformationParser.parse(loadFixture('informations.json'));
      expect(result.tabTitles, ['Informations']);
      expect(result.tabData, hasLength(1));
    });

    test('renders day, year/psalter week and every liturgy option', () {
      final result = InformationParser.parse(loadFixture('informations.json'));
      final lines = result.tabData.single.content.trim().split('\n');

      expect(lines, [
        'Dimanche',
        'Année C - Semaine III',
        '---',
        'Couleur liturgique : rouge',
        'Dimanche de la Pentecôte',
        'Solennité',
        '---',
        'Couleur liturgique : blanc',
        'Saint Médard, évêque',
        'Mémoire facultative',
        '---',
      ]);
    });

    test('psalter week is romanized', () {
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

    test('an out-of-range psalter week degrades to an empty week label', () {
      final result = InformationParser.parse({
        'informations': {
          'liturgical_day': 'lundi',
          'liturgical_year': 'B',
          'psalter_week': 9,
        }
      });
      expect(result.tabData.single.content, contains('Année B - Semaine '));
    });

    test('a missing psalter week drops the whole subtitle line', () {
      final result = InformationParser.parse({
        'informations': {'liturgical_day': 'lundi', 'liturgical_year': 'B'}
      });
      final lines = result.tabData.single.content.trim().split('\n');
      expect(lines, ['Lundi', '---']);
    });

    test('a missing "informations" key yields an error tab', () {
      final result = InformationParser.parse({'laudes': {}});
      expect(result.tabTitles, ['Erreur']);
      expect(result.tabData.single.content, 'Informations non disponibles');
    });
  });
}
