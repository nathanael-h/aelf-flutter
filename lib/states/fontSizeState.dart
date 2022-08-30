import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentZoom extends ChangeNotifier {
  double value;

  void updateZoom(double newZoom) {
    value = newZoom.clamp(100.0, 700.0);
    _saveToPrefs(newZoom);
    notifyListeners();
  }

  final String keyFontSize = 'keyFontSize';
  SharedPreferences _pref;

  CurrentZoom() {
    value = 100;
    _loadFromPrefs();
  }

  // _initPref() is to iniliaze  the _pref variable
  _initPrefs() async {
    if (_pref == null) _pref = await SharedPreferences.getInstance();
  }

  _loadFromPrefs() async {
    await _initPrefs();
    value = _pref.getDouble(keyFontSize) ?? 100;
    notifyListeners();
  }

  _saveToPrefs(double value) async {
    await _initPrefs();
    _pref.setDouble(keyFontSize, value);
  }
}
