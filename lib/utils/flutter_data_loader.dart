import 'package:flutter/services.dart';
import 'package:offline_liturgy/tools/data_loader.dart';

/// Flutter implementation of the DataLoader.
/// It bridges the Dart package logic with Flutter's asset system.
class FlutterDataLoader extends DataLoader {
  static const _assetPrefix = 'packages/offline_liturgy/assets/';

  /// Every asset key the bundle holds, read from the manifest once and kept
  /// (it cannot change while the app runs). Only cached on success, so a
  /// failed read is retried rather than remembered as "no assets at all".
  static Set<String>? _assetKeys;

  static Future<Set<String>> _keys() async {
    final cached = _assetKeys;
    if (cached != null) return cached;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return _assetKeys = manifest.listAssets().toSet();
  }

  @override
  Future<String> load(String relativePath) async {
    final key = '$_assetPrefix$relativePath';
    try {
      // A miss is normal: resolveOfficeContent asks for the French, Hebrew
      // and Greek text of every psalm, and a psalm has no Greek original —
      // only the New Testament canticles do. Asking the bundle for an asset
      // that isn't there throws, and Flutter also hands that error to
      // FlutterError.onError, which fails whichever integration test it
      // lands in. The manifest answers the same question without throwing.
      if (!(await _keys()).contains(key)) return '';
      return await rootBundle.loadString(key);
    } catch (_) {
      return '';
    }
  }

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
