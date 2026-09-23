import 'package:aelf_flutter/utils/settings.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The theme is shared by both liturgies: the online tabs, the offline office
/// views, the Bible and the drawer all read their colours and fonts from here.
/// A change made for one path lands on all of them, which is exactly why it
/// needs pinning.
///
/// The two [ThemeExtension]s are the load-bearing part. Widgets reach them
/// through `AelfLectureColors.of` / `AelfLiturgicalColors.of`, which fall back
/// to a hardcoded palette when the extension is missing — so forgetting to
/// register one on a theme degrades silently rather than failing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('both app themes carry both extensions', () {
    test('light', () {
      expect(light.extension<AelfLectureColors>(), isNotNull,
          reason: 'without it, of() silently falls back to the light palette');
      expect(light.extension<AelfLiturgicalColors>(), isNotNull);
      expect(light.brightness, Brightness.light);
    });

    test('dark', () {
      expect(dark.extension<AelfLectureColors>(), isNotNull);
      expect(dark.extension<AelfLiturgicalColors>(), isNotNull);
      expect(dark.brightness, Brightness.dark);
    });

    test('each theme carries its own palette, not the other one', () {
      expect(AelfLectureColors.of(light), AelfLectureColors.lightColors);
      expect(AelfLectureColors.of(dark), AelfLectureColors.darkColors);
      expect(AelfLiturgicalColors.of(light), AelfLiturgicalColors.lightColors);
      expect(AelfLiturgicalColors.of(dark), AelfLiturgicalColors.darkColors);
    });

    test('the light and dark lecture palettes really differ', () {
      expect(AelfLectureColors.lightColors.background,
          isNot(AelfLectureColors.darkColors.background));
      expect(AelfLectureColors.lightColors.text,
          isNot(AelfLectureColors.darkColors.text));
    });

    test('green and red are the two liturgical colours that differ by theme',
        () {
      const lightColors = AelfLiturgicalColors.lightColors;
      const darkColors = AelfLiturgicalColors.darkColors;

      expect(lightColors.green, isNot(darkColors.green));
      expect(lightColors.red, isNot(darkColors.red));
      // The rest are shared, so a feast looks the same in both themes.
      expect(lightColors.white, darkColors.white);
      expect(lightColors.purple, darkColors.purple);
      expect(lightColors.pink, darkColors.pink);
      expect(lightColors.black, darkColors.black);
      expect(lightColors.unknown, darkColors.unknown);
    });
  });

  group('of() falls back when no extension is registered', () {
    test('by brightness', () {
      final bareLight = ThemeData(brightness: Brightness.light);
      final bareDark = ThemeData(brightness: Brightness.dark);

      expect(AelfLectureColors.of(bareLight), AelfLectureColors.lightColors);
      expect(AelfLectureColors.of(bareDark), AelfLectureColors.darkColors);
      expect(
          AelfLiturgicalColors.of(bareLight), AelfLiturgicalColors.lightColors);
      expect(
          AelfLiturgicalColors.of(bareDark), AelfLiturgicalColors.darkColors);
    });

    test('a registered extension wins over the fallback', () {
      final custom = ThemeData(
        brightness: Brightness.light,
        extensions: const [AelfLectureColors.darkColors],
      );
      expect(AelfLectureColors.of(custom), AelfLectureColors.darkColors);
    });
  });

  group('AelfLectureColors as a ThemeExtension', () {
    test('copyWith replaces only what it is given', () {
      const base = AelfLectureColors.lightColors;
      final copy = base.copyWith(text: const Color(0xFF123456));

      expect(copy.text, const Color(0xFF123456));
      expect(copy.background, base.background);
      expect(copy.backgroundDarker, base.backgroundDarker);
    });

    test('copyWith with nothing is an identical palette', () {
      const base = AelfLectureColors.lightColors;
      final copy = base.copyWith();
      expect(copy.background, base.background);
      expect(copy.backgroundDarker, base.backgroundDarker);
      expect(copy.text, base.text);
    });

    test('lerp interpolates every colour', () {
      const a = AelfLectureColors.lightColors;
      const b = AelfLectureColors.darkColors;

      expect(a.lerp(b, 0).background, a.background);
      expect(a.lerp(b, 1).background, b.background);
      expect(a.lerp(b, 1).text, b.text);
      // Halfway is neither end.
      final mid = a.lerp(b, 0.5);
      expect(mid.background, isNot(a.background));
      expect(mid.background, isNot(b.background));
    });

    test('lerp with null keeps this palette, so a theme swap cannot blank it',
        () {
      const a = AelfLectureColors.lightColors;
      expect(a.lerp(null, 0.5), same(a));
    });
  });

  group('AelfLiturgicalColors as a ThemeExtension', () {
    test('copyWith replaces only what it is given', () {
      const base = AelfLiturgicalColors.lightColors;
      final copy = base.copyWith(red: const Color(0xFF000001));

      expect(copy.red, const Color(0xFF000001));
      expect(copy.green, base.green);
      expect(copy.unknown, base.unknown);
    });

    test('lerp interpolates every colour', () {
      const a = AelfLiturgicalColors.lightColors;
      const b = AelfLiturgicalColors.darkColors;

      expect(a.lerp(b, 0).green, a.green);
      expect(a.lerp(b, 1).green, b.green);
      expect(a.lerp(b, 1).red, b.red);
    });

    test('lerp with null keeps this palette', () {
      const a = AelfLiturgicalColors.lightColors;
      expect(a.lerp(null, 0.5), same(a));
    });

    test('a lerped palette still resolves names', () {
      // Mid-animation the square must still get a colour, not throw.
      final mid = AelfLiturgicalColors.lightColors
          .lerp(AelfLiturgicalColors.darkColors, 0.5);
      expect(mid.resolve('rouge'), mid.red);
      expect(mid.resolve('inconnu'), mid.unknown);
    });
  });

  group('ThemeNotifier defaults', () {
    test('starts in dark mode', () async {
      final notifier = ThemeNotifier();
      await pumpEventQueue();

      expect(notifier.darkTheme, isTrue,
          reason: 'the app has always opened dark; changing it is a product '
              'decision, not an accident');
      expect(notifier.currentTheme.brightness, Brightness.dark);
    });

    test('starts with the serif font', () async {
      final notifier = ThemeNotifier();
      expect(notifier.serifFont, isTrue,
          reason: 'the synchronous initial value matches the stored default');
      await pumpEventQueue();

      expect(notifier.serifFont, isTrue);
      expect(notifier.currentTheme.textTheme.bodyMedium?.fontFamily,
          'LibertinusSerif');
    });

    test('restores a stored sans-serif preference', () async {
      SharedPreferences.setMockInitialValues({keySerifFont: false});

      final notifier = ThemeNotifier();
      await pumpEventQueue();

      expect(notifier.serifFont, isFalse);
      expect(notifier.currentTheme.textTheme.bodyMedium?.fontFamily,
          'SourceSans3');
    });

    test('restores a stored light-mode preference', () async {
      SharedPreferences.setMockInitialValues({'theme': false});

      final notifier = ThemeNotifier();
      await pumpEventQueue();

      expect(notifier.darkTheme, isFalse);
      expect(notifier.currentTheme.brightness, Brightness.light);
    });

    test('restores a stored serif preference, shared with the settings screen',
        () async {
      SharedPreferences.setMockInitialValues({keySerifFont: true});

      final notifier = ThemeNotifier();
      await pumpEventQueue();

      expect(notifier.serifFont, isTrue);
    });
  });

  group('ThemeNotifier toggles', () {
    // Start from the sans-serif font so every toggle has a known direction.
    setUp(() => SharedPreferences.setMockInitialValues({keySerifFont: false}));

    test('toggleTheme flips brightness, notifies and persists', () async {
      final notifier = ThemeNotifier();
      await pumpEventQueue();

      var notifications = 0;
      notifier.addListener(() => notifications++);

      notifier.toggleTheme();
      await pumpEventQueue();

      expect(notifier.darkTheme, isFalse);
      expect(notifier.currentTheme.brightness, Brightness.light);
      expect(notifications, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('theme'), isFalse);
    });

    test('toggleSerifFont swaps the font family across the text theme',
        () async {
      final notifier = ThemeNotifier();
      await pumpEventQueue();

      notifier.toggleSerifFont();
      await pumpEventQueue();

      expect(notifier.serifFont, isTrue);
      expect(await getSerifFont(), isTrue,
          reason: 'the settings screen reads the same key');

      final textTheme = notifier.currentTheme.textTheme;
      for (final style in [
        textTheme.bodySmall,
        textTheme.bodyMedium,
        textTheme.bodyLarge,
        textTheme.titleMedium,
        textTheme.headlineSmall,
      ]) {
        expect(style?.fontFamily, 'LibertinusSerif');
      }
    });

    test('the serif theme enables the ligature features', () async {
      final notifier = ThemeNotifier();
      await pumpEventQueue();
      notifier.toggleSerifFont();

      final features =
          notifier.currentTheme.textTheme.bodyMedium?.fontFeatures ?? [];
      expect(features.map((f) => f.feature), containsAll(['liga', 'calt']));
    });

    test('toggling back restores the sans-serif font', () async {
      final notifier = ThemeNotifier();
      await pumpEventQueue();

      notifier.toggleSerifFont();
      notifier.toggleSerifFont();
      await pumpEventQueue();

      expect(notifier.serifFont, isFalse);
      expect(notifier.currentTheme.textTheme.bodyMedium?.fontFamily,
          'SourceSans3');
    });

    test('the two toggles are independent', () async {
      final notifier = ThemeNotifier();
      await pumpEventQueue();

      notifier.toggleSerifFont();
      await pumpEventQueue();

      expect(notifier.serifFont, isTrue);
      expect(notifier.darkTheme, isTrue,
          reason: 'changing the font must not change the theme');

      notifier.toggleTheme();
      await pumpEventQueue();

      expect(notifier.darkTheme, isFalse);
      expect(notifier.serifFont, isTrue,
          reason: 'changing the theme must not change the font');
    });
  });

  group('currentTheme keeps everything the widgets depend on', () {
    // Start from the sans-serif font so every toggle has a known direction.
    setUp(() => SharedPreferences.setMockInitialValues({keySerifFont: false}));

    test('the extensions survive the font override', () async {
      // currentTheme rebuilds the theme through copyWith; dropping the
      // extensions there would silently change every liturgical colour.
      for (final serif in [false, true]) {
        final notifier = ThemeNotifier();
        await pumpEventQueue();
        if (serif) notifier.toggleSerifFont();

        final theme = notifier.currentTheme;
        expect(theme.extension<AelfLectureColors>(), isNotNull,
            reason: 'serif=$serif');
        expect(theme.extension<AelfLiturgicalColors>(), isNotNull,
            reason: 'serif=$serif');
      }
    });

    test('text colours are preserved when the font changes', () async {
      final notifier = ThemeNotifier();
      await pumpEventQueue();

      final sansColor = notifier.currentTheme.textTheme.bodyMedium?.color;
      notifier.toggleSerifFont();
      final serifColor = notifier.currentTheme.textTheme.bodyMedium?.color;

      expect(serifColor, sansColor,
          reason: 'the font switch must not restyle the text colour');
    });

    test('the brand red stays the secondary colour in both themes', () async {
      // Verse numbers, antiphon labels and the R/ V/ marks all use it.
      expect(light.colorScheme.secondary, const Color(0xFFBF2328));
      expect(dark.colorScheme.secondary, const Color(0xFFf9787e));
    });
  });
}
