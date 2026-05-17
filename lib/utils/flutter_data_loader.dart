import 'package:flutter/services.dart';
import 'package:offline_liturgy/tools/data_loader.dart';

/// Flutter implementation of the DataLoader.
/// It bridges the Dart package logic with Flutter's asset system.
class FlutterDataLoader implements DataLoader {
  static const _assetPrefix = 'packages/offline_liturgy/assets/';

  @override
  Future<String> load(String relativePath) async {
    try {
      return await rootBundle.loadString('$_assetPrefix$relativePath');
    } catch (_) {
      return '';
    }
  }

  @override
  Future<String> loadJson(String relativePath) => load(relativePath);

  @override
  Future<String> loadYaml(String relativePath) => load(relativePath);

  /// Lists filenames (basename only) under [prefix] in the package's assets,
  /// using Flutter's built-in AssetManifest — no hand-maintained manifest needed.
  @override
  Future<List<String>> listFiles(String prefix) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final fullPrefix = '$_assetPrefix$prefix';
    return manifest
        .listAssets()
        .where((p) => p.startsWith(fullPrefix) && p.endsWith('.yaml'))
        .map((p) => p.split('/').last)
        .toList();
  }
}
