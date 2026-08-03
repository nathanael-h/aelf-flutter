import 'dart:math' show min;

import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';

/// The shared background of the AELF drawer headers, ported from
/// `res/drawable/drawer_header_bg_{light,dark}.xml` in aelf-dailyreadings: a
/// radial gradient (centre 0.2/0.2, absolute 300dp radius) closed by a 1dp rule
/// at the bottom. Colours come from [AelfLectureColors].
///
/// Used by both [LeftMenuHeader] (Bible) and `LeftMenuOfficeHeader`
/// (offices/mass) so the two share one background.
class AelfDrawerHeaderBackground extends StatelessWidget {
  const AelfDrawerHeaderBackground({
    super.key,
    required this.child,
    this.minHeight = 160,
    this.gradientReferenceSide = 160,
  });

  final Widget child;

  /// Native `minHeight`. The Bible header pins its content to exactly this;
  /// the offices header grows past it with its liturgical-options list.
  final double minHeight;

  /// The short side used to turn Android's absolute 300dp gradient radius into
  /// Flutter's fraction-of-shortest-side radius. Kept fixed (not measured from
  /// the final height) so both headers scale the gradient identically.
  final double gradientReferenceSide;

  // drawer_header_bg_*.xml
  static const double _gradientRadius = 300;
  static const Alignment _gradientCenter = Alignment(-0.6, -0.6); // 0.2, 0.2
  static const double ruleWidth = 1;

  @override
  Widget build(BuildContext context) {
    final AelfLectureColors colors = AelfLectureColors.of(Theme.of(context));

    // The Bible header's scaled logo overflows the box; the native ViewGroup
    // clips it (clipChildren), so we do the same.
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double shortestSide =
              min(constraints.maxWidth, gradientReferenceSide);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: _gradientCenter,
                radius: _gradientRadius / shortestSide,
                colors: <Color>[colors.background, colors.backgroundDarker],
              ),
              border: Border(
                bottom: BorderSide(color: colors.text, width: ruleWidth),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: SizedBox(width: double.infinity, child: child),
            ),
          );
        },
      ),
    );
  }
}
