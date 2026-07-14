import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/svg_preprocessor.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';

/// Identifies which antiphon-marker glyph to display: a single antiphon,
/// its position among 2-3 antiphons on a psalm, or the liturgical-year
/// antiphon of an evangelical canticle.
enum AntiphonMarker { single, first, second, third, yearA, yearB, yearC }

const Map<AntiphonMarker, String> _markerAssetNames = {
  AntiphonMarker.single: 'antiphon',
  AntiphonMarker.first: 'antiphon1',
  AntiphonMarker.second: 'antiphon2',
  AntiphonMarker.third: 'antiphon3',
  AntiphonMarker.yearA: 'antiphonA',
  AntiphonMarker.yearB: 'antiphonB',
  AntiphonMarker.yearC: 'antiphonC',
};

/// Small SVG glyph ("Ant.", "Ant. 1"...) displayed in the left column of a
/// [LiturgyRow], mirroring how the ℟/℣ liturgical symbols work but for
/// antiphon markers. Raw SVGs live in assets/svg/antiphon*.svg and go
/// through the same [preprocessPsalmSvg] colour substitution as psalm-tone
/// scores, so they always match the app's red/theme colours.
class AntiphonMarkerIcon extends StatefulWidget {
  const AntiphonMarkerIcon({super.key, required this.marker});

  final AntiphonMarker marker;

  @override
  State<AntiphonMarkerIcon> createState() => _AntiphonMarkerIconState();
}

class _AntiphonMarkerIconState extends State<AntiphonMarkerIcon> {
  static final Map<String, String> _rawSvgCache = {};

  static Future<String> _loadRaw(String assetName) async {
    return _rawSvgCache[assetName] ??=
        await rootBundle.loadString('assets/svg/$assetName.svg');
  }

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final themeNotifier = context.watch<ThemeNotifier>();
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final redHex =
        '#${secondaryColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color ??
        Theme.of(context).colorScheme.onSurface;
    final textColorCss = 'rgba('
        '${(bodyColor.r * 255.0).round().clamp(0, 255)}, '
        '${(bodyColor.g * 255.0).round().clamp(0, 255)}, '
        '${(bodyColor.b * 255.0).round().clamp(0, 255)}, '
        '${bodyColor.a.toStringAsFixed(3)})';

    final assetName = _markerAssetNames[widget.marker]!;
    final height = 15.0 * zoom / 100;

    return FutureBuilder<String>(
      future: _loadRaw(assetName),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('AntiphonMarkerIcon: failed to load $assetName: '
              '${snapshot.error}');
        }
        final raw = snapshot.data;
        if (raw == null) return SizedBox(height: height);
        final processed = preprocessPsalmSvg(
          raw,
          textColor: textColorCss,
          serifFont: themeNotifier.serifFont,
          redColor: redHex,
        );
        return SvgPicture.string(processed,
            height: height, fit: BoxFit.contain);
      },
    );
  }
}
