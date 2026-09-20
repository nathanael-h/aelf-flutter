// Dev helper: prints what the online parsers produce from each fixture, so the
// tests can assert against real behaviour rather than assumed behaviour.
// Run: dart --packages=.dart_tool/package_config.json run tool/describe_fixtures.dart
import 'dart:convert';
import 'dart:io';

import 'package:aelf_flutter/parsers/liturgy_parser_service.dart';

void main() {
  for (final name in [
    'mass_single.json',
    'mass_multiple.json',
    'office_laudes.json',
    'office_lectures.json',
    'office_vepres.json',
    'office_complies.json',
    'informations.json',
    'informations_weekday.json',
  ]) {
    final payload =
        json.decode(File('test/fixtures/$name').readAsStringSync()) as Map;
    final r = LiturgyParserService.parse(payload);
    print('=== $name  (${r.length} tabs, massPositions=${r.massPositions})');
    for (var i = 0; i < r.length; i++) {
      final t = r.tabData[i];
      String s(String? v, [int n = 46]) {
        if (v == null) return 'null';
        final one = v.replaceAll('\n', ' ');
        return one.length <= n ? one : '${one.substring(0, n)}…';
      }

      print('  [$i] title=${s(t.title, 34)}');
      if (t.contentTitle != null)
        print('      contentTitle=${s(t.contentTitle)}');
      if (t.ref.isNotEmpty) print('      ref=${s(t.ref)}');
      if (t.subtitle.isNotEmpty) print('      subtitle=${s(t.subtitle)}');
      if (t.intro.isNotEmpty) print('      intro=${s(t.intro)}');
      if (t.introRef.isNotEmpty) print('      introRef=${s(t.introRef)}');
      print(
          '      repeatSubtitle=${t.repeatSubtitle} contentLen=${t.content.length}');
    }
  }
}
