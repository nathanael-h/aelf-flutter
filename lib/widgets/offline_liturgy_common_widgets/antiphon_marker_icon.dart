import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// Identifies which antiphon-marker glyph to display: a single antiphon,
/// its position among 2-3 antiphons on a psalm, or the liturgical-year
/// antiphon of an evangelical canticle.
enum AntiphonMarker { single, first, second, third, yearA, yearB, yearC }

const Map<AntiphonMarker, String> _markerGlyphs = {
  AntiphonMarker.single: '',
  AntiphonMarker.first: '',
  AntiphonMarker.second: '',
  AntiphonMarker.third: '',
  AntiphonMarker.yearA: '',
  AntiphonMarker.yearB: '',
  AntiphonMarker.yearC: '',
};

/// Small glyph ("Ant.", "Ant. 1"...) displayed in the left column of a
/// [LiturgyRow], rendered from the LiturgicalSymbols font alongside the
/// R/, V/ marks (see docs/liturgical-symbols-font.md) instead of the
/// previous per-marker SVG assets.
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

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Text(
      _markerGlyphs[marker]!,
      style: TextStyle(
        fontFamily: 'LiturgicalSymbols',
        color: secondaryColor,
        fontSize: fontSize * _glyphScale * zoom / 100,
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
