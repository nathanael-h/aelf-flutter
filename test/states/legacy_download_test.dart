import 'dart:async';
import 'dart:io';

import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The online liturgy (api.aelf.org) is the legacy mode, enabled in the
/// settings. Its offices are downloaded ahead only while it is enabled: with
/// the offline liturgy, the default, the app must not fetch them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  final requests = <Uri>[];

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('aelf_legacy_download_test');
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
    // Every request is recorded and fails like a server error: nothing is
    // saved, so each test starts from an empty database.
    HttpOverrides.global = _RecordingHttpOverrides(requests);
  });

  tearDownAll(() {
    HttpOverrides.global = null;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  setUp(requests.clear);

  /// A new state, once its async startup has settled.
  Future<LiturgyState> startState(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final state = LiturgyState();
    await pumpEventQueue(times: 2000);
    return state;
  }

  /// The paths of the online liturgy requests: v1/<type>/<date>/<region>.
  List<List<String>> liturgyPaths() => requests
      .where((uri) => uri.host == 'api.aelf.org')
      .map((uri) => uri.pathSegments)
      .toList();

  test('the offline liturgy downloads no online day ahead', () async {
    await startState({});
    final dates = liturgyPaths().map((path) => path[2]).toSet();
    // At most today's, the office the state starts on.
    expect(dates.length, lessThanOrEqualTo(1), reason: '$requests');
  });

  test('enabling the legacy mode downloads its coming days', () async {
    final state = await startState({});
    requests.clear();
    // What the settings switch does.
    await setFeatureOfflineLiturgy(false);
    state.autoSaveLiturgy();
    await pumpEventQueue(times: 2000);
    final dates = liturgyPaths()
        .where((path) => path[1] == 'lectures')
        .map((path) => path[2])
        .toSet();
    expect(dates, hasLength(state.nbDaysSaved));
  });

  test('the legacy mode downloads every office of the coming days', () async {
    final state = await startState({keyFeatureOfflineLiturgy: false});
    final paths = liturgyPaths();
    // informations comes from another API (api.epitre.co).
    for (final type in state.types.where((t) => t != 'informations')) {
      final dates = paths.where((p) => p[1] == type).map((p) => p[2]).toSet();
      expect(dates, hasLength(state.nbDaysSaved), reason: type);
    }
  });
}

class _RecordingHttpOverrides extends HttpOverrides {
  _RecordingHttpOverrides(this.requests);

  final List<Uri> requests;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _RecordingHttpClient(requests);
}

class _RecordingHttpClient implements HttpClient {
  _RecordingHttpClient(this.requests);

  final List<Uri> requests;

  @override
  set userAgent(String? value) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requests.add(url);
    return _FailingRequest();
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FailingResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingResponse extends Stream<List<int>> implements HttpClientResponse {
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
