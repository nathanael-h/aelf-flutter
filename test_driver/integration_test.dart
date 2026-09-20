import 'package:integration_test/integration_test_driver.dart';

/// Driver entry point for `flutter drive`.
///
/// The suite normally runs with `flutter test integration_test -d <device>`,
/// which needs no driver. This file exists for the cases that do: capturing
/// screenshots, or driving a device that only `flutter drive` can reach.
///
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/online_liturgy_test.dart \
///     -d DEVICE_ID
Future<void> main() => integrationDriver();
