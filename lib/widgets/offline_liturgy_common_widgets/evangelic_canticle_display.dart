import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_frame.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_marker_icon.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/canticle_language_button.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';

/// The psalm to actually display for a canticle: its Latin or Greek variant
/// per [language] when one exists, otherwise the psalm itself unchanged.
Psalm _displayPsalm(Psalm psalm, CanticleLanguage language) {
  switch (language) {
    case CanticleLanguage.latin:
      return psalm.latin ?? psalm;
    case CanticleLanguage.greek:
      return psalm.greek ?? psalm;
    case CanticleLanguage.french:
      return psalm;
  }
}

/// The font to render a canticle's text in for [language] — Greek needs its
/// own polytonic-capable font; French and Latin use the parser's default.
TextStyle? _verseStyle(CanticleLanguage language, double zoom) {
  if (language != CanticleLanguage.greek) return null;
  return TextStyle(
    fontFamily: 'GentiumPlus',
    fontSize: PsalmConfig.textSize * zoom / 100,
    height: PsalmConfig.lineSpacing,
  );
}

AntiphonMarker _markerForEntry(String key, int index, int count) {
  switch (key) {
    case 'A':
      return AntiphonMarker.yearA;
    case 'B':
      return AntiphonMarker.yearB;
    case 'C':
      return AntiphonMarker.yearC;
    default:
      return count > 1
          ? AntiphonMarker.numbered(index + 1)
          : AntiphonMarker.single;
  }
}

Widget _buildAntiphonBlock(Map<String, List<String>> antiphons, double zoom) {
  final widgets = <Widget>[];
  for (final entry in antiphons.entries) {
    final values = entry.value;
    for (int j = 0; j < values.length; j++) {
      if (widgets.isNotEmpty) widgets.add(SizedBox(height: 12.0 * zoom / 100));
      widgets.add(AntiphonWidget(
        antiphon1: values[j],
        marker1: _markerForEntry(entry.key, j, values.length),
      ));
    }
  }
  return AntiphonFrame(
    child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
  );
}

/// Header part of a canticle: title + opening antiphon block.
/// Used as a sliver peer with [CanticleBody] when a sticky SVG tone is present.
class CanticleHeader extends StatelessWidget {
  const CanticleHeader({
    super.key,
    required this.psalm,
    required this.antiphons,
  });

  final Psalm psalm;
  final Map<String, List<String>> antiphons;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final canticleLanguage = context.watch<LiturgyState>().canticleLanguage;
    final displayPsalm = _displayPsalm(psalm, canticleLanguage);
    final displayTitle = displayPsalm.title ?? '';

    // Biblical reference stays on the title row, same as a psalm's.
    final bibRef = displayPsalm.biblicalReference;
    final refTrailing = bibRef != null
        ? (double zoom) =>
            BiblicalReferenceButton(reference: bibRef, zoom: zoom)
        : null;
    // The language toggle gets its own right-aligned line below, same as
    // a psalm's Hebrew/Greek toggle.
    final hasLanguageToggle = psalm.latin != null || psalm.greek != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LiturgyPartTitle(displayTitle,
            left: LiturgyRowLeft.indent, trailing: refTrailing),
        if (hasLanguageToggle)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: CanticleLanguageButton(zoom: zoom),
            ),
          ),
        if (antiphons.isNotEmpty) ...[
          SizedBox(height: 8.0 * zoom / 100),
          _buildAntiphonBlock(antiphons, zoom),
          SizedBox(height: 14.0 * zoom / 100),
        ],
      ],
    );
  }
}

/// Body part of a canticle: psalm text + closing antiphon block.
/// Used as a sliver peer with [CanticleHeader] when a sticky SVG tone is present.
class CanticleBody extends StatelessWidget {
  const CanticleBody({
    super.key,
    required this.psalm,
    required this.antiphons,
  });

  final Psalm psalm;
  final Map<String, List<String>> antiphons;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final canticleLanguage = context.watch<LiturgyState>().canticleLanguage;
    final displayPsalm = _displayPsalm(psalm, canticleLanguage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PsalmFromMarkdown(
          content: displayPsalm.content,
          verseStyle: _verseStyle(canticleLanguage, zoom),
        ),
        if (antiphons.isNotEmpty) ...[
          SizedBox(height: 14.0 * zoom / 100),
          _buildAntiphonBlock(antiphons, zoom),
        ],
      ],
    );
  }
}

class CanticleWidget extends StatelessWidget {
  final Map<String, List<String>> antiphons;
  final Psalm psalm;

  const CanticleWidget({
    super.key,
    required this.antiphons,
    required this.psalm,
  });

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final canticleLanguage = context.watch<LiturgyState>().canticleLanguage;
    final displayPsalm = _displayPsalm(psalm, canticleLanguage);
    final displayTitle = displayPsalm.title ?? '';

    // Biblical reference stays on the title row, same as a psalm's.
    final bibRef = displayPsalm.biblicalReference;
    final refTrailing = bibRef != null
        ? (double zoom) =>
            BiblicalReferenceButton(reference: bibRef, zoom: zoom)
        : null;
    // The language toggle gets its own right-aligned line below, same as
    // a psalm's Hebrew/Greek toggle.
    final hasLanguageToggle = psalm.latin != null || psalm.greek != null;

    final antiphonBlock =
        antiphons.isNotEmpty ? _buildAntiphonBlock(antiphons, zoom) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LiturgyPartTitle(displayTitle,
            left: LiturgyRowLeft.indent, trailing: refTrailing),
        if (hasLanguageToggle)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: CanticleLanguageButton(zoom: zoom),
            ),
          ),
        if (antiphonBlock != null) ...[
          SizedBox(height: 8.0 * zoom / 100),
          antiphonBlock,
          SizedBox(height: 14.0 * zoom / 100),
        ],
        PsalmFromMarkdown(
          content: displayPsalm.content,
          verseStyle: _verseStyle(canticleLanguage, zoom),
        ),
        if (antiphonBlock != null) ...[
          SizedBox(height: 14.0 * zoom / 100),
          antiphonBlock,
        ],
      ],
    );
  }
}
