import 'package:shared_preferences/shared_preferences.dart';

final String keyVisitedFlag = 'keyVisitedFlag';

getVisitedFlag() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool flag = prefs.getBool(keyVisitedFlag) ?? false ; // if is null return false
  return flag;
}

setVisitedFlag() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool(keyVisitedFlag, true);
}

togleVisitedFlag() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool flag = prefs.getBool(keyVisitedFlag);
  if (flag == true) { 
    prefs.setBool(keyVisitedFlag, false); 
    } else { 
    prefs.setBool(keyVisitedFlag, false);
    }
}