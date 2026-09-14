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
  const AntiphonMarkerIcon({super.key, required this.marker});

  final AntiphonMarker marker;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Text(
      _markerGlyphs[marker]!,
      style: TextStyle(
        fontFamily: 'LiturgicalSymbols',
        color: secondaryColor,
        fontSize: 15.0 * 0.85 * zoom / 100,
      ),
    );
  }
}
