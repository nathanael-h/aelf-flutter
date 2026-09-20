import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AelfLiturgicalColors.resolve', () {
    final colors = AelfLiturgicalColors.lightColors;

    test('accepts the French names the online API sends', () {
      expect(colors.resolve('blanc'), colors.white);
      expect(colors.resolve('vert'), colors.green);
      expect(colors.resolve('rouge'), colors.red);
      expect(colors.resolve('violet'), colors.purple);
      expect(colors.resolve('rose'), colors.pink);
      expect(colors.resolve('noir'), colors.black);
    });

    test('accepts the English names offline_liturgy sends', () {
      expect(colors.resolve('white'), colors.white);
      expect(colors.resolve('green'), colors.green);
      expect(colors.resolve('red'), colors.red);
      expect(colors.resolve('purple'), colors.purple);
      expect(colors.resolve('pink'), colors.pink);
      expect(colors.resolve('black'), colors.black);
    });

    test('both sources agree on the same colour for the same day', () {
      expect(colors.resolve('rouge'), colors.resolve('red'));
      expect(colors.resolve('blanc'), colors.resolve('white'));
      expect(colors.resolve('vert'), colors.resolve('green'));
    });

    test('is case and whitespace insensitive', () {
      expect(colors.resolve('  ROUGE '), colors.red);
      expect(colors.resolve('Green'), colors.green);
    });

    test('unknown and null resolve to the transparent "unknown" colour', () {
      expect(colors.resolve('fuchsia'), colors.unknown);
      expect(colors.resolve(null), colors.unknown);
      expect(colors.unknown.a, 0, reason: 'unknown must be fully transparent');
    });

    test('of() falls back to the brightness-matched palette', () {
      expect(AelfLiturgicalColors.of(ThemeData(brightness: Brightness.light)),
          AelfLiturgicalColors.lightColors);
      expect(AelfLiturgicalColors.of(ThemeData(brightness: Brightness.dark)),
          AelfLiturgicalColors.darkColors);
    });

    test('of() prefers the extension carried by the app themes', () {
      expect(AelfLiturgicalColors.of(light), AelfLiturgicalColors.lightColors);
      expect(AelfLiturgicalColors.of(dark), AelfLiturgicalColors.darkColors);
    });
  });

  group('getLiturgicalColor', () {
    test('maps the English names used by the offline calendar view', () {
      expect(getLiturgicalColor('white'), Colors.white);
      expect(getLiturgicalColor('red'), Colors.red.shade700);
      expect(getLiturgicalColor('green'), Colors.green.shade700);
      expect(getLiturgicalColor('violet'), Colors.purple.shade700);
      expect(getLiturgicalColor('rose'), Colors.pink.shade300);
      expect(getLiturgicalColor('pink'), Colors.pink.shade300);
      expect(getLiturgicalColor('gold'), Colors.amber.shade700);
      expect(getLiturgicalColor('yellow'), Colors.amber.shade700);
    });

    test('is case insensitive', () {
      expect(getLiturgicalColor('WHITE'), Colors.white);
    });

    test('null and unknown fall back to grey', () {
      expect(getLiturgicalColor(null), Colors.grey);
      expect(getLiturgicalColor('mauve'), Colors.grey);
    });
  });
}
