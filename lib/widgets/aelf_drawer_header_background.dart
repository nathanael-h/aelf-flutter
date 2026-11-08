import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';

/// The shared background of the AELF drawer headers: a solid colour, the
/// darker lecture background of [AelfLectureColors] (also the background of
/// the whole drawer, see `drawerTheme`), closed by a 1dp rule at the bottom.
///
/// The native app (`res/drawable/drawer_header_bg_{light,dark}.xml` in
/// aelf-dailyreadings) draws a radial gradient instead, too faint to be seen.
///
/// Used by both [LeftMenuHeader] (Bible) and `LeftMenuOfficeHeader`
/// (offices/mass) so the two share one background.
class AelfDrawerHeaderBackground extends StatelessWidget {
  const AelfDrawerHeaderBackground({
    super.key,
    required this.child,
    this.minHeight = 160,
  });

  final Widget child;

  /// Native `minHeight`. The Bible header pins its content to exactly this;
  /// the offices header grows past it with its liturgical-options list.
  final double minHeight;

  static const double ruleWidth = 1;

  @override
  Widget build(BuildContext context) {
    final AelfLectureColors colors = AelfLectureColors.of(Theme.of(context));

    // The Bible header's scaled logo overflows the box; the native ViewGroup
    // clips it (clipChildren), so we do the same.
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.backgroundDarker,
          border: Border(
            bottom: BorderSide(color: colors.text, width: ruleWidth),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
