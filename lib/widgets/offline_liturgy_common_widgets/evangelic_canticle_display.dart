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
    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);

    // --- Build Multi-Antiphon Column ---
    Widget? antiphonBlock;
    if (antiphons.isNotEmpty) {
      final antiphonWidgets = <Widget>[];
      for (final entry in antiphons.entries) {
        final baseLabel = _antiphonLabels[entry.key] ?? entry.key;
        final values = entry.value;
        for (int j = 0; j < values.length; j++) {
          final label = values.length > 1 ? '$baseLabel ${j + 1}' : baseLabel;
          if (antiphonWidgets.isNotEmpty) {
            antiphonWidgets.add(const SizedBox(height: 12.0));
          }
          antiphonWidgets
              .add(AntiphonWidget(antiphon1: values[j], label1: label));
        }
      }

      antiphonBlock = Padding(
        padding: kContentPadding,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: antiphonWidgets),
      );
    }

    // --- Header and Reference Logic ---
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

    final zoom = context.watch<CurrentZoom>().value;

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
