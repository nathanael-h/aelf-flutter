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
  // Mass has no offline implementation: it stays on the online API whatever
  // the state of the feature flag.
};

/// The online app section for the office matching [now].
///
/// Sunday is special: between 8h and 15h it opens on Mass instead of the
/// little hours, since that is what someone is most likely looking for. Note
/// the Lauds window (4h-8h) is checked first, so early Sunday morning still
/// opens on Lauds rather than Mass.
String onlineOfficeAt(DateTime now) {
  final hour = now.hour;
  final isSunday = now.weekday == DateTime.sunday;

  if (hour < 3) return 'complies';
  if (hour < 4) return 'lectures';
  if (hour < 8) return 'laudes';
  if (hour < 15 && isSunday) return 'messes';
  if (hour < 10) return 'tierce';
  if (hour < 13) return 'sexte';
  if (hour < 16) return 'none';
  if (hour < 21) return 'vepres';
  return 'complies';
}

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
