import 'package:flutter/services.dart';
import 'package:offline_liturgy/tools/data_loader.dart';

/// Flutter implementation of the DataLoader.
/// It bridges the Dart package logic with Flutter's asset system.
class FlutterDataLoader implements DataLoader {
  /// Loads an asset from the Flutter bundle.
  /// Assets must be declared in the pubspec.yaml of the app or the package.
  @override
  Future<String> load(String relativePath) async {
    // The prefix 'packages/offline_liturgy/assets/' is required if the
    // files are stored inside a separate package.
    final path = 'packages/offline_liturgy/assets/$relativePath';

    try {
      // rootBundle.loadString is optimized and handles caching internally.
      return await rootBundle.loadString(path);
    } catch (e) {
      // If the file is missing or not declared in pubspec.yaml,
      // we return an empty string to keep the app running.
      return '';
    }
  }

  /// Redirects JSON calls to the primary load method.
  @override
  Future<String> loadJson(String relativePath) => load(relativePath);

  /// Redirects YAML calls to the primary load method.
  @override
  Future<String> loadYaml(String relativePath) => load(relativePath);
}
