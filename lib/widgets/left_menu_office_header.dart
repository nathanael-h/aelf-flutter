import 'package:aelf_flutter/models/office_header_info.dart';
import 'package:aelf_flutter/utils/small_caps.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/aelf_drawer_header_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Offices / Mass drawer header, ported from the Android native app's
/// `res/layout/navigation_drawer_header_offices.xml` in aelf-dailyreadings.
///
/// Layout: the AELF logo top-left, then a column with the day title (autosized),
/// the liturgical time, and a region selector.
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
  static const double _squareSize = 9;

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
              _day(context, foreground),
              if ((info.degree ?? '').isNotEmpty)
                _degree(context, info.degree!, foreground)
              else if ((info.seasonText ?? '').isNotEmpty)
                _degree(context, info.seasonText!, foreground),
              if (info.timeText.isNotEmpty)
                Transform.translate(
                  offset: const Offset(0, _timeMarginTop),
                  child:
                      _lightText(context, info.timeText, _timeSize, foreground),
                ),
              if (onRegionTap != null || onRegionSelected != null)
                _regionSelector(context, foreground),
            ],
          ),
        ),
      ],
    );
  }

  Widget _day(BuildContext context, Color foreground) {
    final String text = info.isLoading
        ? 'Chargement…'
        : info.isError
            ? 'Erreur'
            : (info.day ?? '');
    if (text.isEmpty) return const SizedBox.shrink();
    final TextStyle style = TextStyle(
      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: _daySize,
      height: 1.0,
      color: foreground,
    );
    // android:maxHeight="40dp" + autoSize 16–34dp, gravity bottom: shrink to fit
    // one line within the band, aligned to the bottom-left.
    final Widget title = Transform.translate(
      offset: const Offset(0, _dayMarginTop),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: _dayMaxHeight,
          minHeight: _dayMinSize,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomLeft,
          child: Text.rich(
            smallCapsSpan(text, style, ratio: 0.7),
            maxLines: 1,
            textScaler: TextScaler.noScaling,
          ),
        ),
      ),
    );
    return title;
  }

  Widget _regionSelector(BuildContext context, Color foreground) {
    final String label = regionLabel ?? _regionLabel(selectedRegion);
    final Widget row = Row(
      children: <Widget>[
        Expanded(child: _lightText(context, label, _regionSize, foreground)),
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

  Widget _lightText(
      BuildContext context, String text, double size, Color color) {
    return Text(
      text,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        fontWeight: FontWeight.w300,
        fontSize: size,
        color: color,
      ),
    );
  }

  /// The primary celebration's own degree or season/week line, right under
  /// the title, in a light italic. Wraps onto a second line rather than
  /// overflowing when it's long (e.g. "25ème semaine du Temps Ordinaire").
  /// Carries the liturgical-colour square.
  Widget _degree(BuildContext context, String text, Color color) {
    final Widget label = Text(
      text,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        fontSize: _regionSize,
        color: color,
      ),
    );
    final Color? square = info.squareColor(context);
    if (square == null) return label;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 6, top: 3),
          child: SizedBox(
            width: _squareSize,
            height: _squareSize,
            child: ColoredBox(color: square),
          ),
        ),
        Flexible(child: label),
      ],
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
