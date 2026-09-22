import 'package:flutter/foundation.dart';
import 'package:aelf_flutter/utils/settings.dart';

class FeatureFlagsState extends ChangeNotifier {
  bool _offlineLiturgyEnabled;
  bool _offlineGeolocationEnabled = false;

  // Accepts a value preloaded (synchronously, before the first frame) in
  // main() so widgets gating UI on offlineLiturgyEnabled — e.g. the "Mode
  // défilement" toggle — don't flash between hidden and shown while this
  // provider's own async _load() is still in flight.
  FeatureFlagsState({bool? initialOfflineLiturgyEnabled})
      : _offlineLiturgyEnabled = initialOfflineLiturgyEnabled ?? true {
    _load();
  }

  bool get offlineLiturgyEnabled => _offlineLiturgyEnabled;
  bool get offlineGeolocationEnabled => _offlineGeolocationEnabled;

  Future<void> _load() async {
    _offlineLiturgyEnabled = await getFeatureOfflineLiturgy();
    _offlineGeolocationEnabled = await getOfflineGeolocation();
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

  Future<void> setOfflineGeolocationEnabled(bool enabled) async {
    _offlineGeolocationEnabled = enabled;
    await setOfflineGeolocation(enabled);
    notifyListeners();
  }
}
