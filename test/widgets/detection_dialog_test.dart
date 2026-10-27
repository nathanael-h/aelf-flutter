import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/geolocalisation_service.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The dialog of a detected diocese with no data yet stays readable by
/// night as by day: every text against the dialog's background.
void main() {
  // Its beginning: enough to find it
  const message = 'Ce diocèse n';

  double contrast(Color a, Color b) {
    final (la, lb) = (a.computeLuminance(), b.computeLuminance());
    return (la > lb ? la + 0.05 : lb + 0.05) /
        (la > lb ? lb + 0.05 : la + 0.05);
  }

  for (final (name, theme) in [('day', light), ('night', dark)]) {
    testWidgets('readable by $name', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(ChangeNotifierProvider<LiturgyState>.value(
        value: _FakeLiturgyState(),
        child: MaterialApp(
          theme: theme,
          home: Builder(builder: (c) {
            context = c;
            return const Scaffold();
          }),
        ),
      ));
      GeolocalisationService.showDetectionDialog(context, 'france',
          showHelperMessage: true, rawDioceseId: 'saint_flour');
      await tester.pumpAndSettle();

      final background = tester
          .widget<Material>(find
              .descendant(
                  of: find.byType(AlertDialog), matching: find.byType(Material))
              .first)
          .color!;
      Color colorOf(String text) {
        final finder = find.textContaining(text);
        return tester.widget<Text>(finder).style?.color ??
            DefaultTextStyle.of(tester.element(finder)).style.color!;
      }

      expect(contrast(colorOf(message), background), greaterThan(4.5));
      // Large and bold: a lower contrast reads
      expect(contrast(colorOf('Saint Flour'), background), greaterThan(3));
      for (final button in ['Ignorer', 'Choisir manuellement']) {
        expect(contrast(colorOf(button), background), greaterThan(4.5),
            reason: button);
      }
    });
  }
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
