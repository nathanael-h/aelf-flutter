import 'dart:async';
import 'dart:io';

import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/location_service.dart';
import 'package:aelf_flutter/utils/region_sync.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// `LiturgyState` holds four things that must stay consistent with each other:
/// the **date**, the **online region**, the **offline location**, and the
/// current **office** (`liturgyType`).
///
/// The risky one is the region/location pair. The offline location list is far
/// longer than the online region list, so choosing a location has to be
/// translated into a region the API accepts — otherwise Mass, which has no
/// offline implementation, silently starts serving the wrong calendar.
/// `region_sync.dart` owns that rule and `region_sync_test.dart` covers it over
/// the whole real tree; these tests check `LiturgyState` actually applies it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('aelf_liturgy_state_test');

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    for (final channel in [
      'plugins.flutter.io/path_provider',
      'plugins.flutter.io/path_provider_linux',
    ]) {
      messenger.setMockMethodCallHandler(
          MethodChannel(channel), (call) async => tmp.path);
    }

    PackageInfo.setMockInitialValues(
      appName: 'aelf',
      packageName: 'fr.isidorus.aelf-flutter',
      version: '1.16.0',
      buildNumber: '29',
      buildSignature: '',
    );

    // Every selectOfflineLocation() call below also updates the *online*
    // region, and LiturgyState.updateRegion() unconditionally reacts by
    // fetching the online liturgy — that's correct app behaviour (the
    // default liturgyType is 'messes'), but here it's an unrelated side
    // effect that fires a real HTTP request per office/region combination.
    // Stand in a client that fails the same way a real 5xx would (the
    // exact shape _getAELFLiturgyOnWeb already falls back to for a non-200
    // response), so these tests stay deterministic and network-free instead
    // of depending on how the runner's sandbox happens to handle outbound
    // connections.
    HttpOverrides.global = _NoNetworkHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// Builds a state and lets its async constructor work settle.
  Future<LiturgyState> newState([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final state = LiturgyState();
    await pumpEventQueue(times: 200);
    return state;
  }

  group('startup defaults are coherent', () {
    test('the date is today, in the API\'s yyyy-MM-dd form', () async {
      final state = await newState();
      final today = DateTime.now();
      expect(state.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(state.date, '${today.toLocal()}'.split(' ')[0]);
    });

    test('the online region is one the API accepts', () async {
      final state = await newState();
      expect(kValidOnlineRegions, contains(state.region));
    });

    test('the offline location defaults to the Roman calendar', () async {
      final state = await newState();
      expect(state.offlineRegion, 'romain');
      expect(state.offlineRegionLabel, 'Calendrier romain');
    });

    test('the office defaults to a real section', () async {
      final state = await newState();
      expect(state.liturgyType, 'messes');
    });
  });

  group('the stored online region is validated', () {
    test('a valid stored region is kept', () async {
      for (final region in ['france', 'belgique', 'canada', 'romain']) {
        final state = await newState({keyPrefRegion: region});
        expect(state.region, region, reason: region);
      }
    });

    test('a region the API would reject is replaced', () async {
      // Otherwise every request would 404 for as long as the value persisted.
      final state = await newState({keyPrefRegion: 'atlantide'});
      expect(state.region, isNot('atlantide'));
      expect(kValidOnlineRegions, contains(state.region));
      expect(state.region, 'france', reason: 'the documented fallback');
    });

    test('the corrected region is written back, not just held in memory',
        () async {
      await newState({keyPrefRegion: 'atlantide'});
      expect(await getRegion(), 'france');
    });
  });

  group('choosing an offline location syncs the online region', () {
    test('a French diocese sets the offline location and the region france',
        () async {
      final state = await newState();

      await state.selectOfflineLocation('lyon');
      await pumpEventQueue(times: 50);

      expect(state.offlineRegion, 'lyon');
      expect(state.region, 'france',
          reason: 'the online API has no Lyon, so it must fall back to France');
      expect(await LocationService.getSelectedLocation(), 'lyon');
      expect(await getOfflineRegion(), 'lyon');
    });

    test('a country with a different offline spelling still syncs', () async {
      final state = await newState();

      await state.selectOfflineLocation('belgium');
      await pumpEventQueue(times: 50);

      expect(state.offlineRegion, 'belgium');
      expect(state.region, 'belgique',
          reason: 'offline "belgium" is online "belgique"');
    });

    test('an African location maps onto the single afrique region', () async {
      final state = await newState();

      await state.selectOfflineLocation('north-africa');
      await pumpEventQueue(times: 50);

      expect(state.offlineRegion, 'north-africa');
      expect(state.region, 'afrique');
    });

    test('a continent with no API region falls back to the Roman calendar',
        () async {
      final state = await newState();

      await state.selectOfflineLocation('europe');
      await pumpEventQueue(times: 50);

      expect(state.offlineRegion, 'europe');
      expect(state.region, 'romain');
    });

    test('whatever is chosen, the online region stays valid', () async {
      final state = await newState();

      for (final id in [
        'lyon',
        'belgium',
        'switzerland',
        'canada',
        'monaco',
        'north-africa',
        'europe',
        'atlantis'
      ]) {
        await state.selectOfflineLocation(id);
        await pumpEventQueue(times: 30);
        expect(kValidOnlineRegions, contains(state.region),
            reason: 'location "$id" left region "${state.region}"');
      }
    });

    test('the displayed label follows the chosen location', () async {
      final state = await newState();

      await state.selectOfflineLocation('france');
      await pumpEventQueue(times: 50);
      expect(state.offlineRegionLabel, 'France');

      await state.selectOfflineLocation('belgium');
      await pumpEventQueue(times: 50);
      expect(state.offlineRegionLabel, 'Belgique');

      await state.selectOfflineLocation('romain');
      await pumpEventQueue(times: 50);
      expect(state.offlineRegionLabel, 'Calendrier romain',
          reason: 'the Roman calendar is not a node in the location tree');
    });

    test('an unknown location degrades to the Roman label, not a crash',
        () async {
      final state = await newState();

      await state.selectOfflineLocation('atlantis');
      await pumpEventQueue(times: 50);

      expect(state.offlineRegionLabel, 'Calendrier romain');
      expect(state.region, 'romain');
    });
  });

  group('inferOnlineRegion on the state matches the shared rule', () {
    test('delegates to region_sync for real locations', () async {
      final state = await newState();
      expect(await state.inferOnlineRegion('lyon'), 'france');
      expect(await state.inferOnlineRegion('switzerland'), 'suisse');
      expect(await state.inferOnlineRegion('north-africa'), 'afrique');
      expect(await state.inferOnlineRegion('atlantis'), 'romain');
    });
  });

  group('the online and offline selections stay independent', () {
    test('changing the online region leaves the offline location alone',
        () async {
      final state = await newState();
      await state.selectOfflineLocation('lyon');
      await pumpEventQueue(times: 50);

      state.updateRegion('canada');
      await pumpEventQueue(times: 30);

      expect(state.region, 'canada');
      expect(state.offlineRegion, 'lyon',
          reason:
              'the offline calendar is not dragged along by the API region');
    });

    test('each is persisted under its own key', () async {
      final state = await newState();
      // Order matters: selecting a location syncs the online region to it, so
      // an explicit region choice has to come afterwards to survive.
      await state.selectOfflineLocation('lyon');
      await pumpEventQueue(times: 50);
      state.updateRegion('canada');
      await pumpEventQueue(times: 30);

      expect(await getRegion(), 'canada');
      expect(await getOfflineRegion(), 'lyon');
    });
  });

  group('updates notify only on a real change', () {
    test('the date', () async {
      final state = await newState();
      var notifications = 0;
      state.addListener(() => notifications++);

      state.updateDate('2025-06-08');
      expect(state.date, '2025-06-08');
      expect(notifications, 1);

      state.updateDate('2025-06-08');
      expect(notifications, 1, reason: 'same date, no rebuild');
    });

    test('the office', () async {
      final state = await newState();
      var notifications = 0;
      state.addListener(() => notifications++);

      state.updateLiturgyType('laudes');
      expect(state.liturgyType, 'laudes');
      expect(notifications, 1);

      state.updateLiturgyType('laudes');
      expect(notifications, 1, reason: 'same office, no rebuild');
    });

    test('the region', () async {
      final state = await newState({keyPrefRegion: 'france'});
      var notifications = 0;
      state.addListener(() => notifications++);

      state.updateRegion('canada');
      expect(state.region, 'canada');
      expect(notifications, 1);

      state.updateRegion('canada');
      expect(notifications, 1, reason: 'same region, no rebuild');
    });
  });

  group('date arithmetic for the offline cache', () {
    test('produces API-shaped dates either side of today', () async {
      final state = await newState();
      final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');

      expect(state.getDifferedDateAdd(0), matches(iso));
      expect(state.getDifferedDateAdd(0), state.date);

      for (final days in [1, 7, 20, 365]) {
        final ahead = DateTime.parse(state.getDifferedDateAdd(days));
        final behind = DateTime.parse(state.getDifferedDateSub(days));
        final today = DateTime.parse(state.date);

        expect(ahead.difference(today).inDays, days);
        expect(today.difference(behind).inDays, days);
      }
    });

    test('crosses month and year boundaries correctly', () async {
      final state = await newState();
      // 400 days always crosses a year; just check it parses and moves forward.
      final far = DateTime.parse(state.getDifferedDateAdd(400));
      expect(far.isAfter(DateTime.parse(state.date)), isTrue);
    });
  });

  group('startup survives a missing device_info plugin', () {
    test('initUserAgent degrades instead of throwing', () async {
      // device_info is a plugin, so it is unavailable under flutter test —
      // the same situation as an unusual host. It must not take the
      // constructor down with it. (Reaching this assertion at all is the
      // point: an escaping error fails the test.)
      final state = await newState();
      await pumpEventQueue(times: 50);
      expect(state.userAgent, isA<String>());
    });
  });
}

/// Fails every request the way _getAELFLiturgyOnWeb's own non-200 branch
/// already handles, without touching the network. Only the members that
/// code path actually calls are given real bodies; everything else falls
/// through noSuchMethod, which is safe because nothing else is called.
class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _NoNetworkHttpClient();
}

class _NoNetworkHttpClient implements HttpClient {
  @override
  set userAgent(String? value) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _NoNetworkHttpClientRequest();

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoNetworkHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _NoNetworkHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoNetworkHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.serviceUnavailable;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return const Stream<List<int>>.empty().listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
