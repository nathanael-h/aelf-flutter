import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';

/// Reusable row used across liturgy parts to display the
/// verse id placeholder and the main content area.
///
/// The builder receives the current zoom value so callers
/// can build text/styles using that value.
///
/// [leftWidget], when provided, replaces the [verseIdPlaceholder] and is
/// centered inside the same fixed-width column. This lets callers place a
/// visual marker (e.g. a coloured square) in the verse-number column while
/// keeping the main content aligned with psalm verse text.
class LiturgyRow extends StatelessWidget {
  final Widget Function(BuildContext context, double? zoom) builder;
  final EdgeInsets? padding;
  final bool hideVerseIdPlaceholder;
  final Widget? leftWidget;

  const LiturgyRow({
    required this.builder,
    this.padding,
    this.hideVerseIdPlaceholder = false,
    this.leftWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoomValue = currentZoom.value;
        final placeholderWidth = 10.0 + verseFontSize * zoomValue / 100;
        return Row(children: [
          Expanded(
            child: Row(
              children: [
                if (leftWidget != null)
                  SizedBox(
                    width: placeholderWidth,
                    child: Center(child: leftWidget),
                  )
                else if (!hideVerseIdPlaceholder)
                  verseIdPlaceholder(zoom: zoomValue),
                Expanded(
                  child: Padding(
                    padding: padding ?? EdgeInsets.zero,
                    child: builder(context, zoomValue),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10, left: 0, right: 15),
                )
              ],
            ),
          ),
        ]);
      },
    );
  }
}
