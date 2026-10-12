import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';

/// Frames a block of antiphons with an [AntiphonSeparator] above and below.
/// Several consecutive antiphons must be passed as a single [child] so the
/// separators only appear before the first and after the last one.
class AntiphonFrame extends StatelessWidget {
  const AntiphonFrame({super.key, required this.child});

  final Widget child;

  /// Gap between a separator and the antiphon text, before zoom.
  static const _innerGap = 4.0;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final gap = _innerGap * zoom / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AntiphonSeparator(),
        SizedBox(height: gap),
        child,
        SizedBox(height: gap),
        const AntiphonSeparator(),
      ],
    );
  }
}

/// Light ornament made of two short hairlines around a small diamond:
/// ───── ◆ ─────
/// Centered on the text column so it lines up with the antiphon text.
class AntiphonSeparator extends StatelessWidget {
  const AntiphonSeparator({super.key});

  static const _lineWidth = 25.0;
  static const _lineThickness = 0.7;
  static const _diamondSize = 4.0;
  static const _diamondGap = 6.0;
  static const _opacity = 0.65;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.secondary.withValues(alpha: _opacity);

    return LiturgyRow(
      builder: (context, zoom) {
        final scale = (zoom ?? 100) / 100;
        final line = Container(
          width: _lineWidth * scale,
          height: _lineThickness,
          color: color,
        );
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              line,
              SizedBox(width: _diamondGap * scale),
              Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: _diamondSize * scale,
                  height: _diamondSize * scale,
                  color: color,
                ),
              ),
              SizedBox(width: _diamondGap * scale),
              line,
            ],
          ),
        );
      },
    );
  }
}
