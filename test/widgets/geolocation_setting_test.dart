import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/widgets/geolocation_setting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The geolocation switch tells what the system allows, rather than
/// promising a detection it forbids.
void main() {
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  // LocationPermission's index, as the platform sends it
  const denied = 0, deniedForever = 1, whileInUse = 2;

  late bool serviceEnabled;
  late int permission;
  late int permissionOnRequest;
  late List<String> calls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    serviceEnabled = true;
    permission = whileInUse;
    permissionOnRequest = whileInUse;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return serviceEnabled;
        case 'checkPermission':
          return permission;
        case 'requestPermission':
          return permission = permissionOnRequest;
        case 'openAppSettings':
        case 'openLocationSettings':
          return true;
      }
      // No position: the detection stops there
      return null;
    });
  });

  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  Future<FeatureFlagsState> pump(WidgetTester tester) async {
    final flags = FeatureFlagsState();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: flags,
      child: const MaterialApp(
        home: Scaffold(body: GeolocationSetting()),
      ),
    ));
    await tester.pumpAndSettle();
    return flags;
  }

  Switch switchOf(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch));

  testWidgets('allowed: the switch alone, no warning', (tester) async {
    await pump(tester);
    expect(switchOf(tester).onChanged, isNotNull);
    expect(find.text('Ouvrir les réglages'), findsNothing);
  });

  testWidgets('location off on the device: greyed, said, its settings',
      (tester) async {
    serviceEnabled = false;
    await pump(tester);
    expect(switchOf(tester).onChanged, isNull);
    expect(switchOf(tester).value, isFalse);
    expect(find.text('La localisation est désactivée sur l’appareil.'),
        findsOneWidget);
    await tester.tap(find.text('Ouvrir les réglages'));
    expect(calls, contains('openLocationSettings'));
  });

  testWidgets("refused to the app: greyed, said, the app's settings",
      (tester) async {
    permission = deniedForever;
    await pump(tester);
    expect(switchOf(tester).onChanged, isNull);
    expect(find.text('AELF n’a pas l’autorisation d’accéder à votre position.'),
        findsOneWidget);
    expect(
        find.textContaining('Dans Autorisations › Position'), findsOneWidget);
    await tester.tap(find.text('Ouvrir les réglages'));
    expect(calls, contains('openAppSettings'));
  });

  group('on iOS', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    testWidgets("refused to the app: the steps left in the app's page",
        (tester) async {
      permission = deniedForever;
      await pump(tester);
      expect(find.textContaining('Dans Réglages › AELF, touchez Position'),
          findsOneWidget);
      expect(find.text('Ouvrir les réglages'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
        'location off on the device: the way to Location Services, '
        'which no settings page an app opens leads to', (tester) async {
      serviceEnabled = false;
      await pump(tester);
      expect(
          find.textContaining('Confidentialité et sécurité, activez Service '
              'de localisation'),
          findsOneWidget);
      expect(find.text('Ouvrir les réglages'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  testWidgets('turned on, it asks the system first', (tester) async {
    permission = denied;
    final flags = await pump(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(calls, contains('requestPermission'));
    expect(flags.offlineGeolocationEnabled, isTrue);
  });

  testWidgets('refused when asked: stays off, and says so', (tester) async {
    permission = denied;
    permissionOnRequest = deniedForever;
    final flags = await pump(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(flags.offlineGeolocationEnabled, isFalse);
    expect(switchOf(tester).onChanged, isNull);
    expect(find.text('Ouvrir les réglages'), findsOneWidget);
  });

  testWidgets('allowed again in the settings: back on, as chosen',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'feature_offline_geolocation': true});
    permission = deniedForever;
    await pump(tester);
    expect(switchOf(tester).value, isFalse);

    permission = whileInUse;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(switchOf(tester).value, isTrue);
    expect(find.text('Ouvrir les réglages'), findsNothing);
  });
}
