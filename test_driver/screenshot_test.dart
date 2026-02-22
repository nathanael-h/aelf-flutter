import 'dart:io';
import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart' hide find;

void main() {
  group('Screenshot test', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver.close();
    });

    test('capture screenshot of Complies Offline New', () async {
      // Wait for the app to settle
// Attempt to locate the "Complies Offline New" text
      bool found = false;
      try {
        await driver.waitFor(find.text('Complies Offline New'),
            timeout: const Duration(seconds: 10));
        found = true;
      } catch (_) {
        // ignore
      }
      if (!found) {
        // Small-screen mode: open navigation drawer via tooltip
        await driver.tap(find.byTooltip('Open navigation menu'));
        await driver.waitFor(find.text('Complies Offline New'),
            timeout: const Duration(seconds: 10));
      }
      // Capture screenshot
      final List<int> bytes = await driver.screenshot();
      final file = File('screenshot.png');
      await file.writeAsBytes(bytes);
    });
  });
}
