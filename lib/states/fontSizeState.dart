import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentZoom extends ChangeNotifier {

double value = 100;

  void updateZoom(double newZoom) {
    value = newZoom;
    notifyListeners();
  }

final String keyFontSize = 'keyFontSize';
  SharedPreferences _pref;
  double _fontSize;

  double get fontSize => _fontSize;

  FontSizeNotifier() {
    _fontSize = 100;
    _loadFromPrefs();
  }

  udateFontSize(double fontSize){
    _fontSize = this.fontSize;
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
      _fontSize = _pref.getDouble(keyFontSize) ?? 100;
      notifyListeners();
  }
  _saveToPrefs() async {
    await _initPrefs();
    _pref.setDouble(keyFontSize, _fontSize);
  }
}