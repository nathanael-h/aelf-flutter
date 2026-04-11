import 'package:flutter/foundation.dart';

/// Global state that remembers the last celebration and common chosen by the
/// user so that other offices can default to the same selection when possible.
class SelectedCelebrationState extends ChangeNotifier {
  String? celebrationKey;
  String? common;
  bool commonSet =
      false; // true once the user (or an office) has explicitly set a common value (including null = "no common")

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
