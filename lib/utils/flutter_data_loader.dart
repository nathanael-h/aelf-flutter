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
///     - assets/hymns/
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
    // For local packages, Flutter requires the 'packages/' prefix
    final path = 'packages/offline_liturgy/assets/$relativePath';

    try {
      final content = await rootBundle.loadString(path);
      print('✅ Successfully loaded JSON from: $path');
      return content;
    } catch (e) {
      print('❌ Failed to load JSON from: $path - Error: $e');
    }
    return '';
  }

  @override
  Future<String> loadYaml(String relativePath) async {
    // For local packages, Flutter requires the 'packages/' prefix
    final path = 'packages/offline_liturgy/assets/$relativePath';

    try {
      final content = await rootBundle.loadString(path);
      print('✅ Successfully loaded YAML from: $path');
      return content;
    } catch (e) {
      print('❌ Failed to load YAML from: $path - Error: $e');
    }
    return '';
  }
}
