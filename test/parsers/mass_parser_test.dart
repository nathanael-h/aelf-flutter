import 'package:aelf_flutter/app_screens/mass_parser.dart';
import 'package:aelf_flutter/models/liturgy_tab_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixtures.dart';

/// Regression net for the **online** (AELF API) Mass rendering.
///
/// Mass has no offline twin yet, so this path must keep working unchanged
/// while the offline liturgy is built behind `feature_offline_liturgy`.
void main() {
  group('MassParser — single mass', () {
    late LiturgyParseResult result;

    setUp(() => result = MassParser.parse(loadFixture('mass_single.json')));

    test('produces one tab per lecture, in API order, with no mass menu', () {
      expect(result.tabTitles, [
        'Première Lecture',
        'Psaume',
        'Épître',
        'Séquence',
        'Évangile',
      ]);
      expect(result.massPositions, isEmpty);
      expect(result.tabData, hasLength(result.tabTitles.length));
    });

    test('reading keeps the short tab title and the long content title', () {
      final lecture = result.tabData[0];
      expect(lecture.title, 'Première Lecture');
      expect(
        lecture.contentTitle,
        startsWith('« Ils furent tous remplis'),
      );
      expect(lecture.displayTitle, lecture.contentTitle);
      expect(lecture.ref, 'Ac 2, 1-11');
      expect(lecture.subtitle, 'Lecture du livre des Actes des Apôtres');
    });

    test('psalm ref is prefixed with "Ps" and refrain becomes the subtitle',
        () {
      final psaume = result.tabData[1];
      expect(psaume.ref, startsWith('Ps 103 (104)'));
      expect(psaume.subtitle, startsWith('Ô Seigneur, envoie ton Esprit'));
    });

    test('gospel carries the acclamation verse as intro + introRef', () {
      final evangile = result.tabData.last;
      expect(evangile.title, 'Évangile');
      expect(evangile.ref, 'Jn 20, 19-23');
      expect(evangile.intro, startsWith('Alléluia.'));
      expect(evangile.introRef, 'cf. Ps 103, 30');
      expect(evangile.subtitle, 'Évangile de Jésus Christ selon saint Jean');
    });

    test('sequence has no ref and no subtitle', () {
      final sequence = result.tabData[3];
      expect(sequence.title, 'Séquence');
      expect(sequence.ref, '');
      expect(sequence.subtitle, '');
      expect(sequence.content, contains('Viens, Esprit Saint'));
    });

    test('every tab carries non-empty content', () {
      for (final tab in result.tabData) {
        expect(tab.content, isNotEmpty,
            reason: 'empty content in ${tab.title}');
      }
    });
  });

  group('MassParser — several masses', () {
    late LiturgyParseResult result;

    setUp(() => result = MassParser.parse(loadFixture('mass_multiple.json')));

    test('inserts one "Messes" menu tab before each mass', () {
      expect(result.tabTitles, [
        'Messes',
        'Première Lecture',
        'Évangile',
        'Messes',
        'Première Lecture',
        'Deuxième Lecture',
        'Cantique',
        'Évangile',
      ]);
    });

    test('massPositions points at each menu tab', () {
      expect(result.massPositions, [0, 3]);
      for (final position in result.massPositions) {
        expect(result.tabData[position].content, '__MASS_MENU__');
      }
    });

    test('numbered readings map to French ordinals', () {
      expect(result.tabData[4].title, 'Première Lecture');
      expect(result.tabData[5].title, 'Deuxième Lecture');
    });

    test('cantique keeps its raw ref and uses the refrain as subtitle', () {
      final cantique = result.tabData[6];
      expect(cantique.title, 'Cantique');
      expect(cantique.ref, 'Is 12, 2-6');
      expect(cantique.subtitle, startsWith('Vous puiserez les eaux'));
    });
  });

  group('MassParser — degraded input', () {
    test('missing "messes" key yields a single error tab', () {
      final result = MassParser.parse({'laudes': {}});
      expect(result.tabTitles, ['Erreur']);
      expect(result.tabData.single.content, 'Format de données invalide');
    });

    test('server-side erreur_technique is surfaced verbatim', () {
      final result = MassParser.parse({
        'messes': {'erreur_technique': "Nous n'avons pas trouvé cette lecture."}
      });
      expect(result.tabTitles, ['Erreur']);
      expect(
        result.tabData.single.content,
        "Nous n'avons pas trouvé cette lecture.",
      );
    });

    test('"messes" of an unexpected type yields an error tab', () {
      final result = MassParser.parse({'messes': 'oops'});
      expect(result.tabTitles, ['Erreur']);
      expect(result.tabData.single.content, contains("n'est pas une liste"));
    });

    test('an unknown lecture type is skipped rather than crashing', () {
      final result = MassParser.parse({
        'messes': [
          {
            'lectures': [
              {'type': 'type_inconnu', 'contenu': '<p>x</p>', 'ref': ''},
              {'type': 'sequence', 'contenu': '<p>y</p>', 'ref': ''},
            ]
          }
        ]
      });
      expect(result.tabTitles, ['Séquence']);
    });
  });
}
