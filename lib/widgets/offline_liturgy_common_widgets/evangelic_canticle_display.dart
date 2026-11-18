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
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/latin_toggle_button.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';

/// The psalm to actually display for a canticle: its Latin variant when
/// [useLatin] is on and one exists, otherwise the psalm itself unchanged.
Psalm _displayPsalm(Psalm psalm, bool useLatin) =>
    useLatin && psalm.latin != null ? psalm.latin! : psalm;

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
    final useLatin = context.watch<LiturgyState>().useLatinCanticle;
    final displayPsalm = _displayPsalm(psalm, useLatin);
    final displayTitle = displayPsalm.title ?? '';

    final trailing = <Widget>[
      if (psalm.latin != null) LatinToggleButton(zoom: zoom),
      if (displayPsalm.biblicalReference != null)
        BiblicalReferenceButton(
            reference: displayPsalm.biblicalReference!, zoom: zoom),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LiturgyPartTitle(displayTitle, left: LiturgyRowLeft.indent),
        if (trailing.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: trailing),
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
    final useLatin = context.watch<LiturgyState>().useLatinCanticle;
    final displayPsalm = _displayPsalm(psalm, useLatin);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PsalmFromMarkdown(content: displayPsalm.content),
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
    final useLatin = context.watch<LiturgyState>().useLatinCanticle;
    final displayPsalm = _displayPsalm(psalm, useLatin);
    final displayTitle = displayPsalm.title ?? '';

    final trailing = <Widget>[
      if (psalm.latin != null) LatinToggleButton(zoom: zoom),
      if (displayPsalm.biblicalReference != null)
        BiblicalReferenceButton(
            reference: displayPsalm.biblicalReference!, zoom: zoom),
    ];

    final antiphonBlock =
        antiphons.isNotEmpty ? _buildAntiphonBlock(antiphons, zoom) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LiturgyPartTitle(displayTitle, left: LiturgyRowLeft.indent),
        if (trailing.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: trailing),
            ),
          ),
        if (antiphonBlock != null) ...[
          SizedBox(height: 8.0 * zoom / 100),
          antiphonBlock,
          SizedBox(height: 14.0 * zoom / 100),
        ],
        PsalmFromMarkdown(content: displayPsalm.content),
        if (antiphonBlock != null) ...[
          SizedBox(height: 14.0 * zoom / 100),
          antiphonBlock,
        ],
      ],
    );
  }
}
