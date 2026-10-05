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

  /// 50 blocks whose height follows the zoom, like the office texts. With
  /// [withScores], each block is preceded by a fixed 100 px box standing for
  /// a psalm tone score, and the content is a lazy [SliverList] like the
  /// office scroll views.
  Future<(CurrentZoom, ScrollController)> pumpArea(WidgetTester tester,
      {bool withScores = false}) async {
    final zoom = CurrentZoom();
    await tester.runAsync(() => pumpEventQueue());
    late ScrollController controller;
    List<Widget> blocks(double zoom) => [
          for (var i = 0; i < 50; i++) ...[
            if (withScores)
              SizedBox(
                  key: ValueKey('score $i'),
                  width: double.infinity,
                  height: 100,
                  child: const ColoredBox(color: Colors.grey)),
            SizedBox(
                width: double.infinity, height: zoom, child: Text('Block $i')),
          ],
        ];
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentZoom>.value(
        value: zoom,
        child: MaterialApp(
          home: Scaffold(
            body: PinchZoomSelectionArea.scrollAnchored(
              builder: (context, scrollController) {
                controller = scrollController;
                return Consumer<CurrentZoom>(
                  builder: (context, zoom, _) => withScores
                      ? CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverList(
                                delegate: SliverChildListDelegate(
                                    blocks(zoom.value))),
                          ],
                        )
                      : SingleChildScrollView(
                          controller: scrollController,
                          child: Column(children: blocks(zoom.value)),
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

  /// Pinches around [focal], spreading the fingers from 100 to 150 px.
  Future<void> pinchAround(WidgetTester tester, Offset focal) async {
    final first = await tester.startGesture(focal - const Offset(0, 50));
    final second = await tester.startGesture(focal + const Offset(0, 50));
    await tester.pump();
    await first.moveBy(const Offset(0, -25));
    await second.moveBy(const Offset(0, 25));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();
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

  testWidgets('a fixed-size score under the fingers stays put', (tester) async {
    final (zoom, controller) = await pumpArea(tester, withScores: true);
    controller.jumpTo(1000);
    await tester.pump();

    final score = find.byKey(const ValueKey('score 6'));
    final before = tester.getTopLeft(score).dy;
    await pinchAround(tester, Offset(200, before + 60));

    expect(zoom.value, 150);
    expect(tester.getTopLeft(score).dy, moreOrLessEquals(before));
  });

  testWidgets('text below fixed-size scores stays under the fingers',
      (tester) async {
    final (zoom, controller) = await pumpArea(tester, withScores: true);
    controller.jumpTo(1000);
    await tester.pump();

    // Several unscaled scores sit above this block: a uniform rescale of
    // the offset would drift by 50 px per score.
    final text = find.text('Block 6');
    final before = tester.getTopLeft(text).dy;
    await pinchAround(tester, Offset(20, before + 5));

    expect(zoom.value, 150);
    expect(tester.getTopLeft(text).dy, moreOrLessEquals(before));
  });

  /// A score (fixed 100 px) followed by a block whose height follows the
  /// zoom, repeated [count] times and labelled with [prefix].
  List<Widget> scoredBlocks(String prefix, double zoom, {int count = 30}) => [
        for (var i = 0; i < count; i++) ...[
          const SizedBox(
              width: double.infinity,
              height: 100,
              child: ColoredBox(color: Colors.grey)),
          SizedBox(
              width: double.infinity, height: zoom, child: Text('$prefix $i')),
        ],
      ];

  Future<CurrentZoom> pumpChild(WidgetTester tester, Widget child,
      {bool selectable = true}) async {
    final zoom = CurrentZoom();
    await tester.runAsync(() => pumpEventQueue());
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentZoom>.value(
        value: zoom,
        child: MaterialApp(
          home: Scaffold(
            body: PinchZoomSelectionArea(selectable: selectable, child: child),
          ),
        ),
      ),
    );
    return zoom;
  }

  testWidgets('tabs: the visible tab is anchored, not its kept-alive siblings',
      (tester) async {
    final controller = TabController(length: 3, vsync: const TestVSync());
    final zoom = await pumpChild(
      tester,
      Consumer<CurrentZoom>(
        builder: (context, zoom, _) => TabBarView(
          controller: controller,
          children: [
            for (final tab in ['A', 'B', 'C'])
              ListView(children: scoredBlocks('Tab $tab', zoom.value)),
          ],
        ),
      ),
    );
    controller.index = 1;
    await tester.pumpAndSettle();
    await tester.drag(find.text('Tab B 2'), const Offset(0, -500));
    await tester.pumpAndSettle();

    final text = find.text('Tab B 4');
    final before = tester.getTopLeft(text).dy;
    await pinchAround(tester, Offset(20, before + 5));

    expect(zoom.value, 150);
    expect(tester.getTopLeft(text).dy, moreOrLessEquals(before));
  });

  testWidgets('Bible: the chapter page scroll view is anchored',
      (tester) async {
    final zoom = await pumpChild(
      tester,
      selectable: false,
      Consumer<CurrentZoom>(
        builder: (context, zoom, _) => PageView(
          children: [
            for (final chapter in ['1', '2'])
              SingleChildScrollView(
                // Like BibleHtmlView: a non-scrolling inner list, which must
                // not pick up the primary controller.
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: scoredBlocks('Chapter $chapter', zoom.value),
                ),
              ),
          ],
        ),
      ),
    );
    await tester.drag(find.text('Chapter 1 2'), const Offset(0, -500));
    await tester.pumpAndSettle();

    final text = find.text('Chapter 1 4');
    final before = tester.getTopLeft(text).dy;
    await pinchAround(tester, Offset(20, before + 5));

    expect(zoom.value, 150);
    expect(tester.getTopLeft(text).dy, moreOrLessEquals(before));
    expect(tester.takeException(), isNull);
  });
}
