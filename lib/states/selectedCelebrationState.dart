import 'package:flutter/foundation.dart';

/// Global state that remembers the last celebration and common chosen by the
/// user so that other offices can default to the same selection when possible.
class SelectedCelebrationState extends ChangeNotifier {
  String? celebrationKey;
  String? common;
  bool commonSet =
      false; // true once the user (or an office) has explicitly set a common value (including null = "no common")

  final Map<String, int> _precedenceOverrides = {};

  int? getPrecedenceOverride(String key) => _precedenceOverrides[key];

  void setPrecedenceOverride(String key, int precedence) {
    _precedenceOverrides.clear();
    _precedenceOverrides[key] = precedence;
    notifyListeners();
  }

  void removePrecedenceOverride(String key) {
    _precedenceOverrides.remove(key);
    notifyListeners();
  }

  void setCelebration(String? key) {
    celebrationKey = key;
    notifyListeners();
  }

  void setCommon(String? value) {
    common = value;
    commonSet = true;
    notifyListeners();
  }
}
