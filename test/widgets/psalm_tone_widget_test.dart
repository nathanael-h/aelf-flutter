import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A score is sized from the width it actually gets, not from the screen
/// width: otherwise a score wider than its column keeps the height computed
/// for the larger width while its drawing is shrunk to fit, leaving blank
/// space above and below it (e.g. next to the side menu, or with full-screen
/// margins).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const wideScore = '<svg xmlns="http://www.w3.org/2000/svg" width="1000" '
      'height="100" viewBox="0 0 1000 100"><rect width="1000" height="100"/>'
      '</svg>';

  testWidgets('a score wider than its column keeps its proportions',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              // Much narrower than the 800 px test screen.
              child: SizedBox(
                width: 400,
                child: PsalmToneWidget(svgData: [wideScore]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final score = tester.getSize(find.byType(SvgPicture));
    expect(score.width, lessThan(400));
    // The score box keeps the 10:1 ratio of the SVG: sized from the screen
    // width, it was 759 x 75.9 px squeezed to 359 px wide, the drawing
    // centred with ~20 px of blank above and below.
    expect(score.height, moreOrLessEquals(score.width / 10, epsilon: 0.5));
  });
}
