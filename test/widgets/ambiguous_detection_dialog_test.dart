import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/geolocalisation_service.dart';
import 'package:aelf_flutter/utils/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When the position matches more than one registered location (the
/// diocese boundary data overlaps two adjacent dioceses near their shared
/// edge), [GeolocalisationService.showAmbiguousDetectionDialog] offers one
/// button per candidate instead of silently picking one.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<BuildContext> pump(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(ChangeNotifierProvider<LiturgyState>.value(
      value: _FakeLiturgyState(),
      child: MaterialApp(
        home: Builder(builder: (c) {
          context = c;
          return const Scaffold();
        }),
      ),
    ));
    return context;
  }

  testWidgets('one button per candidate, plus the manual and ignore ways out',
      (tester) async {
    final context = await pump(tester);
    GeolocalisationService.showAmbiguousDetectionDialog(
        context, {'valence': 'Diocèse de Valence', 'grenoble': 'Grenoble'});
    await tester.pumpAndSettle();

    expect(find.text('Diocèse de Valence'), findsOneWidget);
    expect(find.text('Grenoble'), findsOneWidget);
    expect(find.text('Choisir manuellement'), findsOneWidget);
    expect(find.text('Ignorer'), findsOneWidget);
  });

  testWidgets('picking a candidate selects it and closes the dialog',
      (tester) async {
    final context = await pump(tester);
    GeolocalisationService.showAmbiguousDetectionDialog(
        context, {'valence': 'Diocèse de Valence', 'grenoble': 'Grenoble'});
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diocèse de Valence'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(await LocationService.getSelectedLocation(), 'valence');
  });

  testWidgets('"Ignorer" closes the dialog without choosing anything',
      (tester) async {
    final context = await pump(tester);
    GeolocalisationService.showAmbiguousDetectionDialog(
        context, {'valence': 'Diocèse de Valence', 'grenoble': 'Grenoble'});
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ignorer'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(await LocationService.getSelectedLocation(), 'romain',
        reason: 'the default — nothing was selected');
  });
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  // The real implementation, not noSuchMethod: every candidate button calls
  // this, so it must actually exist rather than throw.
  @override
  void updateOfflineRegion(String newRegion) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
