import 'package:flutter/foundation.dart';
import 'package:aelf_flutter/utils/settings.dart';

class FeatureFlagsState extends ChangeNotifier {
  bool _offlineLiturgyEnabled = false;

  FeatureFlagsState() {
    _load();
  }

  bool get offlineLiturgyEnabled => _offlineLiturgyEnabled;

  Future<void> _load() async {
    _offlineLiturgyEnabled = await getFeatureOfflineLiturgy();
    notifyListeners();
  }

  Future<void> setOfflineLiturgyEnabled(bool enabled) async {
    _offlineLiturgyEnabled = enabled;
    await setFeatureOfflineLiturgy(enabled);
    notifyListeners();
  }

  Future<void> toggleOfflineLiturgy() async {
    await setOfflineLiturgyEnabled(!offlineLiturgyEnabled);
  }
}
