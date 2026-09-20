import 'package:aelf_flutter/app_screens/office_parser.dart';
import 'package:aelf_flutter/models/liturgy_tab_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixtures.dart';

/// Regression net for the **online** (AELF API) Divine Office rendering
/// (laudes, vêpres, lectures, complies…).
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
        'Hymne',
        'Psaume 5, 2-3.5-6a.7.9-10.11cd.12',
        'Cantique des trois enfants',
        'Psaume 28 (29), 1-2 - II',
        'Parole de Dieu',
        'Cantique de Zacharie',
        'Intercession',
        'Notre Père',
        'Oraison et bénédiction',
        'Salve Regina',
      ]);
    });

    test('psalm picks up its matching antienne_N as an "Antienne :" subtitle',
        () {
      final psaume = tabNamed(result, 'Psaume 5, 2-3.5-6a.7.9-10.11cd.12');
      expect(psaume.subtitle, contains('Antienne : '));
      expect(psaume.subtitle, contains('Au matin, tu écoutes ma voix'));
      expect(psaume.repeatSubtitle, isTrue,
          reason: 'the antiphon is repeated after the psalm text');
      expect(psaume.ref, 'Ps 5, 2-3.5-6a.7.9-10.11cd.12');
    });

    test('a split psalm with no antienne_N falls back to the previous one', () {
      final split = tabNamed(result, 'Psaume 28 (29), 1-2 - II');
      expect(split.subtitle, contains('Nous te louons, Seigneur'),
          reason: 'antienne_3 is absent, so antienne_2 carries over');
    });

    test('psalms get a "Gloire au Père" doxology appended to the last <p>', () {
      final psaume = tabNamed(result, 'Psaume 5, 2-3.5-6a.7.9-10.11cd.12');
      expect(psaume.content, endsWith('Gloire au Père, ...</p>'));
    });

    test('canticle keeps its own title and raw (unprefixed) reference', () {
      final cantique = tabNamed(result, 'Cantique des trois enfants');
      expect(cantique.ref, 'Dn 3, 57-88.56');
      expect(cantique.subtitle, contains('Nous te louons, Seigneur'));
    });

    test('pericope stitches the répons into the content under a Répons title',
        () {
      final parole = tabNamed(result, 'Parole de Dieu');
      expect(parole.ref, 'Rm 8, 11');
      expect(parole.content, contains("Si l'Esprit de celui"));
      expect(parole.content, contains('<p class="repons">Répons</p>'));
      expect(parole.content, contains('Le Christ est ressuscité'));
    });

    test('gospel canticle uses antienne_magnificat as its subtitle', () {
      final zacharie = tabNamed(result, 'Cantique de Zacharie');
      expect(zacharie.ref, 'Lc 1, 68-79');
      expect(zacharie.subtitle, contains("Béni soit le Seigneur"));
      expect(zacharie.repeatSubtitle, isTrue);
    });

    test('Notre Père is rendered from the hardcoded text, not the API value',
        () {
      final pater = tabNamed(result, 'Notre Père');
      expect(pater.content, startsWith('Notre Père, qui es aux cieux'));
      expect(pater.content, endsWith('Amen'));
      expect(pater.content, isNot(contains('1')));
    });

    test('oraison appends the final blessing', () {
      final oraison = tabNamed(result, 'Oraison et bénédiction');
      expect(oraison.content, contains('accorde-nous ta paix'));
      expect(oraison.content, contains('Que le seigneur nous bénisse'));
      expect(oraison.content, endsWith('Amen.'));
    });

    test('hymn title becomes the subtitle, not the tab title', () {
      final hymne = tabNamed(result, 'Hymne');
      expect(hymne.subtitle, 'Voici le jour du Seigneur');
      expect(hymne.content, contains('Voici le jour du Seigneur'));
    });
  });

  group('OfficeParser — office des lectures', () {
    late LiturgyParseResult result;

    setUp(
        () => result = OfficeParser.parse(loadFixture('office_lectures.json')));

    test('emits the readings-office parts in API order', () {
      expect(result.tabTitles, [
        'Introduction',
        'Psaume invitatoire',
        'Psaume 22 (23)',
        'Lecture',
        'Lecture patristique',
        'Te Deum',
        'Oraison et bénédiction',
      ]);
    });

    test('invitatory psalm takes antienne_invitatoire and a "Ps " ref', () {
      final invit = tabNamed(result, 'Psaume invitatoire');
      expect(invit.ref, 'Ps 94 (95)');
      expect(invit.subtitle, contains('Venez, adorons le Seigneur'));
      expect(invit.content, endsWith('Gloire au Père, ...</p>'));
    });

    test('scripture reading keeps a short tab title and a quoted content title',
        () {
      final lecture = tabNamed(result, 'Lecture');
      expect(lecture.title, 'Lecture');
      expect(lecture.displayTitle, "« La foi d'abraham »");
      expect(lecture.ref, 'He 11, 1-16');
      expect(lecture.content, contains('<p class="repons">Répons</p>'));
    });

    test('patristic reading pulls its title and répons from sibling keys', () {
      final patristique = tabNamed(result, 'Lecture patristique');
      expect(
          patristique.displayTitle, '« Homélie de saint Augustin sur la foi »');
      expect(patristique.content, contains('Ce que nous croyons'));
      expect(patristique.content, contains('Que ta grâce nous accompagne'));
    });
  });

  group('OfficeParser — degraded input', () {
    test('erreur_technique becomes a single Erreur tab', () {
      final result = OfficeParser.parse(loadFixture('office_error.json'));
      expect(result.tabTitles, ['Erreur']);
      expect(
        result.tabData.single.content,
        "Nous n'avons pas trouvé cette lecture.",
      );
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
