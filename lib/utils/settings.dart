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
  String region = prefs.getString(keyPrefRegion) ?? 'romain';
  return (region == '' ? '0' : region);
}
