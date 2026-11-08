import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/widgets/bible_verse_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A verse number too wide for its column (e.g. `11.17` in the canticles
/// that span two chapters) is shrunk to fit on one line, instead of wrapping
/// and pushing its verse down. In the test font every glyph is 1 em wide, so
/// at zoom 100 `9` (10 px) fits the 21 px column and `11.17` (50 px) does
/// not, and so at any zoom.
void main() {
  Future<void> pumpIds(WidgetTester tester, double zoom) async {
    final fontSize = verseFontSize * zoom / 100;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BibleVerseId(
                key: const ValueKey('short'), id: '9', fontSize: fontSize),
            BibleVerseId(
                key: const ValueKey('long'), id: '11.17', fontSize: fontSize),
          ],
        ),
      ),
    ));
  }

  Rect idRect(WidgetTester tester, String key) =>
      tester.getRect(find.byKey(ValueKey(key)));

  /// The drawn rectangle of the number, shrinking included.
  Rect textRect(WidgetTester tester, String key) => tester.getRect(find
      .descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Text)));

  for (final zoom in [100.0, 300.0]) {
    final column = verseFontSize * zoom / 100 + 5;

    testWidgets('a number that fits keeps its size at $zoom%', (tester) async {
      await pumpIds(tester, zoom);
      final text = textRect(tester, 'short');
      final unscaled = tester.getSize(find.descendant(
          of: find.byKey(const ValueKey('short')),
          matching: find.byType(Text)));
      expect(text.width, moreOrLessEquals(unscaled.width, epsilon: 0.01));
      // Right-aligned in its column.
      expect(
          text.right,
          moreOrLessEquals(idRect(tester, 'short').left + column,
              epsilon: 0.01));
    });

    testWidgets('a number too wide shrinks onto one line at $zoom%',
        (tester) async {
      await pumpIds(tester, zoom);
      final short = idRect(tester, 'short');
      final long = idRect(tester, 'long');
      // Same column, same height as a number that fits: no wrapping.
      expect(long.size, short.size);
      final text = textRect(tester, 'long');
      expect(text.width, moreOrLessEquals(column, epsilon: 0.01));
      expect(text.right, moreOrLessEquals(long.left + column, epsilon: 0.01));
      // Vertically centred on its line.
      expect(text.center.dy, moreOrLessEquals(long.center.dy, epsilon: 0.01));
      expect(tester.takeException(), isNull, reason: 'no overflow');
    });
  }
}
