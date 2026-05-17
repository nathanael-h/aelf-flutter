import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentZoom extends ChangeNotifier {
  static const String keyCurrentZoom = 'keyCurrentZoom';
  static const double minZoom = 60.0;
  static const double maxZoom = 300.0;
  static const double defaultZoom = 100.0;

  double _value = defaultZoom;
  SharedPreferences? _prefs;

  /// Getter to access the zoom value safely
  double get value => _value;

  CurrentZoom() {
    _init();
  }

  /// Combined initialization logic
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load and clamp the value immediately
    final savedZoom = _prefs?.getDouble(keyCurrentZoom);
    if (savedZoom != null) {
      _value = savedZoom.clamp(minZoom, maxZoom);
      notifyListeners();
    }
  }

  /// Updates the zoom level and persists it to storage
  void updateZoom(double newZoom) {
    // Optimization: Don't do anything if the value hasn't changed
    final clampedZoom = newZoom.clamp(minZoom, maxZoom);
    if (_value == clampedZoom) return;

    _value = clampedZoom;

    // Save to disk (we don't strictly need to await here to update the UI)
    _prefs?.setDouble(keyCurrentZoom, _value);

    // Refresh all widgets listening to this state
    notifyListeners();
  }
}
