import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

final String keyLastVersionInstalled = 'keyLastVersionInstalled';
final String keyPrefRegion = 'keyPrefRegion';
final String keyOfflineRegion = 'keyOfflineRegion';
final String keyFeatureOfflineLiturgy = 'feature_offline_liturgy';
final String keyImprecatoryVerses = 'use_imprecatory_verses';
final String keySerifFont = 'use_serif_font';
final String keyLastBibleBook = 'keyLastBibleBook';
final String keyLastBibleChapter = 'keyLastBibleChapter';
final String keyOfflineGeolocation = 'feature_offline_geolocation';

Future<void> setRegion(String newRegion) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(keyPrefRegion, newRegion);
}

Future<String> getRegion() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? region = prefs.getString(keyPrefRegion);
  if (region != null && region.isNotEmpty) {
    return region;
  }
  final detected = _getDefaultRegionFromLocale();
  await prefs.setString(keyPrefRegion, detected);
  return detected;
}

Future<String> getOfflineRegion() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(keyOfflineRegion) ?? 'romain';
}

Future<void> setOfflineRegion(String region) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(keyOfflineRegion, region);
}

// Feature flags
Future<bool> getFeatureOfflineLiturgy() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(keyFeatureOfflineLiturgy) ?? false;
}

Future<void> setFeatureOfflineLiturgy(bool enabled) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(keyFeatureOfflineLiturgy, enabled);
}

Future<bool> getImprecatoryVerses() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(keyImprecatoryVerses) ?? false;
}

Future<void> setImprecatoryVerses(bool bool) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(keyImprecatoryVerses, bool);
}

Future<bool> getOfflineGeolocation() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(keyOfflineGeolocation) ?? false;
}

Future<void> setOfflineGeolocation(bool enabled) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(keyOfflineGeolocation, enabled);
}

Future<bool> getSerifFont() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(keySerifFont) ?? false;
}

Future<void> setSerifFont(bool enabled) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(keySerifFont, enabled);
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
