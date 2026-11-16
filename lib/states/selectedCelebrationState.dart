import 'package:flutter/foundation.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

/// The identity [SelectedCelebrationState.celebrationKey] stores and is
/// matched against — NOT a map key from any one office's own celebration
/// list. Those map keys differ in format between the Office of Readings/
/// Morning/Vespers/MiddleOfDay (`celebrationTitle ?? celebrationCode`, see
/// `buildDetectionMap`) and the Mass (`"$celebrationTitle - $massName"`, see
/// `massDetection`) — comparing raw keys across screens silently fails to
/// match and drops the user's selection. This identity is common to both.
String celebrationIdentity(CelebrationContext c) =>
    c.celebrationTitle ?? c.celebrationCode;

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
