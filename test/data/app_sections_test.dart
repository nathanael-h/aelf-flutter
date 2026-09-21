import 'package:aelf_flutter/data/app_sections.dart';
import 'package:aelf_flutter/widgets/left_menu.dart';
import 'package:flutter_test/flutter_test.dart';

/// `appSections` is indexed directly: `PageState.activeAppSection` and
/// `_pageController.jumpToPage(index)` both use the list position, and
/// `AelfHomePageState._getAppSectionFromName` looks sections up by name.
/// Reordering or renaming an entry silently redirects navigation.
void main() {
  group('appSections integrity', () {
    test('section names are unique', () {
      final names = appSections.map((s) => s.name).toList();
      expect(names.toSet(), hasLength(names.length),
          reason: 'a duplicate name makes indexWhere() ambiguous');
    });

    test('visible section titles are unique for a given flag state', () {
      // An online office and its offline twin deliberately share a title
      // (e.g. both called "Messe") — LeftMenu.showSection guarantees only one
      // of the pair is ever shown at once, so uniqueness only has to hold
      // among the sections actually visible in a given mode.
      for (final offlineEnabled in [false, true]) {
        final titles = appSections
            .where((s) => LeftMenu.showSection(s.name, offlineEnabled))
            .map((s) => s.title)
            .toList();
        expect(titles.toSet(), hasLength(titles.length),
            reason: 'the drawer would show two identical rows '
                '(offlineEnabled=$offlineEnabled)');
      }
    });

    test('names are lowercase, so the name lookup matches', () {
      // _getAppSectionFromName compares against e.name.toLowerCase().
      for (final section in appSections) {
        expect(section.name, section.name.toLowerCase(), reason: section.name);
      }
    });

    test('no section has an empty name or title', () {
      for (final section in appSections) {
        expect(section.name, isNotEmpty);
        expect(section.title, isNotEmpty);
      }
    });
  });

  group('bible section', () {
    test('is first, because PageView index 0 is BibleListsScreen', () {
      expect(appSections.first.name, 'bible');
    });

    test('is the only section with search, and has no date picker', () {
      final bible = appSections.first;
      expect(bible.searchVisible, isTrue);
      expect(bible.datePickerVisible, isFalse);

      for (final section in appSections.skip(1)) {
        expect(section.searchVisible, isFalse, reason: section.name);
      }
    });
  });

  group('liturgy sections', () {
    test('every liturgy section shows the date picker', () {
      // The offline calendar has its own date navigation.
      const noDatePicker = {'bible', 'offline_calendar'};
      for (final section in appSections) {
        expect(section.datePickerVisible, !noDatePicker.contains(section.name),
            reason: section.name);
      }
    });

    test('the online offices consumed from the API are all present', () {
      final names = appSections.map((s) => s.name).toSet();
      expect(
        names,
        containsAll(<String>[
          'messes',
          'informations',
          'lectures',
          'laudes',
          'tierce',
          'sexte',
          'none',
          'vepres',
          'complies',
        ]),
      );
    });

    test('the online offices come before the offline ones', () {
      final firstOffline =
          appSections.indexWhere((s) => s.name.startsWith('offline_'));
      final lastOnline =
          appSections.lastIndexWhere((s) => !s.name.startsWith('offline_'));
      expect(firstOffline, greaterThan(lastOnline),
          reason: 'offline sections are appended, so existing indices — and '
              'therefore saved navigation state — stay stable');
    });

    test(
        'offline sections share their title with their online twin, '
        'apart from the calendar', () {
      final byName = {for (final s in appSections) s.name: s.title};
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
        expect(byName[offline], byName[online], reason: offline);
      });
    });
  });
}
