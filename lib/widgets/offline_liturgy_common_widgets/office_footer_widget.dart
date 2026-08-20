import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/svg_preprocessor.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';

/// End-of-office ornament ("assets/svg/footer.svg"), shown at the bottom of
/// a scrolled office or after its last tab. Goes through the same
/// [preprocessPsalmSvg] colour substitution as [AntiphonMarkerIcon] so it
/// always matches the app's red/theme colours.
class OfficeFooterWidget extends StatefulWidget {
  const OfficeFooterWidget({super.key});

  @override
  State<OfficeFooterWidget> createState() => _OfficeFooterWidgetState();
}

class _OfficeFooterWidgetState extends State<OfficeFooterWidget> {
  static String? _rawSvgCache;

  static Future<String> _loadRaw() async {
    return _rawSvgCache ??=
        await rootBundle.loadString('assets/svg/footer.svg');
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

    final height = 15.0 * zoom / 100;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0 * zoom / 100),
      child: FutureBuilder<String>(
        future: _loadRaw(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('OfficeFooterWidget: failed to load footer.svg: '
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
          return Center(
            child: SvgPicture.string(processed,
                height: height, fit: BoxFit.contain),
          );
        },
      ),
    );
  }
}
