import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';

const _antiphonLabels = {
  'antiphon': 'Ant.',
  'A': 'Année A',
  'B': 'Année B',
  'C': 'Année C',
};

Widget _buildAntiphonBlock(Map<String, List<String>> antiphons) {
  final widgets = <Widget>[];
  for (final entry in antiphons.entries) {
    final baseLabel = _antiphonLabels[entry.key] ?? entry.key;
    final values = entry.value;
    for (int j = 0; j < values.length; j++) {
      final label = values.length > 1 ? '$baseLabel ${j + 1}' : baseLabel;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12.0));
      widgets.add(AntiphonWidget(antiphon1: values[j], label1: label));
    }
  }
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
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
    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);
    final shortRef = psalm.shortReference;
    final showShort = shortRef != null &&
        (shortRef.startsWith('AT') || shortRef.startsWith('NT'));
    final displayTitle =
        showShort ? '${psalm.title} ($shortRef)' : (psalm.title ?? '');

    Widget Function(double zoom)? biblicalRefTrailing;
    if (psalm.biblicalReference != null) {
      biblicalRefTrailing = (zoom) =>
          BiblicalReferenceButton(reference: psalm.biblicalReference!, zoom: zoom);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: kContentPadding,
          child: LiturgyPartContentTitle(displayTitle,
              trailing: biblicalRefTrailing),
        ),
        SizedBox(height: 12.0 * zoom / 100),
        if (antiphons.isNotEmpty) ...[
          _buildAntiphonBlock(antiphons),
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
          _buildAntiphonBlock(antiphons),
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
    final shortRef = psalm.shortReference;
    final showShort = shortRef != null &&
        (shortRef.startsWith('AT') || shortRef.startsWith('NT'));
    final displayTitle =
        showShort ? '${psalm.title} ($shortRef)' : (psalm.title ?? '');

    Widget Function(double zoom)? biblicalRefTrailing;
    if (psalm.biblicalReference != null) {
      biblicalRefTrailing = (zoom) => BiblicalReferenceButton(
          reference: psalm.biblicalReference!, zoom: zoom);
    }

    final antiphonBlock =
        antiphons.isNotEmpty ? _buildAntiphonBlock(antiphons) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LiturgyPartContentTitle(displayTitle,
            trailing: biblicalRefTrailing, hideVerseIdPlaceholder: false),
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
