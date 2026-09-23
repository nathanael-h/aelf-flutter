import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `FeatureFlagsState` is what `LeftMenu` and `SettingsMenu` watch to decide
/// which liturgy the drawer lists. The new (offline) version is the default,
/// and the online API liturgy stays one switch away for users who turn it off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts enabled before the async load resolves', () {
    final state = FeatureFlagsState();
    expect(state.offlineLiturgyEnabled, isTrue,
        reason: 'the synchronous initial value must match the stored default, '
            'so the first frame does not flash the online menu');
    expect(state.offlineGeolocationEnabled, isFalse);
  });

  test('a preloaded value wins before the async load resolves', () {
    final state = FeatureFlagsState(initialOfflineLiturgyEnabled: false);
    expect(state.offlineLiturgyEnabled, isFalse,
        reason: 'main() preloads the stored flag so an opted-out user never '
            'sees the offline menu, even for the first frame');
  });

  test('stays enabled once the stored (empty) prefs are loaded', () async {
    final state = FeatureFlagsState();
    await pumpEventQueue();
    expect(state.offlineLiturgyEnabled, isTrue);
  });

  test('picks up a previously disabled flag', () async {
    SharedPreferences.setMockInitialValues({keyFeatureOfflineLiturgy: false});

    final state = FeatureFlagsState();
    await pumpEventQueue();

    expect(state.offlineLiturgyEnabled, isFalse);
  });

  test('picks up a previously enabled geolocation flag', () async {
    SharedPreferences.setMockInitialValues(
        {keyFeatureOfflineLiturgy: true, keyOfflineGeolocation: true});

    final state = FeatureFlagsState();
    await pumpEventQueue();

    expect(state.offlineLiturgyEnabled, isTrue);
    expect(state.offlineGeolocationEnabled, isTrue);
  });

  test('disabling notifies listeners and persists', () async {
    final state = FeatureFlagsState();
    await pumpEventQueue();

    var notifications = 0;
    state.addListener(() => notifications++);

    await state.setOfflineLiturgyEnabled(false);

    expect(state.offlineLiturgyEnabled, isFalse);
    expect(notifications, 1);
    expect(await getFeatureOfflineLiturgy(), isFalse);
  });

  test('toggling flips the flag both ways and persists each time', () async {
    final state = FeatureFlagsState();
    await pumpEventQueue();

    await state.toggleOfflineLiturgy();
    expect(state.offlineLiturgyEnabled, isFalse);
    expect(await getFeatureOfflineLiturgy(), isFalse);

    await state.toggleOfflineLiturgy();
    expect(state.offlineLiturgyEnabled, isTrue);
    expect(await getFeatureOfflineLiturgy(), isTrue);
  });

  test('geolocation is a separate flag from the liturgy one', () async {
    SharedPreferences.setMockInitialValues({keyFeatureOfflineLiturgy: false});

    final state = FeatureFlagsState();
    await pumpEventQueue();

    await state.setOfflineGeolocationEnabled(true);

    expect(state.offlineGeolocationEnabled, isTrue);
    expect(state.offlineLiturgyEnabled, isFalse,
        reason: 'enabling geolocation must not switch on the offline liturgy');
  });
}
