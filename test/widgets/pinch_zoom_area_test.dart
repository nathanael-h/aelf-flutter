import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pinch-to-zoom used to lose the gesture arena to the scroll view as soon as
/// the first finger moved before the second one landed. These tests drive raw
/// pointers to check that a pinch is recognised whatever the finger order,
/// that the zoom is only applied once the pinch ends, and that the text under
/// the fingers stays in place.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// 50 blocks whose height follows the zoom, like the office texts.
  Future<(CurrentZoom, ScrollController)> pumpArea(WidgetTester tester) async {
    final zoom = CurrentZoom();
    await tester.runAsync(() => pumpEventQueue());
    late ScrollController controller;
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentZoom>.value(
        value: zoom,
        child: MaterialApp(
          home: Scaffold(
            body: PinchZoomSelectionArea.scrollAnchored(
              builder: (context, scrollController) {
                controller = scrollController;
                return Consumer<CurrentZoom>(
                  builder: (context, zoom, _) => SingleChildScrollView(
                    controller: scrollController,
                    child: Column(children: [
                      for (var i = 0; i < 50; i++)
                        SizedBox(
                            width: double.infinity,
                            height: zoom.value,
                            child: Text('Block $i')),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    return (zoom, controller);
  }

  testWidgets('a pinch wins even after the first finger started scrolling',
      (tester) async {
    final (zoom, controller) = await pumpArea(tester);
    controller.jumpTo(1000);
    await tester.pump();

    final first = await tester.startGesture(const Offset(200, 300));
    // The first move only crosses the touch slop; the second one scrolls.
    await first.moveBy(const Offset(0, -40));
    await first.moveBy(const Offset(0, -40));
    await tester.pump();
    final scrolledTo = controller.offset;
    expect(scrolledTo, greaterThan(1000), reason: 'the first finger scrolls');

    final second = await tester.startGesture(const Offset(200, 320));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await first.moveBy(const Offset(0, -5));
      await second.moveBy(const Offset(0, 5));
      await tester.pump();
    }

    expect(controller.offset, scrolledTo,
        reason: 'two fingers down lock scrolling');
    expect(zoom.value, 100, reason: 'the zoom only changes at the end');

    await first.up();
    await second.up();
    await tester.pump();

    // Span 100 -> 200: the zoom doubles.
    expect(zoom.value, 200);
  });

  testWidgets('the content under the fingers stays under the fingers',
      (tester) async {
    final (zoom, controller) = await pumpArea(tester);
    controller.jumpTo(1000);
    await tester.pump();

    // Focal point at y = 200; span 100 -> 150.
    final first = await tester.startGesture(const Offset(200, 150));
    final second = await tester.startGesture(const Offset(200, 250));
    await tester.pump();
    await first.moveBy(const Offset(0, -25));
    await second.moveBy(const Offset(0, 25));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(zoom.value, 150);
    expect(controller.offset, (1000 + 200) * 1.5 - 200);
  });

  testWidgets('the new zoom is rounded to 5% and persisted', (tester) async {
    final (zoom, _) = await pumpArea(tester);

    final first = await tester.startGesture(const Offset(200, 150));
    final second = await tester.startGesture(const Offset(200, 250));
    await tester.pump();
    // Span 100 -> 123: 123% rounds to 125%.
    await second.moveBy(const Offset(0, 23));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(zoom.value, 125);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getDouble(CurrentZoom.keyCurrentZoom), 125);
  });

  testWidgets('a two-finger tap leaves the zoom alone', (tester) async {
    final (zoom, _) = await pumpArea(tester);

    final first = await tester.startGesture(const Offset(200, 150));
    final second = await tester.startGesture(const Offset(200, 250));
    await tester.pump();
    await second.moveBy(const Offset(0, 1));
    await first.up();
    await second.up();
    await tester.pump();

    expect(zoom.value, 100);
  });

  testWidgets('scrolling works again once every finger is lifted',
      (tester) async {
    final (_, controller) = await pumpArea(tester);

    final first = await tester.startGesture(const Offset(200, 150));
    final second = await tester.startGesture(const Offset(200, 250));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    await tester.drag(find.text('Block 3'), const Offset(0, -300));
    await tester.pump();
    expect(controller.offset, greaterThan(0));
  });
}
