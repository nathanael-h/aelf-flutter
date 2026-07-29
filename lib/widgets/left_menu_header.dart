import 'dart:math' show min;

import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';

/// Drawer header ported from the Android native app, see
/// `res/layout/navigation_drawer_header_bible.xml` and
/// `res/drawable/drawer_header_bg_{light,dark}.xml` in aelf-dailyreadings.
///
/// Layout: a tinted logo mask bleeding off the left edge, and a vertically
/// centred title/subtitle block sharing the same colour, over a radial
/// gradient closed by a 1dp rule at the bottom.
///
/// The numbers below are the dp values of the native layout. The native app
/// sizes its text in dp (not sp), so text scaling is disabled here as well to
/// keep the header identical. Its colours come from the theme, see
/// [AelfLectureColors].
class LeftMenuHeader extends StatelessWidget {
  const LeftMenuHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.logoAsset = bibleLogoMask,
  });

  /// `@drawable/ic_logo_bible_mask`: alpha mask, tinted with the text colour.
  static const String bibleLogoMask = 'assets/icons/ic_logo_bible_mask.png';

  final String title;
  final String? subtitle;
  final String logoAsset;

  // navigation_drawer_header_bible.xml
  static const double _height = 160;
  static const double _logoBoxWidth = 160;
  static const double _logoScale = 1.6;
  static const Offset _logoOffset = Offset(-100, 36);
  static const double _textPadding = 16;
  static const double _titleSize = 34;
  static const double _subtitleSize = 14;

  /// Left edge of the text block: the 160dp logo box, pulled back by the
  /// column's `layout_marginLeft="-48dp"`.
  static const double _textColumnLeft = _logoBoxWidth - 48;

  /// The subtitle's `layout_marginTop="-8dp"`.
  static const double _subtitleOverlap = 8;

  /// Size of the small capitals, relative to the full ones. Measured on the
  /// native app: at a 34dp font size, its `fontFeatureSettings="smcp"` gives
  /// 24.3dp capitals and 19.3dp small capitals.
  ///
  /// Small capitals are synthesized instead of requested through
  /// [FontFeature] `smcp`, because only Android's system font ships an `smcp`
  /// table: everywhere else (Linux, iOS, web) the title would silently fall
  /// back to plain lower case.
  static const double _smallCapsRatio = 19.3 / 24.3;

  // drawer_header_bg_*.xml
  static const double _gradientRadius = 300;
  static const Alignment _gradientCenter = Alignment(-0.6, -0.6); // 0.2, 0.2
  static const double _ruleWidth = 1;

  @override
  Widget build(BuildContext context) {
    final AelfLectureColors colors = AelfLectureColors.of(Theme.of(context));
    final Color foreground = colors.text;
    final List<Color> background = <Color>[
      colors.background,
      colors.backgroundDarker,
    ];

    // The scaled logo overflows its box; the native ViewGroup clips it to the
    // header (clipChildren), so we do the same.
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Android's gradientRadius is an absolute dp radius, Flutter's is a
          // fraction of the shortest side.
          final double shortestSide = min(constraints.maxWidth, _height);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: _gradientCenter,
                radius: _gradientRadius / shortestSide,
                colors: background,
              ),
            ),
            child: SizedBox(
              height: _height,
              width: double.infinity,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: 0,
                    width: _logoBoxWidth,
                    height: _height,
                    child: _logo(foreground),
                  ),
                  Positioned(
                    left: _textColumnLeft,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: _text(foreground),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _ruleWidth,
                    child: ColoredBox(color: foreground),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _logo(Color foreground) {
    // translationX/Y are applied on top of scaleX/Y, both around the centre of
    // the 160dp box (`scaleType="centerInside"` == BoxFit.contain here, the
    // mask being larger than the box).
    return Transform.translate(
      offset: _logoOffset,
      child: Transform.scale(
        scale: _logoScale,
        child: Image.asset(
          logoAsset,
          fit: BoxFit.contain,
          color: foreground,
          colorBlendMode: BlendMode.srcIn,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }

  /// Keeps a line unbroken: the native header lets its `TextView`s wrap, but
  /// they never do at the drawer widths Android uses. Rather than wrap in a
  /// narrower drawer, shrink to fit — the same thing the native offices header
  /// does through `autoSizeTextType`. Nothing is scaled while the line fits.
  Widget _singleLine(Widget text) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: text,
    );
  }

  /// Rebuilds [text] as small capitals: lower-case letters become capitals at
  /// [_smallCapsRatio] of the font size, everything else is left as-is, which
  /// is what the font's `smcp` feature does on Android.
  TextSpan _smallCaps(String text, TextStyle style) {
    final TextStyle smallStyle = style.copyWith(
      fontSize: (style.fontSize ?? _titleSize) * _smallCapsRatio,
    );
    final List<TextSpan> spans = <TextSpan>[];
    final StringBuffer run = StringBuffer();
    bool? runIsLowerCase;

    void flushRun() {
      if (run.isEmpty) return;
      final bool isLowerCase = runIsLowerCase!;
      spans.add(TextSpan(
        text: isLowerCase ? run.toString().toUpperCase() : run.toString(),
        style: isLowerCase ? smallStyle : null,
      ));
      run.clear();
    }

    for (final String char in text.split('')) {
      final bool isLowerCase =
          char != char.toUpperCase() && char == char.toLowerCase();
      if (runIsLowerCase != null && isLowerCase != runIsLowerCase) flushRun();
      runIsLowerCase = isLowerCase;
      run.write(char);
    }
    flushRun();

    return TextSpan(style: style, children: spans);
  }

  Widget _text(Color foreground) {
    final String? subtitle = this.subtitle;
    final TextStyle titleStyle = TextStyle(
      // android:fontFamily="sans-serif-medium"
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w500,
      fontSize: _titleSize,
      letterSpacing: 0,
      color: foreground,
    );
    final Widget column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _singleLine(
          Text.rich(
            _smallCaps(title, titleStyle),
            textScaler: TextScaler.noScaling,
          ),
        ),
        if (subtitle != null)
          Transform.translate(
            offset: const Offset(0, -_subtitleOverlap),
            child: _singleLine(
              Text(
                subtitle,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  // android:fontFamily="sans-serif-light"
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w300,
                  fontSize: _subtitleSize,
                  color: foreground,
                ),
              ),
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _textPadding),
      child: subtitle == null
          ? column
          // The subtitle's negative margin shortens the block on Android, which
          // moves its centred position down by half the overlap.
          : Transform.translate(
              offset: const Offset(0, _subtitleOverlap / 2),
              child: column,
            ),
    );
  }
}
