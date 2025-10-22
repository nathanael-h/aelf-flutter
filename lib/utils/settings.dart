import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

final String keyVisitedFlag = 'keyVisitedFlag';
final String keyLastVersionInstalled = 'keyLastVersionInstalled';
final String keyPrefRegion = 'keyPrefRegion';
final String keySelectedLocation = 'keySelectedLocation';
final String keyCurrentZoom = 'keyCurrentZoom';

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

// Legacy region functions (for backward compatibility)
void setRegion(String newRegion) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(keyPrefRegion, newRegion);
  // Also update the new location system for consistency
  prefs.setString(keySelectedLocation, newRegion);
}

Future<String> getRegion() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Try new location system first, fall back to old region system
  String location = prefs.getString(keySelectedLocation) ??
      prefs.getString(keyPrefRegion) ??
      'romain';
  return (location == '' ? 'romain' : location);
}

// New location functions (use these for new code)
Future<void> setSelectedLocation(String locationId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(keySelectedLocation, locationId);
  // Also update legacy region for backward compatibility
  await prefs.setString(keyPrefRegion, locationId);
}

Future<String> getSelectedLocation() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String location = prefs.getString(keySelectedLocation) ??
      prefs.getString(keyPrefRegion) ??
      'romain';
  return location;
}
