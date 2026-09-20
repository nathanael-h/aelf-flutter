import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/bible_verse_id.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The liturgy layout rule from CLAUDE.md: every text block stacked around the
/// psalm verses shares the verses' left column. That only holds while the
/// verse-id column and the `LiturgyRow` indent are exactly the same width.
///
/// `BibleVerseId` renders verse numbers, `verseIdPlaceholder` renders the blank
/// column for numberless lines, and `liturgyRowIndentWidth` is what every
/// `LiturgyRow` reserves. If these three drift apart the left edges go ragged —
/// the exact symptom CLAUDE.md warns about.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const zooms = <double>[60, 100, 150, 300];

  Widget host(Widget child, {double zoom = 100}) {
    final currentZoom = CurrentZoom()..updateZoom(zoom);
    return ChangeNotifierProvider<CurrentZoom>.value(
      value: currentZoom,
      child: MaterialApp(
        home: Scaffold(body: Align(alignment: Alignment.topLeft, child: child)),
      ),
    );
  }

  group('verse column width', () {
    for (final zoom in zooms) {
      testWidgets('BibleVerseId occupies the LiturgyRow indent at $zoom%',
          (tester) async {
        await tester.pumpWidget(host(
          BibleVerseId(id: '12', fontSize: verseFontSize * zoom / 100),
          zoom: zoom,
        ));

        expect(
          tester.getSize(find.byType(BibleVerseId)).width,
          moreOrLessEquals(liturgyRowIndentWidth(zoom), epsilon: 0.01),
          reason: 'verse numbers and LiturgyRow content must share one column',
        );
      });

      testWidgets('verseIdPlaceholder matches the same width at $zoom%',
          (tester) async {
        await tester.pumpWidget(host(
          verseIdPlaceholder(zoom: zoom),
          zoom: zoom,
        ));

        expect(
          tester.getSize(find.byType(verseIdPlaceholder)).width,
          moreOrLessEquals(liturgyRowIndentWidth(zoom), epsilon: 0.01),
          reason: 'numberless lines must line up with numbered ones',
        );
      });
    }

    test('the indent formula stays 10 + verseFontSize * zoom / 100', () {
      expect(liturgyRowIndentWidth(100), 10.0 + verseFontSize);
      expect(liturgyRowIndentWidth(200), 10.0 + verseFontSize * 2);
      expect(liturgyRowIndentWidth(50), 10.0 + verseFontSize / 2);
    });

    test('the indent grows with zoom', () {
      var previous = 0.0;
      for (final zoom in zooms) {
        final width = liturgyRowIndentWidth(zoom);
        expect(width, greaterThan(previous));
        previous = width;
      }
    });
  });

  group('LiturgyRow layout', () {
    testWidgets('indents its content by exactly the verse column width',
        (tester) async {
      await tester.pumpWidget(host(
        LiturgyRow(
          builder: (context, zoom) =>
              const Text('Antienne', key: ValueKey('content')),
        ),
      ));

      final rowLeft = tester.getTopLeft(find.byType(LiturgyRow)).dx;
      final contentLeft =
          tester.getTopLeft(find.byKey(const ValueKey('content'))).dx;

      expect(contentLeft - rowLeft,
          moreOrLessEquals(liturgyRowIndentWidth(100), epsilon: 0.01));
    });

    testWidgets('LiturgyRowLeft.none spans the full width', (tester) async {
      await tester.pumpWidget(host(
        LiturgyRow(
          left: LiturgyRowLeft.none,
          builder: (context, zoom) =>
              const Text('Titre', key: ValueKey('content')),
        ),
      ));

      final rowLeft = tester.getTopLeft(find.byType(LiturgyRow)).dx;
      final contentLeft =
          tester.getTopLeft(find.byKey(const ValueKey('content'))).dx;

      expect(contentLeft - rowLeft, moreOrLessEquals(0, epsilon: 0.01));
    });

    testWidgets('reserves a fixed 15px right gap, not scaled by zoom',
        (tester) async {
      Future<double> rightGapAt(double zoom) async {
        await tester.pumpWidget(host(
          LiturgyRow(
            builder: (context, z) =>
                const SizedBox(key: ValueKey('content'), height: 10),
          ),
          zoom: zoom,
        ));
        final rowRight = tester.getTopRight(find.byType(LiturgyRow)).dx;
        final contentRight =
            tester.getTopRight(find.byKey(const ValueKey('content'))).dx;
        return rowRight - contentRight;
      }

      expect(await rightGapAt(100), moreOrLessEquals(15, epsilon: 0.01));
      expect(await rightGapAt(300), moreOrLessEquals(15, epsilon: 0.01),
          reason: 'CLAUDE.md: the right gap is fixed at 15px, never zoomed');
    });
  });
}
