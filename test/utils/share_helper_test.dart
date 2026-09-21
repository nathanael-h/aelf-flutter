import 'package:aelf_flutter/data/app_sections.dart';
import 'package:aelf_flutter/utils/share_helper.dart';
import 'package:flutter_test/flutter_test.dart';

/// The share button is only shown when `ShareHelper.slugFor` returns a slug
/// (see `AelfHomePageState.build`), so this map decides share-button
/// visibility for every section — online and offline alike.
void main() {
  group('ShareHelper.slugFor — online offices', () {
    test('every online office and mass maps to its aelf.org slug', () {
      expect(ShareHelper.slugFor('messes'), 'messe');
      expect(ShareHelper.slugFor('lectures'), 'lectures');
      expect(ShareHelper.slugFor('laudes'), 'laudes');
      expect(ShareHelper.slugFor('tierce'), 'tierce');
      expect(ShareHelper.slugFor('sexte'), 'sexte');
      expect(ShareHelper.slugFor('none'), 'none');
      expect(ShareHelper.slugFor('vepres'), 'vepres');
      expect(ShareHelper.slugFor('complies'), 'complies');
    });
  });

  group('ShareHelper.slugFor — offline twins', () {
    test('each offline office shares the same aelf.org page as its online twin',
        () {
      const twins = {
        'offline_mass': 'messes',
        'offline_readings': 'lectures',
        'offline_morning': 'laudes',
        'offline_tierce': 'tierce',
        'offline_sexte': 'sexte',
        'offline_none': 'none',
        'offline_vespers': 'vepres',
        'offline_complines': 'complies',
      };
      twins.forEach((offline, online) {
        expect(ShareHelper.slugFor(offline), ShareHelper.slugFor(online),
            reason: '$offline should share the same page as $online');
      });
    });
  });

  group('ShareHelper.slugFor — non-shareable sections', () {
    test('bible, informations and the offline calendar are not shareable', () {
      expect(ShareHelper.slugFor('bible'), isNull);
      expect(ShareHelper.slugFor('informations'), isNull);
      expect(ShareHelper.slugFor('offline_calendar'), isNull);
    });

    test('an unknown liturgy type is not shareable', () {
      expect(ShareHelper.slugFor('type_inconnu'), isNull);
    });
  });

  test('every app section is either shareable or deliberately excluded', () {
    const notShareable = {
      'bible',
      'informations',
      'offline_calendar',
    };
    for (final section in appSections) {
      final slug = ShareHelper.slugFor(section.name);
      if (notShareable.contains(section.name)) {
        expect(slug, isNull, reason: '${section.name} must not be shareable');
      } else {
        expect(slug, isNotNull,
            reason: '${section.name} has no share slug — either add one to '
                'ShareHelper._slugMap or list it as deliberately excluded');
      }
    }
  });
}
