import 'package:aelf_flutter/utils/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings defaults decide what a fresh install sees. The critical one is
/// `getFeatureOfflineLiturgy`: the new (offline) version is the default, and
/// the online API liturgy is what a user gets by switching it off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('feature_offline_liturgy flag', () {
    test('is ON on a fresh install', () async {
      expect(await getFeatureOfflineLiturgy(), isTrue,
          reason: 'the new version is the default; the online one is opt-out');
    });

    test('round-trips once the user opts out', () async {
      await setFeatureOfflineLiturgy(false);
      expect(await getFeatureOfflineLiturgy(), isFalse);
      await setFeatureOfflineLiturgy(true);
      expect(await getFeatureOfflineLiturgy(), isTrue);
    });

    test('is stored under the key the native app already uses', () async {
      await setFeatureOfflineLiturgy(true);
      final prefs = await SharedPreferences.getInstance();
      expect(keyFeatureOfflineLiturgy, 'feature_offline_liturgy');
      expect(prefs.getBool('feature_offline_liturgy'), isTrue);
    });
  });

  group('other feature flags', () {
    test('the serif font is on by default', () async {
      expect(await getSerifFont(), isTrue);
    });

    test('offline geolocation, imprecatory verses, scroll mode, SVG are off',
        () async {
      expect(await getOfflineGeolocation(), isFalse);
      expect(await getImprecatoryVerses(), isFalse);
      expect(await getScrollMode(), isFalse);
      expect(await getPsalmSvgEnabled(), isFalse);
    });

    test('each one round-trips', () async {
      await setOfflineGeolocation(true);
      await setImprecatoryVerses(true);
      await setScrollMode(true);
      await setSerifFont(false);
      await setPsalmSvgEnabled(true);

      expect(await getOfflineGeolocation(), isTrue);
      expect(await getImprecatoryVerses(), isTrue);
      expect(await getScrollMode(), isTrue);
      expect(await getSerifFont(), isFalse);
      expect(await getPsalmSvgEnabled(), isTrue);
    });
  });

  group('regions', () {
    test('a stored online region is returned as-is', () async {
      await setRegion('belgique');
      expect(await getRegion(), 'belgique');
    });

    test('with nothing stored, a region is detected and persisted', () async {
      final detected = await getRegion();
      expect(detected, isNotEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(keyPrefRegion), detected,
          reason: 'the detected region must be written back');
      expect(await getRegion(), detected, reason: 'and be stable afterwards');
    });

    test('the offline region defaults to the roman calendar', () async {
      expect(await getOfflineRegion(), 'romain');
      await setOfflineRegion('france');
      expect(await getOfflineRegion(), 'france');
    });

    test('online and offline regions are stored independently', () async {
      await setRegion('france');
      await setOfflineRegion('belgium');
      expect(await getRegion(), 'france');
      expect(await getOfflineRegion(), 'belgium');
      expect(keyPrefRegion, isNot(keyOfflineRegion));
    });
  });

  group('psalm SVG source', () {
    test('defaults to seminaire-emmanuel and round-trips', () async {
      expect(await getPsalmSvgSource(), 'seminaire-emmanuel');
      await setPsalmSvgSource('seminaire-paris');
      expect(await getPsalmSvgSource(), 'seminaire-paris');
    });
  });

  group('movable feast date overrides', () {
    test('are unset by default', () async {
      expect(await getEpiphanyDateOverride(), isNull);
      expect(await getAscensionDateOverride(), isNull);
      expect(await getCorpusDominiDateOverride(), isNull);
    });

    test('round-trip independently', () async {
      await setEpiphanyDateOverride('sunday');
      await setAscensionDateOverride('thursday');
      await setCorpusDominiDateOverride('sunday');

      expect(await getEpiphanyDateOverride(), 'sunday');
      expect(await getAscensionDateOverride(), 'thursday');
      expect(await getCorpusDominiDateOverride(), 'sunday');
    });
  });
}
