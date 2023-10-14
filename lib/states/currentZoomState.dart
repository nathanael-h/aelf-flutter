import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentZoom extends ChangeNotifier {
  double? value;

  void updateZoom(double newZoom) {
    value = newZoom.clamp(60.0, 300.0);
    _saveToPrefs(value ?? 100);
    notifyListeners();
  }

  final String keyCurrentZoom = 'keyCurrentZoom';
  SharedPreferences? _pref;

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
    value = _pref!.getDouble(keyCurrentZoom)?.clamp(60.0, 300.0) ?? 100;
    notifyListeners();
  }

  _saveToPrefs(double value) async {
    await _initPrefs();
    _pref!.setDouble(keyCurrentZoom, value);
  }
}
