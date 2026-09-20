import 'package:aelf_flutter/parsers/liturgy_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fixtures.dart';

/// `LiturgyParserService` is the single entry point every online liturgy
/// payload goes through (`LiturgyFormatter` calls it on `LiturgyState.aelfJson`).
/// Its routing decides which parser runs, so it is the narrowest place to catch
/// a regression in the online path.
void main() {
  group('LiturgyParserService routing', () {
    test('null (not yet downloaded) yields the loading tab', () {
      final result = LiturgyParserService.parse(null);
      expect(result.tabTitles, ['Chargement']);
      expect(result.tabData.single.content, isEmpty);
      expect(result.isEmpty, isFalse);
      expect(result.length, 1);
    });

    test('a root-level erreur_technique short-circuits to an error tab', () {
      final result = LiturgyParserService.parse(
          {'erreur_technique': 'La connexion au serveur a échoué.'});
      expect(result.tabTitles, ['Erreur']);
      expect(
          result.tabData.single.content, 'La connexion au serveur a échoué.');
    });

    test('a "messes" payload routes to the Mass parser', () {
      final result =
          LiturgyParserService.parse(loadFixture('mass_single.json'));
      expect(result.tabTitles, ['Première Lecture', 'Psaume', 'Évangile']);
    });

    test('an "informations" payload routes to the informations parser', () {
      final result =
          LiturgyParserService.parse(loadFixture('informations.json'));
      expect(result.tabTitles, ['Informations']);
    });

    test('every office payload routes to the office parser', () {
      for (final fixture in [
        'office_laudes.json',
        'office_lectures.json',
        'office_vepres.json',
        'office_complies.json',
      ]) {
        final result = LiturgyParserService.parse(loadFixture(fixture));
        expect(result.tabTitles.first, 'Introduction', reason: fixture);
        expect(result.tabTitles, contains('Oraison et bénédiction'),
            reason: fixture);
      }
    });

    test('"messes" wins over "informations" when both are present', () {
      // The raw api.aelf.org response carries both; LiturgyState strips it down
      // to one key, but the routing order is what makes that safe either way.
      final payload = <String, dynamic>{
        ...loadFixture('informations.json'),
        ...loadFixture('mass_single.json'),
      };
      final result = LiturgyParserService.parse(payload);
      expect(result.tabTitles, isNot(contains('Informations')));
      expect(result.tabTitles, contains('Évangile'));
    });

    test('an office error payload surfaces the server message', () {
      final result =
          LiturgyParserService.parse(loadFixture('office_error.json'));
      expect(result.tabTitles, ['Erreur']);
      expect(result.tabData.single.content,
          "Nous n'avons pas trouvé cette lecture.");
    });
  });
}
