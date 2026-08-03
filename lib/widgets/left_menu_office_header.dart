import 'package:aelf_flutter/models/office_header_info.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/aelf_drawer_header_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Offices / Mass drawer header, ported from the Android native app's
/// `res/layout/navigation_drawer_header_offices.xml` and
/// `navigation_drawer_liturgical_options_fragment.xml` in aelf-dailyreadings.
///
/// Layout: the AELF logo top-left, then a column with the day title (autosized),
/// the liturgical time, and a region selector; below, a list of liturgical
/// options, each a small colour square + name + degree.
///
/// The data comes normalized through [OfficeHeaderInfo], so this widget is the
/// same whether the office is fetched from the online API or computed by the
/// offline_liturgy package. Text is sized in dp (scaling disabled) to match the
/// native layout; colours come from [AelfLectureColors] / [AelfLiturgicalColors].
class LeftMenuOfficeHeader extends StatelessWidget {
  const LeftMenuOfficeHeader({
    super.key,
    required this.info,
    this.selectedRegion,
    this.regionLabel,
    this.onRegionSelected,
    this.onRegionTap,
  });

  final OfficeHeaderInfo info;

  /// Current region id; when null the selector shows nothing selected.
  final String? selectedRegion;

  /// Explicit label for the region row (offline location name). When null the
  /// built-in online region label for [selectedRegion] is used.
  final String? regionLabel;

  /// Called with a region id when the user picks one from the built-in popup
  /// (online mode). Ignored when [onRegionTap] is provided.
  final ValueChanged<String>? onRegionSelected;

  /// Opens a custom region picker (offline location sheet) instead of the
  /// built-in popup. Takes precedence over [onRegionSelected].
  final VoidCallback? onRegionTap;

  /// `@drawable/aelf_logo_{light,dark}` ported to SVG. Recoloured per theme by
  /// [_AelfLogoColorMapper].
  static const String _logoAsset = 'assets/icons/aelf_logo.svg';

  // navigation_drawer_header_offices.xml
  static const double _paddingHorizontal = 16;
  static const double _paddingTop = 24;
  static const double _paddingBottom = 16;
  static const double _minHeight = 160;
  static const double _logoSize = 69;
  static const double _logoTranslationX = -8;
  static const double _dayMarginLeft = 2;
  static const double _dayMarginTop = -8;
  static const double _daySize = 34;
  static const double _dayMinSize = 16;
  static const double _dayMaxHeight = 40;
  static const double _timeSize = 14;
  static const double _timeMarginTop = -4;
  static const double _regionSize = 14;
  static const double _optionsPaddingTop = 16;

  // navigation_drawer_liturgical_options_fragment.xml
  static const double _squareSize = 9;
  static const double _squareMarginTop = 6;
  static const double _optionTitleMarginLeft = 8;
  static const double _optionTitleSize = 14;
  static const double _optionDegreeSize = 12;
  static const double _optionDegreeMarginTop = -4;

  /// Region ids and labels, in the native dropdown order
  /// (`left_menu_light_liturgy_dropdown.png`).
  static const List<List<String>> regions = <List<String>>[
    <String>['france', 'France'],
    <String>['belgique', 'Belgique'],
    <String>['luxembourg', 'Luxembourg'],
    <String>['suisse', 'Suisse'],
    <String>['canada', 'Canada'],
    <String>['monaco', 'Monaco'],
    <String>['afrique', 'Afrique'],
    <String>['romain', 'Romain (Autres)'],
  ];

  static String _regionLabel(String? id) {
    for (final r in regions) {
      if (r[0] == id) return r[1];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color foreground = AelfLectureColors.of(Theme.of(context)).text;

    return AelfDrawerHeaderBackground(
      minHeight: _minHeight,
      child: Padding(
        padding: const EdgeInsets.only(
          left: _paddingHorizontal,
          right: _paddingHorizontal,
          top: _paddingTop,
          bottom: _paddingBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _topRow(context, foreground, isDark),
            if (info.options.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: _optionsPaddingTop),
                child: _options(context, foreground),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topRow(BuildContext context, Color foreground, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Transform.translate(
          offset: const Offset(_logoTranslationX, 0),
          child: SvgPicture.asset(
            _logoAsset,
            width: _logoSize,
            height: _logoSize,
            colorMapper: _AelfLogoColorMapper(isDark: isDark),
          ),
        ),
        const SizedBox(width: _dayMarginLeft),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _day(foreground),
              if (info.timeText.isNotEmpty)
                Transform.translate(
                  offset: const Offset(0, _timeMarginTop),
                  child: _lightText(info.timeText, _timeSize, foreground),
                ),
              if (onRegionTap != null || onRegionSelected != null)
                _regionSelector(context, foreground),
            ],
          ),
        ),
      ],
    );
  }

