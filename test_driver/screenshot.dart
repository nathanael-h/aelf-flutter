import 'dart:io';
import 'dart:convert';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

Future<void> main() async {
  // Connect to the Flutter driver.
  final driver = await FlutterDriver.connect();
  try {
    // Give the app some time to load.
    await Future.delayed(const Duration(seconds: 5));
    // Open the navigation drawer.
    final menuButton = find.byTooltip('Open navigation menu');
    await driver.waitFor(menuButton);
    await driver.tap(menuButton);
    // Wait for drawer to open.
    await Future.delayed(const Duration(seconds: 1));
    // Find and tap 'Complies Offline New' item in left menu
    final compliOfflineFinder = find.text('Complies Offline New');
    await driver.waitFor(compliOfflineFinder);
    await driver.tap(compliOfflineFinder);

    await Future.delayed(const Duration(seconds: 2));

    final List<int> pngBytes = await driver.screenshot();
    final file = File('screenshot.png');
    await file.writeAsBytes(pngBytes);
    print('Screenshot saved to screenshot.png');
  } finally {
    driver.close();
  }
}
