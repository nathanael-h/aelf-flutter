import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';

/// ============================================
/// CHOICE SELECTORS
/// ============================================
/// The offices' two ways of offering a choice: a list of rows for long
/// labels (celebrations, Commons, Complines, Mass readings), and a segmented
/// control for two to four short ones (the Mass's reading source, the
/// invitatory psalm).

/// Builds a [Text.rich] for a choice label, rendering ^word as superscript.
Widget buildRichLabelText(String text, TextStyle style) {
  final paragraphs = YamlTextParser.parseText(text);
  final spans = <InlineSpan>[];

  for (final para in paragraphs) {
    for (final line in para.lines) {
      for (final segment in line.segments) {
        if (segment.isSuperscript) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Transform.translate(
              offset: Offset(0, -(style.fontSize ?? 12.0) * 0.45),
              child: Text(
                segment.text,
                style:
                    style.copyWith(fontSize: (style.fontSize ?? 12.0) * 0.65),
              ),
            ),
          ));
        } else {
          spans.add(TextSpan(text: segment.text, style: style));
        }
      }
    }
  }

  if (spans.isEmpty) {
    return Text(text,
        style: style, softWrap: true, maxLines: 5, textAlign: TextAlign.left);
  }

  return Text.rich(
    TextSpan(children: spans),
    softWrap: true,
    maxLines: 5,
    textAlign: TextAlign.left,
  );
}

/// Splits a label ending with a parenthesis into its title and the
/// parenthesis' content: "Commun des Pasteurs (papes)" -> ("Commun des
/// Pasteurs", "papes"). A label without one is returned whole, with no
/// subtitle.
(String, String?) splitTrailingParenthesis(String label) {
  final match = RegExp(r'^(.*\S)\s*\(([^()]+)\)\s*$').firstMatch(label);
  if (match == null) return (label, null);
  return (match.group(1)!, match.group(2)!.trim());
}

/// The color marking a selected [ChoiceRow]: [liturgicalColor], or the
/// theme's accent when it would vanish on the background — a white feast on
/// a light theme. A null [liturgicalColor] (a Common, a reading choice
/// outside any celebration) also takes the accent.
Color choiceMarkColor(BuildContext context, String? liturgicalColor) {
  final colorScheme = Theme.of(context).colorScheme;
  if (liturgicalColor == null) return colorScheme.secondary;
  final color = getLiturgicalColor(liturgicalColor);
  final contrast =
      (color.computeLuminance() - colorScheme.surface.computeLuminance()).abs();
  return contrast < 0.3 ? colorScheme.secondary : color;
}

/// Rows of a [ChoiceRow] list, set in the offices' 16 px side margins.
class ChoiceList extends StatelessWidget {
  const ChoiceList({super.key, required this.rows});

  final List<ChoiceRow> rows;

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      ),
    );
  }
}

/// One choice of a [ChoiceList]: an optional dot of the liturgical color,
/// the title (in bold unless [boldTitle] is false) and an optional subtitle
/// below. The selected row is
/// marked by a bar of [barColor] (by default [markColor]) and a tint of
/// [markColor] (see [choiceMarkColor]).
/// A [muted] row (a celebration not celebrated today) is set in italics.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.dotColor,
    this.showDot = false,
    this.leading,
    required this.markColor,
    this.barColor,
    this.boldTitle = true,
    this.muted = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  // Liturgical color name of the dot; showDot without one draws no dot but
  // keeps its room, so the titles of a list stay aligned.
  final String? dotColor;
  final bool showDot;
  // Drawn in place of the dot when given, e.g. the Commons' ChoiceDiamond
  final Widget? leading;
  final Color markColor;
  // The celebration's own color, even white: the tint keeps the selection
  // visible where the bar alone would not be
  final Color? barColor;
  // False where the title is a name rather than a reference, so it stays
  // distinct from the bold section titles above (celebrations, Commons)
  final bool boldTitle;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final theme = Theme.of(context);
    final titleStyle = TextStyle(
      color: muted ? theme.hintColor : theme.colorScheme.onSurface,
      fontSize: 14 * zoom / 100,
      fontWeight: boldTitle && !muted ? FontWeight.w600 : FontWeight.normal,
      fontStyle: muted ? FontStyle.italic : FontStyle.normal,
      height: 1.3,
    );
    final subtitleStyle = TextStyle(
      color: theme.hintColor,
      fontSize: 12.5 * zoom / 100,
      height: 1.3,
    );
    final radius = BorderRadius.circular(4);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0 * zoom / 100),
      child: Material(
        color:
            selected ? markColor.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? barColor ?? markColor : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(
                horizontal: 10.0, vertical: 6.0 * zoom / 100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null || showDot) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 4.5 * zoom / 100),
                    child:
                        leading ?? _LiturgicalDot(color: dotColor, zoom: zoom),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildRichLabelText(title, titleStyle),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        buildRichLabelText(subtitle!, subtitleStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small disc of a liturgical color, outlined so a white one shows.
class _LiturgicalDot extends StatelessWidget {
  const _LiturgicalDot({required this.color, required this.zoom});

  final String? color;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final size = 10.0 * zoom / 100;
    return Container(
      width: size,
      height: size,
      decoration: color == null
          ? null
          : BoxDecoration(
              color: getLiturgicalColor(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
    );
  }
}

/// A small diamond of the accent red, the ornament of AntiphonSeparator:
/// the bullet of a list whose rows carry no liturgical color (the Commons),
/// so it can't be mistaken for a celebration's dot. Sized like that dot,
/// so the titles line up the same way.
class ChoiceDiamond extends StatelessWidget {
  const ChoiceDiamond({super.key});

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final side = 5.0 * zoom / 100;
    return SizedBox.square(
      dimension: 10.0 * zoom / 100,
      child: Center(
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: side,
            height: side,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

/// Two to four short choices side by side, the selected one filled — for
/// a one-out-of-a-few choice such as the invitatory psalm. Its segments
/// stop growing at [maxSegmentWidth], centered, rather than spreading
/// across a wide screen. A null [onSelected] disables it (e.g. while the
/// previous choice loads).
class SegmentedChoice extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  /// A segment's widest, at 100 % zoom: room for "Psaume 100" and its margins
  static const double maxSegmentWidth = 90;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = theme.dividerColor;
    final radius = BorderRadius.circular(9);
    // The AELF red, by day as by night
    final selectedColor = colorScheme.secondary;
    const selectedTextColor = Colors.white;

    return SelectionContainer.disabled(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: labels.length * maxSegmentWidth * zoom / 100),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: radius,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, label) in labels.indexed) ...[
                        if (i > 0)
                          VerticalDivider(width: 1, color: borderColor),
                        Expanded(
                          child: Material(
                            color: i == selectedIndex
                                ? selectedColor
                                : Colors.transparent,
                            child: InkWell(
                              onTap: onSelected == null || i == selectedIndex
                                  ? null
                                  : () => onSelected!(i),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 4.0 * zoom / 100),
                                child: Center(
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5 * zoom / 100,
                                      color: i == selectedIndex
                                          ? selectedTextColor
                                          : colorScheme.onSurface.withValues(
                                              alpha:
                                                  onSelected == null ? 0.4 : 1),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
