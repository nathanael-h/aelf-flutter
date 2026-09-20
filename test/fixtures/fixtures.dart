import 'dart:convert';
import 'dart:io';

/// Loads an AELF API fixture from `test/fixtures/`.
///
/// `flutter test` runs with the package root as the working directory, so the
/// relative path is stable both locally and on CI.
Map<String, dynamic> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  if (!file.existsSync()) {
    throw StateError('Missing fixture: ${file.path}');
  }
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}
