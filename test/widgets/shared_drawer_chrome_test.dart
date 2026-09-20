import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/aelf_drawer_header_background.dart';
import 'package:aelf_flutter/widgets/left_menu_header.dart';
import 'package:aelf_flutter/widgets/material_drawer_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The drawer chrome is shared by every section — Bible, the online offices,
/// the offline ones — and it takes its colours from [AelfLectureColors] rather
/// than from [ColorScheme]. That indirection is easy to break by accident,
/// because `AelfLectureColors.of` falls back to a hardcoded palette instead of
/// failing when the extension is missing.
void main() {
  Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('AelfDrawerHeaderBackground', () {
    testWidgets('paints the gradient from the theme extension', (tester) async {
      await tester.pumpWidget(host(const AelfDrawerHeaderBackground(
        minHeight: 160,
        child: SizedBox(width: 300),
      )));
      await tester.pump();

      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AelfDrawerHeaderBackground),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = decorated.decoration as BoxDecoration;
      final gradient = decoration.gradient as RadialGradient;

      expect(gradient.colors, [
        AelfLectureColors.lightColors.background,
        AelfLectureColors.lightColors.backgroundDarker,
      ]);
      expect(
          decoration.border?.bottom.color, AelfLectureColors.lightColors.text);
    });

    testWidgets('uses the dark palette under the dark theme', (tester) async {
      await tester.pumpWidget(host(
        const AelfDrawerHeaderBackground(
            minHeight: 160, child: SizedBox(width: 300)),
        theme: dark,
      ));
      await tester.pump();

      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AelfDrawerHeaderBackground),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final gradient =
          (decorated.decoration as BoxDecoration).gradient as RadialGradient;

      expect(gradient.colors.first, AelfLectureColors.darkColors.background);
    });

    testWidgets('honours its minimum height', (tester) async {
      await tester.pumpWidget(host(const AelfDrawerHeaderBackground(
        minHeight: 160,
        child: SizedBox(width: 300, height: 10),
      )));
      await tester.pump();

      expect(tester.getSize(find.byType(AelfDrawerHeaderBackground)).height,
          greaterThanOrEqualTo(160));
    });
  });

  group('LeftMenuHeader', () {
    testWidgets('shows its title and subtitle', (tester) async {
      await tester.pumpWidget(host(const LeftMenuHeader(
        title: 'La Bible',
        subtitle: 'Traduction liturgique',
      )));
      await tester.pump();

      expect(find.textContaining('Traduction liturgique'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without a subtitle', (tester) async {
      await tester.pumpWidget(host(const LeftMenuHeader(title: 'La Bible')));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    for (final entry in {'light': light, 'dark': dark}.entries) {
      testWidgets('renders in the ${entry.key} theme', (tester) async {
        await tester.pumpWidget(host(
          const LeftMenuHeader(title: 'La Bible', subtitle: 'Traduction'),
          theme: entry.value,
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('ignores the platform text scale, matching the native layout',
        (tester) async {
      // The native header sizes its text in dp, so it must not grow with the
      // system font setting.
      Future<Size> sizeAt(double scale) async {
        await tester.pumpWidget(MaterialApp(
          theme: light,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Scaffold(
                body:
                    LeftMenuHeader(title: 'La Bible', subtitle: 'Sous-titre')),
          ),
        ));
        await tester.pump();
        return tester.getSize(find.byType(LeftMenuHeader));
      }

      expect(await sizeAt(1.0), await sizeAt(2.0));
    });
  });

  group('MaterialDrawerItem', () {
    testWidgets('an unselected item is transparent', (tester) async {
      await tester.pumpWidget(host(
          const MaterialDrawerItem(listTile: ListTile(title: Text('Laudes')))));
      await tester.pump();

      final material = tester.widget<Material>(find
          .descendant(
            of: find.byType(MaterialDrawerItem),
            matching: find.byType(Material),
          )
          .first);
      expect(material.color, Colors.transparent);
    });

    testWidgets('a selected item is tinted with the secondary colour',
        (tester) async {
      await tester.pumpWidget(host(const MaterialDrawerItem(
          listTile: ListTile(title: Text('Laudes'), selected: true))));
      await tester.pump();

      final material = tester.widget<Material>(find
          .descendant(
            of: find.byType(MaterialDrawerItem),
            matching: find.byType(Material),
          )
          .first);

      expect(
          material.color, light.colorScheme.secondary.withValues(alpha: 0.12));
      expect(material.color, isNot(Colors.transparent));
    });

    testWidgets('the tint follows the theme', (tester) async {
      await tester.pumpWidget(host(
        const MaterialDrawerItem(
            listTile: ListTile(title: Text('Laudes'), selected: true)),
        theme: dark,
      ));
      await tester.pump();

      final material = tester.widget<Material>(find
          .descendant(
            of: find.byType(MaterialDrawerItem),
            matching: find.byType(Material),
          )
          .first);

      expect(
          material.color, dark.colorScheme.secondary.withValues(alpha: 0.12));
    });
  });
}
