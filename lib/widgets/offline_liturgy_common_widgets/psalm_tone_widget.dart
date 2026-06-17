import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/utils/svg_preprocessor.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';

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
    final darkMode = themeNotifier.darkTheme;
    final serifFont = themeNotifier.serifFont;
    final brightness = Theme.of(context).brightness;

    final processedSvgs = widget.svgData
        .map((svg) =>
            preprocessPsalmSvg(svg, darkMode: darkMode, serifFont: serifFont))
        .toList();

    if (processedSvgs.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final dotColor = brightness == Brightness.dark
        ? Colors.white54
        : Colors.black38;
    final dotActiveColor = Theme.of(context).colorScheme.secondary;

    if (processedSvgs.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: SvgPicture.string(
            processedSvgs[0],
            width: screenWidth - 32,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount: processedSvgs.length,
              onPageChanged: (index) =>
                  setState(() => _currentPage = index),
              itemBuilder: (context, index) => Center(
                child: SvgPicture.string(
                  processedSvgs[index],
                  width: screenWidth - 32,
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
                  color:
                      _currentPage == index ? dotActiveColor : dotColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
