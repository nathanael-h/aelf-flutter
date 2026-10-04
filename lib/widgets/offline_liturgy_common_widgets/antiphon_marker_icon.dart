import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// Identifies which antiphon marker to display: the A/ glyph, optionally
/// followed by a subscript index — a position among several antiphons
/// ("1", "2"... with no upper bound) or a liturgical year ("A", "B", "C").
class AntiphonMarker {
  /// Subscript shown after the A/ glyph, or null for a single antiphon.
  final String? index;

  const AntiphonMarker._(this.index);

  AntiphonMarker.numbered(int n) : index = '$n';

  static const single = AntiphonMarker._(null);
  static const first = AntiphonMarker._('1');
  static const second = AntiphonMarker._('2');
  static const third = AntiphonMarker._('3');
  static const yearA = AntiphonMarker._('A');
  static const yearB = AntiphonMarker._('B');
  static const yearC = AntiphonMarker._('C');
}

/// A/ antiphon glyph (U+E001) of the LiturgicalSymbols font.
const String _antiphonGlyph = '\uE001';

/// Small "A/" mark displayed in the left column of a [LiturgyRow], rendered
/// from the LiturgicalSymbols font (see docs/liturgical-symbols-font.md),
/// with the marker's index drawn as a subscript in Libertinus Serif — the
/// font the LiturgicalSymbols letterforms come from.
class AntiphonMarkerIcon extends StatelessWidget {
  const AntiphonMarkerIcon({
    super.key,
    required this.marker,
    required this.fontSize,
    this.lineHeight = 1.2,
  });

  final AntiphonMarker marker;

  /// Base font size (pre-zoom) of the antiphon text this marker precedes,
  /// so the glyph scales with it instead of using an independent constant.
  final double fontSize;

  /// The `height` multiplier used by the antiphon text this marker precedes.
  final double lineHeight;

  static const _glyphScale = 0.85;

  /// Subscript size and downward shift, relative to the glyph's font size.
  static const _subscriptScale = 0.7;
  static const _subscriptDrop = 0.2;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final glyphSize = fontSize * _glyphScale * zoom / 100;
    final index = marker.index;

    return Text.rich(
      TextSpan(
        text: _antiphonGlyph,
        children: [
          if (index != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              // Transform shifts the subscript down without enlarging the
              // line box, so the glyph's top alignment is unaffected.
              child: Transform.translate(
                offset: Offset(0, glyphSize * _subscriptDrop),
                child: Text(
                  index,
                  style: TextStyle(
                    fontFamily: 'LibertinusSerif',
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                    fontSize: glyphSize * _subscriptScale,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
      style: TextStyle(
        fontFamily: 'LiturgicalSymbols',
        color: secondaryColor,
        fontSize: glyphSize,
        // The marker is rendered smaller than the antiphon text, so its own
        // line box is shorter too. Since it's positioned with topCenter
        // (flush with the top of the row, not baseline-aligned), a shorter
        // box would visually pull the glyph upward relative to the
        // antiphon's first line. Forcing the same line-box height as the
        // antiphon text (fontSize * lineHeight) keeps the top position
        // — and therefore the glyph — aligned regardless of its font size.
        height: lineHeight / _glyphScale,
      ),
    );
  }
}
