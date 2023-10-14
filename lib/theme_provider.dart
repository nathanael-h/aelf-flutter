import 'package:flutter/cupertino.dart';
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
  scaffoldBackgroundColor: Color(0xFFEFE3CE),
  tabBarTheme: TabBarTheme(
      labelColor: Color(0xFFEFE3CE),
      //unselectedLabelColor: Color.fromRGBO(191, 35, 41, 0.4), //0.4-->66
      unselectedLabelColor: Color(0xFFEFE3CE)),
  appBarTheme: AppBarTheme(color: Color(0xFF1E2024)),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Color(0xFF5D451A)),
    titleLarge: TextStyle(color: Colors.white) // Used for drawer and popUpMenu backgrounds
  ),
  dividerColor: Colors.grey,
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Color(0xFFBF2329),
    selectionColor: Color.fromARGB(80, 191, 35, 41),
    selectionHandleColor: Color(0xFFBF2329),
  ), colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: Color(0xFFBF2328),
    secondary: Color(0xFFBF2328)
    ),
  //platform: TargetPlatform.iOS,
);

ThemeData dark = ThemeData(
  primaryColor: Color(0xFF1E2024),
  scaffoldBackgroundColor: Color(0xFF13171F),
  tabBarTheme: TabBarTheme(
    labelColor: Color(0xFFf9787e),
    unselectedLabelColor: Color(0xB3f9787e),
  ),
  appBarTheme: AppBarTheme(color: Color(0xFF1E2024)),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white70),
    bodyMedium: TextStyle(color: Color(0xDDEFE9DE)),
    titleLarge: TextStyle(color: Color(0xFF1E2024)) // Used for drawer background
  ),
  dividerColor: Colors.grey,
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Color.fromARGB(255, 249, 120, 126),
    selectionColor: Color.fromARGB(80, 249, 120, 126),
    selectionHandleColor: Color(0xFFf9787e),
  ), colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: Color(0xFF1E2024),
    secondary: Color(0xFFf9787e),
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      // https://api.flutter.dev/flutter/material/TextSelectionThemeData/selectionHandleColor.html
      // Needed to define selection handle color on iOS, as per this doc page.
      primaryColor:Color(0xFFf9787e),
    ),
    //platform: TargetPlatform.iOS,
);

class ThemeNotifier extends ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _pref;
  bool? _darkTheme;

  bool? get darkTheme => _darkTheme;

  ThemeNotifier() {
    _darkTheme = true;
    _loadFromPrefs();
  }

  toggleTheme(){
    _darkTheme = !_darkTheme!;
    _saveToPrefs();
    notifyListeners();
  }

 // _initPref() is to iniliaze  the _pref variable
  _initPrefs() async {
    if(_pref == null)
      _pref  = await SharedPreferences.getInstance();
  }
  _loadFromPrefs() async {
      await _initPrefs();
      _darkTheme = _pref!.getBool(key) ?? true;
      notifyListeners();
  }
  _saveToPrefs() async {
    await _initPrefs();
    _pref!.setBool(key, _darkTheme!);
  }
}