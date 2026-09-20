import 'package:aelf_flutter/data/app_sections.dart';
import 'package:aelf_flutter/widgets/left_menu.dart';
import 'package:flutter_test/flutter_test.dart';

/// The drawer is the only way into a liturgy section, so `LeftMenu.showSection`
/// is what actually hides the in-development offline liturgy from users.
///
/// With the flag OFF nothing offline may appear and every online office must
/// stay reachable; with it ON the online twins step aside. Mass and the Bible
/// are never swapped — Mass has no offline implementation yet.
void main() {
  const onlineOffices = [
    'lectures',
    'laudes',
    'tierce',
    'sexte',
    'none',
    'vepres',
    'complies',
    'informations',
  ];

  const offlineSections = [
    'offline_readings',
    'offline_morning',
    'offline_tierce',
    'offline_sexte',
    'offline_none',
    'offline_vespers',
    'offline_complines',
    'offline_calendar',
  ];

  List<String> visibleSections(bool offlineEnabled) => appSections
      .map((s) => s.name)
      .where((name) => LeftMenu.showSection(name, offlineEnabled))
      .toList();

  group('offline liturgy disabled (the shipped default)', () {
    test('no offline section is listed', () {
      for (final name in offlineSections) {
        expect(LeftMenu.showSection(name, false), isFalse,
            reason: '$name must stay hidden while the flag is off');
      }
    });

    test('every online office stays reachable', () {
      for (final name in onlineOffices) {
        expect(LeftMenu.showSection(name, false), isTrue,
            reason: '$name must remain reachable while the flag is off');
      }
    });

    test('the drawer lists exactly the online sections', () {
      expect(visibleSections(false), [
        'bible',
        'messes',
        'informations',
        'lectures',
        'laudes',
        'tierce',
        'sexte',
        'none',
        'vepres',
        'complies',
      ]);
    });

    test('nothing listed starts with offline_', () {
      expect(
        visibleSections(false).where((n) => n.startsWith('offline_')),
        isEmpty,
      );
    });
  });

  group('offline liturgy enabled (opt-in)', () {
    test('each offline section becomes visible', () {
      for (final name in offlineSections) {
        expect(LeftMenu.showSection(name, true), isTrue, reason: name);
      }
    });

    test('the online offices it replaces step aside', () {
      for (final name in onlineOffices) {
        expect(LeftMenu.showSection(name, true), isFalse,
            reason: '$name is replaced by its offline twin');
      }
    });

    test('the drawer lists exactly the offline sections plus mass and bible',
        () {
      expect(visibleSections(true), [
        'bible',
        'messes',
        'offline_readings',
        'offline_morning',
        'offline_tierce',
        'offline_sexte',
        'offline_none',
        'offline_vespers',
        'offline_complines',
        'offline_calendar',
      ]);
    });
  });

  group('sections that never swap', () {
    test('bible and mass are listed in both modes', () {
      for (final name in ['bible', 'messes']) {
        expect(LeftMenu.showSection(name, false), isTrue, reason: name);
        expect(LeftMenu.showSection(name, true), isTrue,
            reason: '$name has no offline implementation yet');
      }
    });
  });

  test('every online office that is hidden has an offline replacement', () {
    // Each name in _aelfReplacedOffices disappears when the flag is on, so
    // something must take its place or the section becomes unreachable.
    const replacements = {
      'lectures': 'offline_readings',
      'laudes': 'offline_morning',
      'tierce': 'offline_tierce',
      'sexte': 'offline_sexte',
      'none': 'offline_none',
      'vepres': 'offline_vespers',
      'complies': 'offline_complines',
      // 'informations' is folded into the offline drawer header instead.
    };
    final knownSections = appSections.map((s) => s.name).toSet();

    replacements.forEach((online, offline) {
      expect(LeftMenu.showSection(online, true), isFalse, reason: online);
      expect(knownSections, contains(offline));
      expect(LeftMenu.showSection(offline, true), isTrue, reason: offline);
    });
  });
}
