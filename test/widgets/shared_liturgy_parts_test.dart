import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widgets used by *both* liturgies.
///
/// `LiturgyRow` backs every online `liturgy_part_*` and ten of the offline
/// office widgets; `LiturgyPartTitle` came from the online side and is now used
/// by all nine offline views. Changing either while working on the offline
/// liturgy lands straight on the online one, which is what these pin down.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host(Widget child, {double zoom = 100, ThemeData? theme}) {
    final currentZoom = CurrentZoom()..updateZoom(zoom);
    return ChangeNotifierProvider<CurrentZoom>.value(
      value: currentZoom,
      child: MaterialApp(
        theme: theme ?? light,
        home: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );
  }

  group('LiturgyPartTitle', () {
    testWidgets('renders its text', (tester) async {
      await tester.pumpWidget(host(const LiturgyPartTitle('Psalmodie')));
      await tester.pump();

      expect(
          find.textContaining('Psalmodie', findRichText: true), findsWidgets);
    });

    testWidgets('collapses to nothing for null and empty content',
        (tester) async {
      for (final content in [null, '']) {
        await tester.pumpWidget(host(LiturgyPartTitle(content)));
        await tester.pump();

        expect(tester.getSize(find.byType(LiturgyPartTitle)), Size.zero,
            reason: 'content=${content == null ? 'null' : 'empty'} should '
                'take no vertical space at all');
      }
    });

    testWidgets('grows with the zoom level', (tester) async {
      await tester.pumpWidget(host(const LiturgyPartTitle('Psalmodie')));
      await tester.pump();
      final small = tester.getSize(find.byType(LiturgyPartTitle)).height;

      await tester
          .pumpWidget(host(const LiturgyPartTitle('Psalmodie'), zoom: 300));
      await tester.pump();
      final large = tester.getSize(find.byType(LiturgyPartTitle)).height;

      expect(large, greaterThan(small));
    });

    testWidgets('defaults to no left column, spanning the full width',
        (tester) async {
      await tester.pumpWidget(host(const LiturgyPartTitle('Psalmodie')));
      await tester.pump();

      final rowLeft = tester.getTopLeft(find.byType(LiturgyRow)).dx;
      final textLeft = tester.getTopLeft(find.byType(RichText).first).dx;
      expect(textLeft - rowLeft, moreOrLessEquals(0, epsilon: 0.5));
    });

    testWidgets('with LiturgyRowLeft.indent it lines up with the verses',
        (tester) async {
      await tester.pumpWidget(host(
          const LiturgyPartTitle('Psalmodie', left: LiturgyRowLeft.indent)));
      await tester.pump();

      final rowLeft = tester.getTopLeft(find.byType(LiturgyRow)).dx;
      final textLeft = tester.getTopLeft(find.byType(RichText).first).dx;
      expect(textLeft - rowLeft,
          moreOrLessEquals(liturgyRowIndentWidth(100), epsilon: 0.5),
          reason: 'CLAUDE.md: titles beside verses share the verse column');
    });

    testWidgets('topPadding: false removes the leading gap', (tester) async {
      await tester.pumpWidget(host(const LiturgyPartTitle('Psalmodie')));
      await tester.pump();
      final withPadding = tester.getSize(find.byType(LiturgyPartTitle)).height;

      await tester.pumpWidget(
          host(const LiturgyPartTitle('Psalmodie', topPadding: false)));
      await tester.pump();
      final without = tester.getSize(find.byType(LiturgyPartTitle)).height;

      expect(without, lessThan(withPadding));
    });

    testWidgets('a trailing widget is laid out beside the title',
        (tester) async {
      await tester.pumpWidget(host(LiturgyPartTitle(
        'Psalmodie',
        trailing: (zoom) => const Icon(Icons.music_note, key: Key('trailing')),
      )));
      await tester.pump();

      expect(find.byKey(const Key('trailing')), findsOneWidget);
      final titleLeft = tester.getTopLeft(find.byType(RichText).first).dx;
      final trailingLeft =
          tester.getTopLeft(find.byKey(const Key('trailing'))).dx;
      expect(trailingLeft, greaterThan(titleLeft));
    });

    testWidgets('the trailing builder receives the current zoom',
        (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(host(
        LiturgyPartTitle('Psalmodie', trailing: (zoom) {
          seen.add(zoom);
          return const SizedBox.shrink();
        }),
        zoom: 250,
      ));
      await tester.pump();

      expect(seen, isNotEmpty);
      expect(seen.last, 250);
    });

    for (final entry in {'light': light, 'dark': dark}.entries) {
      testWidgets('renders in the ${entry.key} theme', (tester) async {
        await tester.pumpWidget(
            host(const LiturgyPartTitle('Psalmodie'), theme: entry.value));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('YAML markup in a title is parsed, not shown raw',
        (tester) async {
      // Offline titles carry the YAML markup format.
      await tester.pumpWidget(host(const LiturgyPartTitle('Psaume %62%')));
      await tester.pump();

      expect(find.textContaining('%', findRichText: true), findsNothing,
          reason: 'the italic markers should be consumed by the parser');
      expect(find.textContaining('Psaume', findRichText: true), findsWidgets);
    });
  });

  group('LiturgyRow left column variants', () {
    testWidgets('a custom left widget occupies the verse column width',
        (tester) async {
      await tester.pumpWidget(host(LiturgyRow(
        left: LiturgyRowLeft.widget(
            const ColoredBox(color: Colors.red, key: Key('bullet'))),
        builder: (context, zoom) => const Text('Antienne', key: Key('content')),
      )));
      await tester.pump();

      final rowLeft = tester.getTopLeft(find.byType(LiturgyRow)).dx;
      final contentLeft =
          tester.getTopLeft(find.byKey(const Key('content'))).dx;

      expect(find.byKey(const Key('bullet')), findsOneWidget);
      expect(contentLeft - rowLeft,
          moreOrLessEquals(liturgyRowIndentWidth(100), epsilon: 0.5),
          reason: 'a bullet must not shift the content off the verse column');
    });

    testWidgets('the builder receives the live zoom value', (tester) async {
      final seen = <double?>[];
      await tester.pumpWidget(host(
        LiturgyRow(builder: (context, zoom) {
          seen.add(zoom);
          return const SizedBox.shrink();
        }),
        zoom: 175,
      ));
      await tester.pump();

      expect(seen.last, 175);
    });

    testWidgets('extra padding is applied inside the content column',
        (tester) async {
      await tester.pumpWidget(host(LiturgyRow(
        padding: const EdgeInsets.only(left: 20),
        builder: (context, zoom) => const Text('x', key: Key('content')),
      )));
      await tester.pump();

      final rowLeft = tester.getTopLeft(find.byType(LiturgyRow)).dx;
      final contentLeft =
          tester.getTopLeft(find.byKey(const Key('content'))).dx;

      expect(contentLeft - rowLeft,
          moreOrLessEquals(liturgyRowIndentWidth(100) + 20, epsilon: 0.5));
    });

    testWidgets('reacts to a zoom change without being rebuilt from scratch',
        (tester) async {
      final zoomState = CurrentZoom();
      await tester.pumpWidget(ChangeNotifierProvider<CurrentZoom>.value(
        value: zoomState,
        child: MaterialApp(
          theme: light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: LiturgyRow(
                builder: (context, zoom) =>
                    const SizedBox(key: Key('content'), height: 10),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();

      double indent() =>
          tester.getTopLeft(find.byKey(const Key('content'))).dx -
          tester.getTopLeft(find.byType(LiturgyRow)).dx;

      expect(
          indent(), moreOrLessEquals(liturgyRowIndentWidth(100), epsilon: 0.5));

      zoomState.updateZoom(200);
      await tester.pump();

      expect(
          indent(), moreOrLessEquals(liturgyRowIndentWidth(200), epsilon: 0.5),
          reason: 'the shared row must follow the zoom for both liturgies');
    });
  });
}
