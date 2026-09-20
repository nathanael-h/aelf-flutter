import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `FeatureFlagsState` is what `LeftMenu` and `SettingsMenu` watch to decide
/// whether the offline liturgy is visible at all. If it ever starts out true,
/// every user is moved onto the in-development offline path.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts disabled before the async load resolves', () {
    final state = FeatureFlagsState();
    expect(state.offlineLiturgyEnabled, isFalse,
        reason: 'the synchronous initial value must never expose the '
            'offline liturgy, even for the first frame');
    expect(state.offlineGeolocationEnabled, isFalse);
  });

  test('stays disabled once the stored (empty) prefs are loaded', () async {
    final state = FeatureFlagsState();
    await pumpEventQueue();
    expect(state.offlineLiturgyEnabled, isFalse);
  });

  test('picks up a previously enabled flag', () async {
    SharedPreferences.setMockInitialValues(
        {keyFeatureOfflineLiturgy: true, keyOfflineGeolocation: true});

    final state = FeatureFlagsState();
    await pumpEventQueue();

    expect(state.offlineLiturgyEnabled, isTrue);
    expect(state.offlineGeolocationEnabled, isTrue);
  });

  test('enabling notifies listeners and persists', () async {
    final state = FeatureFlagsState();
    await pumpEventQueue();

    var notifications = 0;
    state.addListener(() => notifications++);

    await state.setOfflineLiturgyEnabled(true);

    expect(state.offlineLiturgyEnabled, isTrue);
    expect(notifications, 1);
    expect(await getFeatureOfflineLiturgy(), isTrue);
  });

  test('toggling flips the flag both ways and persists each time', () async {
    final state = FeatureFlagsState();
    await pumpEventQueue();

    await state.toggleOfflineLiturgy();
    expect(state.offlineLiturgyEnabled, isTrue);
    expect(await getFeatureOfflineLiturgy(), isTrue);

    await state.toggleOfflineLiturgy();
    expect(state.offlineLiturgyEnabled, isFalse);
    expect(await getFeatureOfflineLiturgy(), isFalse);
  });

  test('geolocation is a separate flag from the liturgy one', () async {
    final state = FeatureFlagsState();
    await pumpEventQueue();

    await state.setOfflineGeolocationEnabled(true);

    expect(state.offlineGeolocationEnabled, isTrue);
    expect(state.offlineLiturgyEnabled, isFalse,
        reason: 'enabling geolocation must not switch on the offline liturgy');
  });
}
