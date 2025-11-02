import 'package:flutter/services.dart';
import 'package:offline_liturgy/tools/data_loader.dart';

/// DataLoader for Flutter applications
/// Loads assets from the Flutter bundle using rootBundle
///
/// Files must be declared in the offline_liturgy package's pubspec.yaml:
/// ```yaml
/// flutter:
///   assets:
///     - assets/calendar_data/special_days/
///     - assets/calendar_data/sanctoral/
///     - assets/calendar_data/ferial_days/
///     - assets/calendar_data/commons/
///     - assets/locations.json
/// ```
///
/// Usage in your Flutter app:
/// ```dart
/// final dataLoader = FlutterDataLoader();
/// final complines = await complineDefinitionResolution(calendar, date, dataLoader);
/// ```
class FlutterDataLoader implements DataLoader {
  @override
  Future<String> loadJson(String relativePath) async {
    try {
      // Load from Flutter bundle with package prefix
      return await rootBundle.loadString(
        'packages/offline_liturgy/assets/$relativePath',
      );
    } catch (e) {
      // If file doesn't exist or in case of error, return empty string
      // This allows the caller to gracefully handle missing files
      return '';
    }
  }
}
