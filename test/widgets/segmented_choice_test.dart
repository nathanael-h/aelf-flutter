import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/choice_selectors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The invitatory psalm's choice: its segments stop growing on a wide
/// screen, centered, and still share a phone's width.
void main() {
  const labels = ['Psaume 94', 'Psaume 99', 'Psaume 66', 'Psaume 23'];

  Future<Rect> layout(WidgetTester tester, double screenWidth,
      {double zoom = 100}) async {
    tester.view.physicalSize = Size(screenWidth, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CurrentZoom()..updateZoom(zoom),
        child: MaterialApp(
          home: Scaffold(
            body: SegmentedChoice(
                labels: labels, selectedIndex: 0, onSelected: (_) {}),
          ),
        ),
      ),
    );
    return tester.getRect(find
        .descendant(
            of: find.byType(SegmentedChoice), matching: find.byType(Row))
        .first);
  }

  testWidgets('no wider than its segments on a wide screen', (tester) async {
    final rect = await layout(tester, 1000);
    expect(rect.width, lessThanOrEqualTo(4 * SegmentedChoice.maxSegmentWidth));
    expect(rect.center.dx, 500);
  });

  testWidgets('wider with the zoom', (tester) async {
    final rect = await layout(tester, 1000, zoom: 150);
    expect(rect.width, greaterThan(4 * SegmentedChoice.maxSegmentWidth));
  });

  testWidgets("the phone's width when narrower", (tester) async {
    final rect = await layout(tester, 320);
    expect(rect.width, 320 - 2 * 16 - 2);
  });
}
