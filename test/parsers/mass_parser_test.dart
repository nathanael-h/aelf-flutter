import 'package:aelf_flutter/app_screens/mass_parser.dart';
import 'package:aelf_flutter/models/liturgy_tab_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixtures.dart';

/// Regression net for the **online** (AELF API) Mass rendering, over real API
/// responses (see `test/fixtures/README.md`).
///
/// Mass has no offline twin yet, so this path must keep working unchanged
/// while the offline liturgy is built behind `feature_offline_liturgy`.
void main() {
  group('MassParser — one mass (ordinary Tuesday, 2025-06-10)', () {
    late LiturgyParseResult result;

    setUp(() => result = MassParser.parse(loadFixture('mass_single.json')));

    test('produces one tab per lecture, in API order, with no mass menu', () {
      expect(result.tabTitles, ['Première Lecture', 'Psaume', 'Évangile']);
      expect(result.massPositions, isEmpty);
      expect(result.tabData, hasLength(3));
    });

    test('reading keeps the short tab title and the long content title', () {
      final lecture = result.tabData[0];
      expect(lecture.title, 'Première Lecture');
      expect(lecture.contentTitle, startsWith('« Le Christ Jésus'));
      expect(lecture.displayTitle, lecture.contentTitle);
      expect(lecture.ref, '2 Co 1, 18-22');
      expect(lecture.subtitle,
          'Lecture de la deuxième lettre de saint Paul apôtre aux Corinthiens');
    });

    test('psalm ref is prefixed with "Ps" and refrain becomes the subtitle',
        () {
      final psaume = result.tabData[1];
      expect(psaume.ref, 'Ps 118 (119), 129-130, 131-132, 133.135');
      expect(psaume.subtitle, contains('que ton visage s’illumine'));
    });

    test('gospel carries the acclamation verse as intro + introRef', () {
      final evangile = result.tabData[2];
      expect(evangile.title, 'Évangile');
      expect(evangile.contentTitle, '« Vous êtes le sel de la terre »');
      expect(evangile.ref, 'Mt 5, 13-16');
      expect(evangile.intro, contains('Alléluia'));
      expect(evangile.introRef, 'Mt 5, 16');
      expect(
          evangile.subtitle, 'Évangile de Jésus Christ selon saint Matthieu');
    });

    test('every tab carries non-empty content', () {
      for (final tab in result.tabData) {
        expect(tab.content, isNotEmpty,
            reason: 'empty content in ${tab.title}');
      }
    });
  });

  group('MassParser — two masses (Pentecost, 2025-06-08)', () {
    late LiturgyParseResult result;

    setUp(() => result = MassParser.parse(loadFixture('mass_multiple.json')));

    test('inserts one "Messes" menu tab before each mass', () {
      expect(result.tabTitles, [
        'Messes',
        'Première Lecture',
        'Première Lecture',
        'Première Lecture',
        'Première Lecture',
        'Psaume',
        'Deuxième Lecture',
        'Évangile',
        'Messes',
        'Première Lecture',
        'Psaume',
        'Deuxième Lecture',
        'Séquence',
        'Évangile',
      ]);
    });

    test('massPositions points at each menu tab', () {
      expect(result.massPositions, [0, 8]);
      for (final position in result.massPositions) {
        expect(result.tabData[position].content, '__MASS_MENU__');
      }
    });

    test(
        'the vigil\'s four readings are all typed lecture_1, so all four tabs '
        'are titled "Première Lecture"', () {
      // Real API behaviour, not a parser bug: the Pentecost vigil offers four
      // alternative first readings and the API types every one of them
      // `lecture_1`. The tab bar therefore shows four identical labels, and
      // only the content title tells them apart. Pinned here so the rendering
      // cannot change unnoticed — and as a record of a real UX wart.
      final vigil = result.tabData.sublist(1, 5);
      expect(vigil.map((t) => t.title), everyElement('Première Lecture'));
      expect(
        vigil.map((t) => t.ref),
        [
          // \u00a0 is a real non-breaking space in the API payload: AELF glues
          // the verse numbers to the chapter so a reference never wraps
          // mid-citation. Written as an escape here so it is visible.
          'Gn 11,\u00a01-9',
          'Ex 19, 3-8a.16-20b',
          'Ez 37,\u00a01-14',
          'Jl 3,\u00a01-5a',
        ],
        reason: 'the four readings are distinguished only by ref/content title',
      );
      expect(vigil.map((t) => t.contentTitle).toSet(), hasLength(4));
    });

    test('a ref that already starts with a space keeps the doubled "Ps  "', () {
      // The API sends " 103 (104), …" for this psalm and the parser prepends
      // "Ps ", producing a visible double space. Pinned so that cleaning it up
      // is a deliberate change with a test to update, not a silent drift.
      expect(result.tabData[5].ref,
          'Ps  103 (104),\u00a01-2a, 24.35c, 27-28\u00a0, 29bc-30');
    });

    test('references keep the API non-breaking spaces', () {
      // These reach flutter_html as-is and stop a citation wrapping between
      // the chapter and its verses. Stripping or normalising them would change
      // how every reference lays out.
      expect(result.tabData[1].ref, contains('\u00a0'));
      expect(result.tabData[5].ref, contains('\u00a0'));
    });

    test('a gospel with no ref_verset yields an intro but an empty introRef',
        () {
      final vigilGospel = result.tabData[7];
      expect(vigilGospel.title, 'Évangile');
      expect(vigilGospel.intro, contains('Alléluia'));
      expect(vigilGospel.introRef, isEmpty);
    });

    test('the sequence appears only in the day mass', () {
      expect(result.tabTitles.sublist(1, 8), isNot(contains('Séquence')));
      final sequence = result.tabData[12];
      expect(sequence.title, 'Séquence');
      expect(sequence.subtitle, isEmpty);
      expect(sequence.content, contains('Viens, Esprit Saint'));
    });

    test('numbered readings map to French ordinals', () {
      expect(result.tabData[6].title, 'Deuxième Lecture');
      expect(result.tabData[11].title, 'Deuxième Lecture');
    });
  });

  group('MassParser — degraded input', () {
    test('missing "messes" key yields a single error tab', () {
      final result = MassParser.parse({'laudes': {}});
      expect(result.tabTitles, ['Erreur']);
      expect(result.tabData.single.content, 'Format de données invalide');
    });

    test('server-side erreur_technique is surfaced verbatim', () {
      // The shape LiturgyState synthesises for a 404 — see fixtures/README.md.
      final result = MassParser.parse({
        'messes': {'erreur_technique': "Nous n'avons pas trouvé cette lecture."}
      });
      expect(result.tabTitles, ['Erreur']);
      expect(result.tabData.single.content,
          "Nous n'avons pas trouvé cette lecture.");
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
