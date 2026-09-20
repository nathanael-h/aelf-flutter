import 'package:aelf_flutter/app_screens/office_parser.dart';
import 'package:aelf_flutter/models/liturgy_tab_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixtures.dart';

/// Regression net for the **online** (AELF API) Divine Office rendering, over
/// real API responses (see `test/fixtures/README.md`). All four offices are
/// from Pentecost 2025-06-08, France.
///
/// These offices are the ones the `offline_*` views are meant to replace
/// eventually; until that lands and is merged, the API-backed path must keep
/// producing exactly these tabs.
void main() {
  LiturgyTabData tabNamed(LiturgyParseResult r, String title) =>
      r.tabData.firstWhere((t) => t.title == title);

  group('OfficeParser — laudes', () {
    late LiturgyParseResult result;

    setUp(() => result = OfficeParser.parse(loadFixture('office_laudes.json')));

    test('emits the office parts in API order, skipping antiphon keys', () {
      expect(result.tabTitles, [
        'Introduction',
        'Psaume invitatoire',
        'Hymne',
        'Psaume 62',
        // Trailing space is in the API's `titre`; kept verbatim.
        'Cantique des trois enfants ',
        'Psaume 149',
        'Parole de Dieu',
        'Cantique de Zacharie',
        'Intercession',
        'Notre Père',
        'Oraison et bénédiction',
      ]);
    });

    test('invitatory psalm takes antienne_invitatoire and a "Ps " ref', () {
      final invit = tabNamed(result, 'Psaume invitatoire');
      expect(invit.ref, 'Ps 94');
      expect(invit.subtitle, contains('Antienne : '));
      expect(invit.subtitle, contains('Alléluia'));
      expect(invit.repeatSubtitle, isTrue);
    });

    test('psalm picks up its matching antienne_N as an "Antienne :" subtitle',
        () {
      final psaume = tabNamed(result, 'Psaume 62');
      expect(psaume.ref, 'Ps 62');
      expect(psaume.subtitle, contains('Antienne : '));
      expect(psaume.subtitle, contains('ton souffle en nous est bon'));
      expect(psaume.repeatSubtitle, isTrue,
          reason: 'the antiphon is repeated after the psalm text');
    });

    test('psalms get a "Gloire au Père" doxology appended to the last <p>', () {
      expect(tabNamed(result, 'Psaume 62').content,
          endsWith('Gloire au Père, ...</p>'));
    });

    test('the Benedictus is matched to antienne_zacharie', () {
      // `cantique_zacharie` is not in OfficeParser's switch — it falls through
      // to the numbered psalm/canticle branch, which splits the key on "_" and
      // looks up `antienne_zacharie`. Incidental, but it is what makes the
      // Benedictus antiphon appear, so it is pinned here.
      final zacharie = tabNamed(result, 'Cantique de Zacharie');
      expect(zacharie.ref, 'Lc 1');
      expect(zacharie.subtitle, contains('Antienne : '));
      expect(zacharie.subtitle, contains('Recevez l’Esprit Saint'));
      expect(zacharie.repeatSubtitle, isTrue);
    });

    test('pericope stitches the répons into the content under a Répons title',
        () {
      final parole = tabNamed(result, 'Parole de Dieu');
      expect(parole.ref, 'Ac 5, 30-32');
      expect(parole.content, contains('<p class="repons">Répons</p>'));
      expect(parole.content, contains('remplis de l’Esprit Saint'));
    });

    test('Notre Père is rendered from the hardcoded text, not the API value',
        () {
      // The API sends the string "Notre Père" — a marker, not the prayer.
      final pater = tabNamed(result, 'Notre Père');
      expect(pater.content, startsWith('Notre Père, qui es aux cieux'));
      expect(pater.content, endsWith('Amen'));
    });

    test('oraison appends the final blessing', () {
      final oraison = tabNamed(result, 'Oraison et bénédiction');
      expect(oraison.content, contains('Que le seigneur nous bénisse'));
      expect(oraison.content, endsWith('Amen.'));
    });

    test('hymn title becomes the subtitle, not the tab title', () {
      final hymne = tabNamed(result, 'Hymne');
      expect(hymne.subtitle, 'Amour qui planais sur les eaux ');
      expect(hymne.content, isNotEmpty);
    });
  });

  group('OfficeParser — office des lectures', () {
    late LiturgyParseResult result;

    setUp(
        () => result = OfficeParser.parse(loadFixture('office_lectures.json')));

    test('emits the readings-office parts in API order', () {
      expect(result.tabTitles, [
        'Introduction',
        'Hymne',
        'Psaume 103 - I',
        'Psaume 103 - II',
        'Psaume 103 - III',
        'Verset',
        'Lecture',
        'Lecture patristique',
        'Te Deum',
        'Oraison et bénédiction',
      ]);
    });

    test('each part of a split psalm keeps its own antiphon', () {
      for (final title in [
        'Psaume 103 - I',
        'Psaume 103 - II',
        'Psaume 103 - III'
      ]) {
        expect(tabNamed(result, title).subtitle, contains('Antienne : '),
            reason: title);
      }
      // Distinct antiphons, i.e. antienne_1/2/3 were each matched.
      final subtitles = [
        'Psaume 103 - I',
        'Psaume 103 - II',
        'Psaume 103 - III'
      ].map((t) => tabNamed(result, t).subtitle).toSet();
      expect(subtitles, hasLength(3));
    });

    test('scripture reading keeps a short tab title and a quoted content title',
        () {
      final lecture = tabNamed(result, 'Lecture');
      expect(lecture.title, 'Lecture');
      expect(lecture.displayTitle, startsWith('«'));
      expect(lecture.displayTitle, endsWith('»'));
      expect(lecture.ref, isNotEmpty);
      expect(lecture.content, contains('<p class="repons">Répons</p>'));
    });

    test('patristic reading pulls its title and répons from sibling keys', () {
      final patristique = tabNamed(result, 'Lecture patristique');
      expect(patristique.displayTitle,
          '« TRAITÉ DE SAINT IRÉNÉE CONTRE LES HÉRÉSIES »');
      expect(patristique.content, contains('<p class="repons">Répons</p>'));
      expect(patristique.content, contains("L'envoi de l'Esprit"),
          reason: 'the patristic text itself');
      expect(patristique.content, contains("Le Seigneur, c'est l'Esprit"),
          reason: 'repons_patristique, stitched in after the Répons title');
    });

    test('verset_psaume becomes a "Verset" tab', () {
      expect(tabNamed(result, 'Verset').content, contains('alléluia'));
    });

    test('te_deum takes its title from the API', () {
      expect(tabNamed(result, 'Te Deum').content, isNotEmpty);
    });
  });

  group('OfficeParser — vêpres', () {
    late LiturgyParseResult result;

    setUp(() => result = OfficeParser.parse(loadFixture('office_vepres.json')));

    test('emits the vespers parts in API order', () {
      expect(result.tabTitles, [
        'Introduction',
        'Hymne',
        'Psaume 109',
        'Psaume 113a',
        'Cantique ',
        'Parole de Dieu',
        'Cantique de Marie',
        'Intercession',
        'Notre Père',
        'Oraison et bénédiction',
      ]);
    });

    test('the Magnificat is matched to antienne_marie', () {
      final marie = tabNamed(result, 'Cantique de Marie');
      expect(marie.ref, 'Lc 1');
      expect(marie.subtitle, contains('Antienne : '));
      expect(marie.repeatSubtitle, isTrue);
    });

    test('a psalm reference with a letter suffix is kept', () {
      expect(tabNamed(result, 'Psaume 113a').ref, 'Ps 113a');
    });
  });

  group('OfficeParser — complies', () {
    late LiturgyParseResult result;

    setUp(
        () => result = OfficeParser.parse(loadFixture('office_complies.json')));

    test('emits the compline parts in API order', () {
      expect(result.tabTitles, [
        'Introduction',
        'Hymne',
        'Psaume 90',
        'Parole de Dieu',
        'Cantique de Syméon',
        'Oraison et bénédiction',
        'Reine du ciel, réjouis-toi, alléluia',
      ]);
    });

    test('the Marian hymn becomes its own tab, titled from the API', () {
      final marial = tabNamed(result, 'Reine du ciel, réjouis-toi, alléluia');
      expect(marial.content, isNotEmpty);
      expect(marial.ref, isEmpty);
    });

    test('the Nunc Dimittis is matched to antienne_symeon', () {
      final symeon = tabNamed(result, 'Cantique de Syméon');
      expect(symeon.ref, 'Lc 2');
      expect(symeon.subtitle, contains('Antienne : '));
    });
  });

  group('OfficeParser — every real office', () {
    for (final fixture in [
      'office_laudes.json',
      'office_lectures.json',
      'office_vepres.json',
      'office_complies.json',
    ]) {
      test('$fixture produces only non-empty titles and content', () {
        final result = OfficeParser.parse(loadFixture(fixture));
        expect(result.tabTitles, isNotEmpty);
        for (final tab in result.tabData) {
          expect(tab.title, isNotEmpty);
          expect(tab.content, isNotEmpty, reason: 'empty tab "${tab.title}"');
        }
      });
    }
  });

  group('OfficeParser — degraded input', () {
    test('erreur_technique becomes a single Erreur tab', () {
      final result = OfficeParser.parse(loadFixture('office_error.json'));
      expect(result.tabTitles, ['Erreur']);
      expect(result.tabData.single.content,
          "Nous n'avons pas trouvé cette lecture.");
    });

    test('null, empty and empty-list parts are skipped', () {
      final result = OfficeParser.parse({
        'laudes': {
          'introduction': '<p>Dieu, viens à mon aide.</p>',
          'hymne': null,
          'intercession': '',
          'psaume_1': [],
          'oraison': '<p>Amen.</p>',
        }
      });
      expect(result.tabTitles, ['Introduction', 'Oraison et bénédiction']);
    });

    test('an unknown part key is ignored', () {
      final result = OfficeParser.parse({
        'vepres': {
          'cle_inconnue': 'valeur',
          'introduction': '<p>Dieu, viens à mon aide.</p>',
        }
      });
      expect(result.tabTitles, ['Introduction']);
    });
  });
}