  Widget _day(Color foreground) {
    final String text = info.isLoading
        ? 'Chargement…'
        : info.isError
            ? 'Erreur'
            : (info.day ?? '');
    if (text.isEmpty) return const SizedBox.shrink();
    // android:maxHeight="40dp" + autoSize 16–34dp, gravity bottom: shrink to fit
    // one line within the band, aligned to the bottom-left.
    return Transform.translate(
      offset: const Offset(0, _dayMarginTop),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: _dayMaxHeight,
          minHeight: _dayMinSize,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomLeft,
          child: Text(
            text,
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              // android:fontFamily="sans-serif-condensed-medium"
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: _daySize,
              height: 1.0,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _regionSelector(BuildContext context, Color foreground) {
    final String label = regionLabel ?? _regionLabel(selectedRegion);
    final Widget row = Row(
      children: <Widget>[
        Expanded(child: _lightText(label, _regionSize, foreground)),
        Icon(Icons.arrow_drop_down, color: foreground, size: 24),
      ],
    );

    // Offline: a custom picker (the location sheet).
    if (onRegionTap != null) {
      return InkWell(onTap: onRegionTap, child: row);
    }

    // Online: the built-in 8-region popup.
    return PopupMenuButton<String>(
      initialValue: selectedRegion,
      tooltip: 'Choisir la région',
      padding: EdgeInsets.zero,
      onSelected: onRegionSelected,
      itemBuilder: (context) => regions
          .map((r) => PopupMenuItem<String>(
                value: r[0],
                child: Text(r[1]),
              ))
          .toList(),
      child: row,
    );
  }

  Widget _options(BuildContext context, Color foreground) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final option in info.options) _option(context, option, foreground),
      ],
    );
  }

  Widget _option(
      BuildContext context, OfficeLiturgyOption option, Color foreground) {
    final Color? square = option.squareColor(context);
    final String? degree = option.degree;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // fragment paddingBottom="4dp"
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: _squareMarginTop),
            child: SizedBox(
              width: _squareSize,
              height: _squareSize,
              child: square == null ? null : ColoredBox(color: square),
            ),
          ),
          const SizedBox(width: _optionTitleMarginLeft),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  option.name,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: _optionTitleSize,
                    color: foreground,
                  ),
                ),
                if (degree != null && degree.isNotEmpty)
                  Transform.translate(
                    offset: const Offset(0, _optionDegreeMarginTop),
                    child: Text(
                      degree,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        // android:fontFamily="sans-serif-light" + italic
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w300,
                        fontStyle: FontStyle.italic,
                        fontSize: _optionDegreeSize,
                        color: foreground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lightText(String text, double size, Color color) {
    return Text(
      text,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        // android:fontFamily="sans-serif-light"
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w300,
        fontSize: size,
        color: color,
      ),
    );
  }
}

/// Remaps the two placeholder fills in `aelf_logo.svg` to the theme colours,
/// matching native `aelf_logo_light.xml` / `aelf_logo_dark.xml`:
/// the red stroke (`#BF252A`) and the "A" glyph (`#000000`).
class _AelfLogoColorMapper extends ColorMapper {
  const _AelfLogoColorMapper({required this.isDark});

  final bool isDark;

  static const Color _sourceRed = Color(0xFFBF252A);
  static const Color _sourceGlyph = Color(0xFF000000);

  @override
  Color substitute(
      String? id, String elementName, String attributeName, Color color) {
    if (color == _sourceRed) {
      return isDark ? const Color(0xFFD7464E) : const Color(0xFFBF252A);
    }
    if (color == _sourceGlyph) {
      return isDark ? const Color(0xFF4D4D4D) : const Color(0xFF000000);
    }
    return color;
  }
}
