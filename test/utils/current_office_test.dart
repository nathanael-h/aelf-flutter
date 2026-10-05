import 'package:aelf_flutter/data/app_sections.dart';
import 'package:aelf_flutter/utils/current_office.dart';
import 'package:aelf_flutter/widgets/left_menu.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app opens on whichever office suits the time of day. Two things have to
/// hold for every hour of every day:
///
/// * the chosen section exists in `appSections`, or
///   `AelfHomePageState._computeCurrentOffice` bails out on a -1 index and the
///   user lands on whatever was showing;
/// * the chosen section is one `LeftMenu` actually lists for the current state
///   of `feature_offline_liturgy`, or the app opens on a page the user cannot
///   navigate back to.
void main() {
  // A Sunday and a Tuesday in the same week, so the weekday rule is exercised
  // against a real calendar rather than a synthesised weekday field.
  final sunday = DateTime(2025, 6, 8);
  final tuesday = DateTime(2025, 6, 10);

  DateTime at(DateTime day, int hour) =>
      DateTime(day.year, day.month, day.day, hour);

  group('the weekday timetable', () {
    test('walks the hours of the office in order', () {
      const expected = <int, String>{
        0: 'complies',
        1: 'complies',
        2: 'complies',
        3: 'lectures',
        4: 'lectures',
        5: 'lectures',
        6: 'lectures',
        7: 'laudes',
        8: 'laudes',
        9: 'tierce',
        10: 'tierce',
        11: 'tierce',
        12: 'sexte',
        13: 'sexte',
        14: 'sexte',
        15: 'none',
        16: 'none',
        17: 'none',
        18: 'vepres',
        19: 'vepres',
        20: 'vepres',
        21: 'complies',
        22: 'complies',
        23: 'complies',
      };

      for (var hour = 0; hour < 24; hour++) {
        expect(onlineOfficeAt(at(tuesday, hour)), expected[hour],
            reason: '${hour}h on a Tuesday');
      }
    });

    test('never opens on Mass on a weekday', () {
      for (var hour = 0; hour < 24; hour++) {
        expect(onlineOfficeAt(at(tuesday, hour)), isNot('messes'),
            reason: '${hour}h');
      }
    });
  });

  group('the Sunday timetable', () {
    test('opens on Mass between 8h and 12h', () {
      for (var hour = 8; hour < 12; hour++) {
        expect(onlineOfficeAt(at(sunday, hour)), 'messes', reason: '${hour}h');
      }
    });

    test('Sunday 7h-8h still opens on Lauds, not Mass', () {
      expect(onlineOfficeAt(at(sunday, 7)), 'laudes');
    });

    test('keeps the night and early-morning offices', () {
      expect(onlineOfficeAt(at(sunday, 0)), 'complies');
      expect(onlineOfficeAt(at(sunday, 2)), 'complies');
      expect(onlineOfficeAt(at(sunday, 3)), 'lectures');
      expect(onlineOfficeAt(at(sunday, 6)), 'lectures');
    });

    test('returns to the office of the day after Mass', () {
      expect(onlineOfficeAt(at(sunday, 12)), 'sexte');
      expect(onlineOfficeAt(at(sunday, 15)), 'none');
      expect(onlineOfficeAt(at(sunday, 18)), 'vepres');
      expect(onlineOfficeAt(at(sunday, 21)), 'complies');
    });

    test('Sunday differs from a weekday only in the 8h-12h window', () {
      for (var hour = 0; hour < 24; hour++) {
        final sundayOffice = onlineOfficeAt(at(sunday, hour));
        final weekdayOffice = onlineOfficeAt(at(tuesday, hour));
        if (hour >= 8 && hour < 12) {
          expect(sundayOffice, 'messes', reason: '${hour}h');
          expect(weekdayOffice, isNot('messes'), reason: '${hour}h');
        } else {
          expect(sundayOffice, weekdayOffice, reason: '${hour}h');
        }
      }
    });

    test('only Sunday gets Mass', () {
      for (var day = 8; day <= 14; day++) {
        final date = DateTime(2025, 6, day, 10);
        final isSunday = date.weekday == DateTime.sunday;
        expect(onlineOfficeAt(date) == 'messes', isSunday,
            reason: 'June $day 2025 (weekday ${date.weekday})');
      }
    });
  });

  group('minutes and seconds do not matter', () {
    test('only the hour is used', () {
      expect(onlineOfficeAt(DateTime(2025, 6, 10, 6, 59, 59)), 'lectures');
      expect(onlineOfficeAt(DateTime(2025, 6, 10, 7, 0, 0)), 'laudes');
      expect(onlineOfficeAt(DateTime(2025, 6, 10, 8, 59, 59)), 'laudes');
      expect(onlineOfficeAt(DateTime(2025, 6, 10, 9, 0, 0)), 'tierce');
    });
  });

  group('with the offline liturgy enabled', () {
    test('each office is swapped for its offline twin', () {
      const twins = {
        'complies': 'offline_complines',
        'lectures': 'offline_readings',
        'laudes': 'offline_morning',
        'tierce': 'offline_tierce',
        'sexte': 'offline_sexte',
        'none': 'offline_none',
        'vepres': 'offline_vespers',
      };

      for (var hour = 0; hour < 24; hour++) {
        final online = onlineOfficeAt(at(tuesday, hour));
        expect(currentOfficeSection(at(tuesday, hour), offlineEnabled: true),
            twins[online],
            reason: '${hour}h -> $online');
      }
    });

    test('Mass is swapped for its offline twin like every other office', () {
      for (var hour = 8; hour < 12; hour++) {
        expect(currentOfficeSection(at(sunday, hour), offlineEnabled: true),
            'offline_mass',
            reason: '${hour}h on a Sunday');
      }
      expect(kOnlineToOfflineOffice['messes'], 'offline_mass');
    });

    test('with the flag off nothing is swapped', () {
      for (final day in [sunday, tuesday]) {
        for (var hour = 0; hour < 24; hour++) {
          expect(currentOfficeSection(at(day, hour), offlineEnabled: false),
              onlineOfficeAt(at(day, hour)),
              reason: '${hour}h');
        }
      }
    });
  });

  group('the date of the office', () {
    test('Compline between midnight and 3h is the previous day\'s', () {
      for (var hour = 0; hour < 3; hour++) {
        expect(
            officeDateAt(DateTime(2025, 6, 10, hour, 30)), DateTime(2025, 6, 9),
            reason: '${hour}h30');
      }
    });

    test('from 3h on, it is the day itself', () {
      for (var hour = 3; hour < 24; hour++) {
        expect(officeDateAt(DateTime(2025, 6, 10, hour, 30)),
            DateTime(2025, 6, 10),
            reason: '${hour}h30');
      }
    });

    test('the previous day crosses month and year boundaries', () {
      expect(officeDateAt(DateTime(2025, 3, 1, 1)), DateTime(2025, 2, 28));
      expect(officeDateAt(DateTime(2024, 3, 1, 1)), DateTime(2024, 2, 29));
      expect(officeDateAt(DateTime(2026, 1, 1, 1)), DateTime(2025, 12, 31));
    });

    test('Compline in the night from Sunday to Monday is Sunday\'s', () {
      // Monday 1h: the Compline of Sunday, not Monday's.
      expect(officeDateAt(DateTime(2025, 6, 9, 1)), DateTime(2025, 6, 8));
    });
  });

  group('reopening on the current office', () {
    final leftAt = DateTime(2025, 6, 10, 8, 15);

    test('not before 2 hours away', () {
      expect(
          shouldReopenOnCurrentOffice(
              leftAt, leftAt.add(const Duration(minutes: 119))),
          isFalse);
    });

    test('from 2 hours away on', () {
      expect(
          shouldReopenOnCurrentOffice(
              leftAt, leftAt.add(const Duration(hours: 2))),
          isTrue);
      expect(
          shouldReopenOnCurrentOffice(
              leftAt, leftAt.add(const Duration(days: 3))),
          isTrue);
    });
  });

  group('coherence with the rest of the app', () {
    final knownSections = appSections.map((s) => s.name).toSet();

    test('every hour of every day picks a section that exists', () {
      for (final offline in [false, true]) {
        for (var day = 8; day <= 14; day++) {
          for (var hour = 0; hour < 24; hour++) {
            final section = currentOfficeSection(DateTime(2025, 6, day, hour),
                offlineEnabled: offline);
            expect(knownSections, contains(section),
                reason: 'June $day ${hour}h (offline=$offline) chose '
                    '"$section", which appSections does not define — '
                    '_computeCurrentOffice would bail out on index -1');
          }
        }
      }
    });

    test('every chosen section is listed in the drawer for that flag state',
        () {
      // Opening on a section LeftMenu hides would strand the user.
      for (final offline in [false, true]) {
        for (var day = 8; day <= 14; day++) {
          for (var hour = 0; hour < 24; hour++) {
            final section = currentOfficeSection(DateTime(2025, 6, day, hour),
                offlineEnabled: offline);
            expect(LeftMenu.showSection(section, offline), isTrue,
                reason: 'June $day ${hour}h (offline=$offline) chose '
                    '"$section", which the drawer does not list');
          }
        }
      }
    });

    test('the offline twins named here match the drawer\'s replacements', () {
      kOnlineToOfflineOffice.forEach((online, offline) {
        expect(knownSections, contains(online));
        expect(knownSections, contains(offline));
        expect(LeftMenu.showSection(online, false), isTrue, reason: online);
        expect(LeftMenu.showSection(offline, true), isTrue, reason: offline);
        expect(LeftMenu.showSection(online, true), isFalse,
            reason: '$online should step aside for $offline');
      });
    });
  });
}
