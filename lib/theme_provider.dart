import 'package:aelf_flutter/creatMaterialColor.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Source : https://codesource.io/building-theme-switcher-using-provider-and-shared-preferences/

ThemeData light = ThemeData(
  // This is the theme of your application.
  //
  // Try running your application with "flutter run". You'll see the
  // application has a red toolbar. Then, without quitting the app, try
  // changing the primarySwatch below to Colors.green and then invoke
  // "hot reload" (press "r" in the console where you ran "flutter run",
  // or simply save your changes to "hot reload" in a Flutter IDE).
  primaryColor: Color(0xFFBF2329),
  primarySwatch: createMaterialColor(Color(0xFFBF2329)),
  accentColor: Color(0xFFBF2328), //0.7 --> B3
  backgroundColor: Color(0xFFEFE3CE),
  scaffoldBackgroundColor: Color(0xFFEFE3CE),
  tabBarTheme: TabBarTheme(
      labelColor: Color(0xFFEFE3CE),
      //unselectedLabelColor: Color.fromRGBO(191, 35, 41, 0.4), //0.4-->66
      unselectedLabelColor: Color(0xFFEFE3CE)),
  appBarTheme: AppBarTheme(color: Color(0xFF1E2024)),
  textTheme: TextTheme(
    bodyText1: TextStyle(color: Colors.black),
    bodyText2: TextStyle(color: Color(0xFF5D451A)),
    headline6: TextStyle(color: Colors.white) // Used for drawer background
  ),
  dividerColor: Colors.grey,
);

ThemeData dark = ThemeData(
  primaryColor: Color(0xFF1E2024),
  primarySwatch: createMaterialColor(Color(0xFFD8474E)),
  accentColor: Color(0xFFf9787e),
  backgroundColor: Color(0xFF13171F),
  scaffoldBackgroundColor: Color(0xFF13171F),
  tabBarTheme: TabBarTheme(
    labelColor: Color(0xFFf9787e),
    unselectedLabelColor: Color(0xB3f9787e),
  ),
  appBarTheme: AppBarTheme(color: Color(0xFF1E2024)),
  textTheme: TextTheme(
    bodyText1: TextStyle(color: Colors.white70),
    bodyText2: TextStyle(color: Color(0xDDEFE9DE)),
    headline6: TextStyle(color: Color(0xFF1E2024)) // Used for drawer background
  ),
  dividerColor: Colors.grey,
);

class ThemeNotifier extends ChangeNotifier {
  final String key = "theme";
  SharedPreferences _pref;
  bool _darkTheme;

  bool get darkTheme => _darkTheme;

  ThemeNotifier() {
    _darkTheme = true;
    _loadFromPrefs();
  }

  toggleTheme() async{
    _darkTheme = !_darkTheme;
    await _saveToPrefs();
    notifyListeners();
  }

 // _initPref() is to iniliaze  the _pref variable
  _initPrefs() async {
    if(_pref == null)
      _pref  = await SharedPreferences.getInstance();
  }
  _loadFromPrefs() async {
      await _initPrefs();
      _darkTheme = _pref.getBool(key) ?? true;
      notifyListeners();
  }
  _saveToPrefs() async {
    await _initPrefs();
    _pref.setBool(key, _darkTheme);
  }
}