import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zoom is shared by the online liturgy tabs, the Bible and the offline office
/// views, so its clamping and persistence guard all three at once.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts at 100%', () {
    expect(CurrentZoom().value, CurrentZoom.defaultZoom);
    expect(CurrentZoom.defaultZoom, 100.0);
  });

  test('a pinch below the floor clamps to minZoom', () async {
    final zoom = CurrentZoom();
    await pumpEventQueue();

    zoom.updateZoom(10);
    expect(zoom.value, CurrentZoom.minZoom);
  });

  test('a pinch above the ceiling clamps to maxZoom', () async {
    final zoom = CurrentZoom();
    await pumpEventQueue();

    zoom.updateZoom(10000);
    expect(zoom.value, CurrentZoom.maxZoom);
  });

  test('a value in range is applied verbatim and notifies once', () async {
    final zoom = CurrentZoom();
    await pumpEventQueue();

    var notifications = 0;
    zoom.addListener(() => notifications++);

    zoom.updateZoom(150);

    expect(zoom.value, 150.0);
    expect(notifications, 1);
  });

  test('re-setting the same value does not notify', () async {
    final zoom = CurrentZoom();
    await pumpEventQueue();
    zoom.updateZoom(150);

    var notifications = 0;
    zoom.addListener(() => notifications++);

    zoom.updateZoom(150);

    expect(notifications, 0, reason: 'no rebuild for an unchanged zoom');
  });

  test('clamping twice at the same bound does not re-notify', () async {
    final zoom = CurrentZoom();
    await pumpEventQueue();
    zoom.updateZoom(10);

    var notifications = 0;
    zoom.addListener(() => notifications++);

    zoom.updateZoom(5);

    expect(zoom.value, CurrentZoom.minZoom);
    expect(notifications, 0);
  });

  test('a stored zoom is restored on startup', () async {
    SharedPreferences.setMockInitialValues({CurrentZoom.keyCurrentZoom: 175.0});

    final zoom = CurrentZoom();
    await pumpEventQueue();

    expect(zoom.value, 175.0);
  });

  test('a stored out-of-range zoom is clamped on startup', () async {
    SharedPreferences.setMockInitialValues(
        {CurrentZoom.keyCurrentZoom: 5000.0});

    final zoom = CurrentZoom();
    await pumpEventQueue();

    expect(zoom.value, CurrentZoom.maxZoom);
  });

  test('a new zoom is persisted for the next launch', () async {
    final zoom = CurrentZoom();
    await pumpEventQueue();

    zoom.updateZoom(125);
    await pumpEventQueue();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(CurrentZoom.keyCurrentZoom), 125.0);
  });
}
