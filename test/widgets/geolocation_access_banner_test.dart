import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/utils/geolocalisation_service.dart';
import 'package:aelf_flutter/widgets/geolocation_access_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unlike [GeolocationSetting] (only seen by someone who opens the settings
/// screen) and the hourly background check (silent on purpose), this banner
/// is what actually tells the user, wherever they are in the app, that
/// detection stopped working because the system revoked the permission.
void main() {
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  const denied = 0, whileInUse = 2;

  late bool serviceEnabled;
  late int permission;
  late List<String> calls;

  setUp(() {
    serviceEnabled = true;
    permission = whileInUse;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return serviceEnabled;
        case 'checkPermission':
          return permission;
        case 'openAppSettings':
        case 'openLocationSettings':
          return true;
      }
      return null;
    });
  });

  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  Future<FeatureFlagsState> pump(WidgetTester tester,
      {bool enabled = true, bool offlineLiturgyEnabled = true}) async {
    SharedPreferences.setMockInitialValues({
      'feature_offline_geolocation': enabled,
      'feature_offline_liturgy': offlineLiturgyEnabled,
    });
    final flags = FeatureFlagsState();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: flags,
      child: const MaterialApp(
        home: Scaffold(body: GeolocationAccessBanner()),
      ),
    ));
    await tester.pumpAndSettle();
    return flags;
  }

  testWidgets('disabled: no banner', (tester) async {
    await pump(tester, enabled: false);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('enabled and allowed: no banner', (tester) async {
    await pump(tester);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('enabled but revoked: warns, with the way to the settings',
      (tester) async {
    permission = denied;
    await pump(tester);
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(
        find.textContaining(
            'AELF n’a plus l’autorisation d’accéder à votre position'),
        findsOneWidget);

    await tester.tap(find.text('Ouvrir les réglages'));
    await tester.pumpAndSettle();
    expect(calls, contains('openAppSettings'));
  });

  testWidgets('enabled but the device location is off: says so',
      (tester) async {
    serviceEnabled = false;
    await pump(tester);
    expect(
        find.textContaining('La localisation a été désactivée sur l’appareil'),
        findsOneWidget);
  });

  testWidgets('"Fermer" dismisses the banner', (tester) async {
    permission = denied;
    await pump(tester);
    expect(find.byType(MaterialBanner), findsOneWidget);

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('repeated resumes while revoked do not stack banners',
      (tester) async {
    permission = denied;
    await pump(tester);
    expect(find.byType(MaterialBanner), findsOneWidget);

    // ScaffoldMessenger *queues* banners, so showing one per resume would
    // leave the user tapping "Fermer" once per app switch, each tap only
    // revealing the next identical copy.
    for (var i = 0; i < 3; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing,
        reason: 'one "Fermer" must dismiss it, not one per resume');
  });

  testWidgets('access restored on resume: the banner goes away',
      (tester) async {
    permission = denied;
    await pump(tester);
    expect(find.byType(MaterialBanner), findsOneWidget);

    permission = whileInUse;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets(
      'revoked to a hard block mid-session (e.g. "don\'t ask again" on a '
      're-prompt): refreshes right away, no need to background the app first',
      (tester) async {
    await pump(tester);
    expect(find.byType(MaterialBanner), findsNothing);

    // Simulate the settings toggle discovering the new access state itself
    // (GeolocationSetting._onChanged pings this after every requestAccess).
    permission = denied;
    GeolocalisationService.notifyAccessChanged();
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(
        find.textContaining(
            'AELF n’a plus l’autorisation d’accéder à votre position'),
        findsOneWidget);
  });

  testWidgets(
      'the offline liturgy is off: no banner, even though geolocation is '
      'still enabled and revoked (the settings row to fix it is hidden too)',
      (tester) async {
    permission = denied;
    await pump(tester, offlineLiturgyEnabled: false);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('turning the setting off also clears the banner', (tester) async {
    permission = denied;
    final flags = await pump(tester);
    expect(find.byType(MaterialBanner), findsOneWidget);

    await flags.setOfflineGeolocationEnabled(false);
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
  });
}
