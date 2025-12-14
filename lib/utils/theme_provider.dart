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
  useMaterial3: false,
  primaryColor: Color(0xFFBF2329),
  scaffoldBackgroundColor: Color(0xFFEFE3CE),
  tabBarTheme: TabBarThemeData(
      labelColor: Color(0xFFEFE3CE),
      //unselectedLabelColor: Color.fromRGBO(191, 35, 41, 0.4), //0.4-->66
      unselectedLabelColor: Color(0xFFEFE3CE)),
  appBarTheme: AppBarTheme(backgroundColor: Color(0xFF1E2024)),
  textTheme: TextTheme(
      bodySmall: TextStyle(color: Color(0xFF5D451A)),
      bodyMedium: TextStyle(color: Color(0xFF5D451A)),
      bodyLarge:
          TextStyle(color: Colors.black), // Used in drawer with white backgroud
      titleSmall: TextStyle(color: Color(0xFF5D451A)),
      titleMedium: TextStyle(color: Color(0xFF5D451A)),
      titleLarge: TextStyle(
          color: Colors
              .white), // Historically used for drawer and popup backgrounds
      displayLarge: TextStyle(color: Color(0xFF5D451A)),
      displayMedium: TextStyle(color: Color(0xFF5D451A)),
      displaySmall: TextStyle(color: Color(0xFF5D451A)),
      headlineLarge: TextStyle(color: Color(0xFF5D451A)),
      headlineMedium: TextStyle(color: Color(0xFF5D451A)),
      headlineSmall: TextStyle(color: Color(0xFF5D451A)),
      labelLarge: TextStyle(color: Color(0xFF5D451A)),
      labelMedium: TextStyle(color: Color(0xFF5D451A)),
      labelSmall: TextStyle(color: Color(0xFF5D451A))),
  dividerColor: Colors.grey,
  sliderTheme: SliderThemeData(
    activeTrackColor: Color(0xFFBF2328),
    inactiveTrackColor: Color(0xFFBF2328).withAlpha(85),
    thumbColor: Color(0xFFBF2328),
    overlayColor: Color(0x29BF2328),
    valueIndicatorColor: Color(0xFFBF2328),
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Color(0xFFBF2329),
    selectionColor: Color.fromARGB(80, 191, 35, 41),
    selectionHandleColor: Color(0xFFBF2329),
  ),
  colorScheme: ColorScheme.fromSwatch(brightness: Brightness.light).copyWith(
      primary: Color(0xFFBF2328),
      secondary: Color(0xFFBF2328),
      // keep the same surface color that was previously stored in textTheme.titleLarge.color
      surface: Colors.white,
      onSurface: Colors.black),
  drawerTheme: DrawerThemeData(backgroundColor: Colors.white),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor:
          WidgetStateProperty.all(Color.fromARGB(255, 240, 229, 210)),
      foregroundColor: WidgetStateProperty.all(Color(0xFF5D451A)),
      textStyle:
          WidgetStateProperty.all(TextStyle(fontStyle: FontStyle.italic)),
    ),
  ),
  //platform: TargetPlatform.iOS,
);

ThemeData dark = ThemeData(
  useMaterial3: false,
  primaryColor: Color(0xFF1E2024),
  scaffoldBackgroundColor: Color(0xFF13171F),
  tabBarTheme: TabBarThemeData(
    labelColor: Color(0xFFf9787e),
    unselectedLabelColor: Color(0xB3f9787e),
  ),
  appBarTheme: AppBarTheme(backgroundColor: Color(0xFF1E2024)),
  textTheme: TextTheme(
      bodySmall: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Color(0xDDEFE9DE)),
      bodyLarge: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(
          color: Color(0xFF1E2024)) // Historically used for drawer background
      ),
  dividerColor: Colors.grey,
  sliderTheme: SliderThemeData(
    activeTrackColor: Color(0xFFf9787e),
    inactiveTrackColor: Color(0xFFf9787e).withAlpha(85),
    thumbColor: Color(0xFFf9787e),
    overlayColor: Color(0x29f9787e),
    valueIndicatorColor: Color(0xFFf9787e),
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Color.fromARGB(255, 249, 120, 126),
    selectionColor: Color.fromARGB(80, 249, 120, 126),
    selectionHandleColor: Color(0xFFf9787e),
  ),
  colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
    primary: Color(0xFF1E2024),
    secondary: Color(0xFFf9787e),
    // preserve previous surface used in UI
    surface: Color(0xFF1E2024),
    onSurface: Colors.white70,
  ),
  drawerTheme: DrawerThemeData(backgroundColor: Color(0xFF1E2024)),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 38, 41, 49)),
      foregroundColor: WidgetStateProperty.all(Color(0xDDEFE9DE)),
      textStyle:
          WidgetStateProperty.all(TextStyle(fontStyle: FontStyle.italic)),
    ),
  ),
  cupertinoOverrideTheme: CupertinoThemeData(
    // https://api.flutter.dev/flutter/material/TextSelectionThemeData/selectionHandleColor.html
    // Needed to define selection handle color on iOS, as per this doc page.
    primaryColor: Color(0xFFf9787e),
  ),
  //platform: TargetPlatform.iOS,
  datePickerTheme: DatePickerThemeData(
    cancelButtonStyle: TextButton.styleFrom(
      foregroundColor: Color(0xDDEFE9DE),
    ),
    confirmButtonStyle: TextButton.styleFrom(
      foregroundColor: Color(0xDDEFE9DE),
    ),
  ),
);

class ThemeNotifier extends ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _pref;
  bool _darkTheme = true;

  bool get darkTheme => _darkTheme;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  void toggleTheme() {
    _darkTheme = !_darkTheme;
    _saveToPrefs();
    notifyListeners();
  }

  // _initPref() is to iniliaze  the _pref variable
  Future<void> _initPrefs() async {
    _pref ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    _darkTheme = _pref!.getBool(key) ?? true;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    await _initPrefs();
    _pref!.setBool(key, _darkTheme);
  }
}
