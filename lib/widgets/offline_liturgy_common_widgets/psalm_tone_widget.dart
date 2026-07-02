import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/utils/svg_preprocessor.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';

const double _svgScale = 1;

double _svgTargetWidth(String svg, double maxWidth) {
  final widthMatch = RegExp(r'<svg[^>]*\swidth="([0-9.]+)"').firstMatch(svg);
  double? natural =
      widthMatch != null ? double.tryParse(widthMatch.group(1)!) : null;
  if (natural == null) {
    final vbMatch =
        RegExp(r'viewBox="[0-9.]+ [0-9.]+ ([0-9.]+)').firstMatch(svg);
    natural = vbMatch != null ? double.tryParse(vbMatch.group(1)!) : null;
  }
  if (natural == null) return maxWidth;
  return (natural * _svgScale).clamp(0, maxWidth);
}

/// Displays one or more psalm tone SVG scores below an antiphon.
///
/// A single SVG is shown directly. Multiple SVGs are presented in a
/// horizontal [PageView] with a dot-indicator for navigation.
class PsalmToneWidget extends StatefulWidget {
  const PsalmToneWidget({super.key, required this.svgData});

  final List<String> svgData;

  @override
  State<PsalmToneWidget> createState() => _PsalmToneWidgetState();
}

class _PsalmToneWidgetState extends State<PsalmToneWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final serifFont = themeNotifier.serifFont;
    final brightness = Theme.of(context).brightness;
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

    final processedSvgs = widget.svgData
        .map((svg) => preprocessPsalmSvg(
              svg,
              textColor: textColorCss,
              serifFont: serifFont,
              redColor: redHex,
            ))
        .toList();

    if (processedSvgs.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final dotColor =
        brightness == Brightness.dark ? Colors.white54 : Colors.black38;
    final dotActiveColor = secondaryColor;

    final maxWidth = screenWidth - 20;

    if (processedSvgs.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.string(
            processedSvgs[0],
            width: _svgTargetWidth(processedSvgs[0], maxWidth),
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount: processedSvgs.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.string(
                  processedSvgs[index],
                  width: _svgTargetWidth(processedSvgs[index], maxWidth),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              processedSvgs.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 10 : 6,
                height: _currentPage == index ? 10 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? dotActiveColor : dotColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
