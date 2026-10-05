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

  /// Updates the zoom level and refreshes all listening widgets.
  ///
  /// With [persist] set to false the value is not written to storage, which
  /// lets continuous interactions (e.g. dragging the settings slider) update
  /// the UI without a platform-channel write on every frame; call [persist]
  /// once the interaction is over.
  void updateZoom(double newZoom, {bool persist = true}) {
    final clampedZoom = newZoom.clamp(minZoom, maxZoom);
    if (_value != clampedZoom) {
      _value = clampedZoom;
      notifyListeners();
    }
    if (persist) this.persist();
  }

  /// Writes the current zoom level to storage.
  void persist() {
    _prefs?.setDouble(keyCurrentZoom, _value);
  }
}
