import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';

/// Width of the invisible left column used to align prose content with
/// psalm verse text (see [LiturgyRowLeft.indent]). Shared with any content
/// that needs to line up with [LiturgyRow] without going through it
/// directly (e.g. [PsalmToneWidget]'s SVG score).
double liturgyRowIndentWidth(double zoom) => 10.0 + verseFontSize * zoom / 100;

sealed class LiturgyRowLeft {
  const LiturgyRowLeft();

  static const indent = _LiturgyRowLeftIndent();
  static const none = _LiturgyRowLeftNone();
  static LiturgyRowLeft widget(Widget w) => _LiturgyRowLeftWidget(w);
}

final class _LiturgyRowLeftIndent extends LiturgyRowLeft {
  const _LiturgyRowLeftIndent();
}

final class _LiturgyRowLeftNone extends LiturgyRowLeft {
  const _LiturgyRowLeftNone();
}

final class _LiturgyRowLeftWidget extends LiturgyRowLeft {
  final Widget child;
  const _LiturgyRowLeftWidget(this.child);
}

/// Reusable row used across liturgy parts to display the
/// verse id placeholder and the main content area.
///
/// The [builder] receives the current zoom value so callers
/// can build text/styles using that value.
///
/// [left] controls the left column:
/// - [LiturgyRowLeft.indent] (default): empty spacer to align with psalm verse text
/// - [LiturgyRowLeft.none]: no left column, content spans full width
/// - [LiturgyRowLeft.widget(w)]: custom widget (e.g. a coloured bullet) in the left column
class LiturgyRow extends StatelessWidget {
  final Widget Function(BuildContext context, double? zoom) builder;
  final EdgeInsets? padding;
  final LiturgyRowLeft left;

  const LiturgyRow({
    required this.builder,
    this.padding,
    this.left = LiturgyRowLeft.indent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoomValue = currentZoom.value;
        final placeholderWidth = liturgyRowIndentWidth(zoomValue);
        return Row(children: [
          Expanded(
            child: Row(
              children: [
                switch (left) {
                  _LiturgyRowLeftIndent() =>
                    verseIdPlaceholder(zoom: zoomValue),
                  _LiturgyRowLeftNone() => const SizedBox.shrink(),
                  _LiturgyRowLeftWidget(:final child) => SizedBox(
                      width: placeholderWidth,
                      child: Center(child: child),
                    ),
                },
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
