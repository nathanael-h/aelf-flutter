import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';

const _antiphonLabels = {
  'antiphon': 'Ant.',
  'A': 'Année A',
  'B': 'Année B',
  'C': 'Année C',
};

Widget _buildAntiphonBlock(Map<String, List<String>> antiphons, double zoom) {
  final widgets = <Widget>[];
  for (final entry in antiphons.entries) {
    final baseLabel = _antiphonLabels[entry.key] ?? entry.key;
    final values = entry.value;
    for (int j = 0; j < values.length; j++) {
      final label = values.length > 1 ? '$baseLabel ${j + 1}' : baseLabel;
      if (widgets.isNotEmpty) widgets.add(SizedBox(height: 12.0 * zoom / 100));
      widgets.add(AntiphonWidget(antiphon1: values[j], label1: label));
    }
  }
  return LiturgyRow(
    builder: (context, zoom) =>
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
    final displayTitle = psalm.title ?? '';

    Widget Function(double zoom)? biblicalRefTrailing;
    if (psalm.biblicalReference != null) {
      biblicalRefTrailing = (zoom) => BiblicalReferenceButton(
          reference: psalm.biblicalReference!, zoom: zoom);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LiturgyPartTitle(displayTitle, left: LiturgyRowLeft.indent),
        if (biblicalRefTrailing != null)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: biblicalRefTrailing!(zoom),
            ),
          ),
        SizedBox(height: 12.0 * zoom / 100),
        if (antiphons.isNotEmpty) ...[
          _buildAntiphonBlock(antiphons, zoom),
          SizedBox(height: 12.0 * zoom / 100),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PsalmFromMarkdown(content: psalm.content),
        if (antiphons.isNotEmpty) ...[
          SizedBox(height: 20.0 * zoom / 100),
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
    final displayTitle = psalm.title ?? '';

    Widget Function(double zoom)? biblicalRefTrailing;
    if (psalm.biblicalReference != null) {
      biblicalRefTrailing = (zoom) => BiblicalReferenceButton(
          reference: psalm.biblicalReference!, zoom: zoom);
    }

    final antiphonBlock =
        antiphons.isNotEmpty ? _buildAntiphonBlock(antiphons, zoom) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LiturgyPartTitle(displayTitle, left: LiturgyRowLeft.indent),
        if (biblicalRefTrailing != null)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: biblicalRefTrailing!(zoom),
            ),
          ),
        SizedBox(height: 12.0 * zoom / 100),
        if (antiphonBlock != null) ...[
          antiphonBlock,
          SizedBox(height: 12.0 * zoom / 100),
        ],
        PsalmFromMarkdown(content: psalm.content),
        if (antiphonBlock != null) ...[
          SizedBox(height: 20.0 * zoom / 100),
          antiphonBlock,
        ],
      ],
    );
  }
}
