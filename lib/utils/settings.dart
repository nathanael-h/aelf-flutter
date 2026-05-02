import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

final String keyVisitedFlag = 'keyVisitedFlag';
final String keyLastVersionInstalled = 'keyLastVersionInstalled';
final String keyPrefRegion = 'keyPrefRegion';
final String keyCurrentZoom = 'keyCurrentZoom';
final String keyLastBibleBook = 'keyLastBibleBook';
final String keyLastBibleChapter = 'keyLastBibleChapter';

Future<bool> getVisitedFlag() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool flag = prefs.getBool(keyVisitedFlag) ?? false; // if is null return false
  return flag;
}

Future<void> setVisitedFlag() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool(keyVisitedFlag, true);
}

Future<void> togleVisitedFlag() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? flag = prefs.getBool(keyVisitedFlag);
  if (flag == true) {
    prefs.setBool(keyVisitedFlag, false);
  } else {
    prefs.setBool(keyVisitedFlag, false);
  }
}

Future<String?>? getLastVersionInstalled() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? version = prefs.getString(keyLastVersionInstalled);
  return (version == '' ? '0' : version);
}

Future<void> setLastVersionInstalled() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String version = packageInfo.version + packageInfo.buildNumber;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(keyLastVersionInstalled, version);
}

void setRegion(String newRegion) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(keyPrefRegion, newRegion);
}

Future<String> getRegion() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(keyPrefRegion);
  if (stored != null && stored.isNotEmpty) {
    return stored;
  }
  // First launch: auto-detect from device locale and persist
  final detected = _getDefaultRegionFromLocale();
  await prefs.setString(keyPrefRegion, detected);
  return detected;
}

String _getDefaultRegionFromLocale() {
  const countryToRegion = {
    'fr': 'france',
    'be': 'belgique',
    'lu': 'luxembourg',
    'ch': 'suisse',
    'ca': 'canada',
  };
  // Matches the Android native app's region list (case-insensitive)
  const africanCountries = {
    'dz',
    'ao',
    'ac',
    'bj',
    'bw',
    'bf',
    'bi',
    'cm',
    'cv',
    'cf',
    'td',
    'km',
    'cg',
    'cd',
    'ci',
    'dg',
    'dj',
    'eg',
    'gq',
    'er',
    'et',
    'fk',
    'ga',
    'gh',
    'gi',
    'gn',
    'gw',
    'ke',
    'ls',
    'lr',
    'ly',
    'mg',
    'mw',
    'ml',
    'mr',
    'mu',
    'yt',
    'ma',
    'mz',
    'na',
    'ne',
    'ng',
    're',
    'rw',
    'sh',
    'st',
    'sn',
    'sc',
    'sl',
    'so',
    'za',
    'sd',
    'sz',
    'tz',
    'gm',
    'tg',
    'ta',
    'tn',
    'ug',
    'eh',
    'zm',
    'zw',
  };
  final countryCode =
      ui.PlatformDispatcher.instance.locale.countryCode?.toLowerCase() ?? '';
  if (countryToRegion.containsKey(countryCode)) {
    return countryToRegion[countryCode]!;
  }
  if (africanCountries.contains(countryCode)) return 'afrique';
  return 'romain';
}
