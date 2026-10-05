/// Choosing which office to open the app on.
///
/// The app opens on whichever hour of the Divine Office is closest to now, the
/// way the native app does, so someone opening it at 7am lands on Lauds rather
/// than on whatever they read last.
///
/// Pure, so the whole clock can be walked in a test rather than waiting for the
/// right hour — see `test/utils/current_office_test.dart`.
library;

/// App section names for the online offices, in the order of the day.
const Map<String, String> kOnlineToOfflineOffice = {
  'lectures': 'offline_readings',
  'laudes': 'offline_morning',
  'tierce': 'offline_tierce',
  'sexte': 'offline_sexte',
  'none': 'offline_none',
  'vepres': 'offline_vespers',
  'complies': 'offline_complines',
  'messes': 'offline_mass',
};

/// The online app section for the office matching [now].
///
///  0h- 3h  Compline (of the previous day, see [officeDateAt])
///  3h- 7h  Office of Readings
///  7h- 9h  Lauds
///  9h-12h  Terce
/// 12h-15h  Sext
/// 15h-18h  None
/// 18h-21h  Vespers
/// 21h-24h  Compline
///
/// Sunday is special: between 8h and 12h it opens on Mass instead, since that
/// is what someone is most likely looking for. Sunday 7h-8h still opens on
/// Lauds.
String onlineOfficeAt(DateTime now) {
  final hour = now.hour;
  final isSunday = now.weekday == DateTime.sunday;

  if (hour < 3) return 'complies';
  if (hour < 7) return 'lectures';
  if (isSunday && hour >= 8 && hour < 12) return 'messes';
  if (hour < 9) return 'laudes';
  if (hour < 12) return 'tierce';
  if (hour < 15) return 'sexte';
  if (hour < 18) return 'none';
  if (hour < 21) return 'vepres';
  return 'complies';
}

/// The liturgical date of the office matching [now]: the previous day between
/// midnight and 3h, when someone opening the app is still ending that day with
/// its Compline; [now]'s own day otherwise. Time of day is dropped.
DateTime officeDateAt(DateTime now) =>
    DateTime(now.year, now.month, now.hour < 3 ? now.day - 1 : now.day);

/// How long the app must have stayed in the background before coming back to
/// it reopens on the office matching the time, instead of where it was left.
const Duration kReopenOnCurrentOfficeAfter = Duration(hours: 2);

/// Whether coming back to the app at [now], after leaving it at [leftAt],
/// should reopen it on the current office (see [kReopenOnCurrentOfficeAfter]).
bool shouldReopenOnCurrentOffice(DateTime leftAt, DateTime now) =>
    now.difference(leftAt) >= kReopenOnCurrentOfficeAfter;

/// The app section to open at [now], honouring the offline liturgy flag.
///
/// With [offlineEnabled] the online offices are swapped for their `offline_`
/// twins, because `LeftMenu` hides the online ones in that mode — opening on a
/// section absent from the menu would strand the user on a page they cannot
/// navigate back to.
String currentOfficeSection(DateTime now, {required bool offlineEnabled}) {
  final section = onlineOfficeAt(now);
  if (!offlineEnabled) return section;
  return kOnlineToOfflineOffice[section] ?? section;
}
