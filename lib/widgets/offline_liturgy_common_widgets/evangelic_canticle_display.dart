import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';

const _antiphonLabels = {
  'antiphon': 'Ant.',
  'A': 'Année A',
  'B': 'Année B',
  'C': 'Année C',
};

class CanticleWidget extends StatelessWidget {
  final Map<String, String> antiphons;
  final Psalm psalm;

  const CanticleWidget({
    super.key,
    required this.antiphons,
    required this.psalm,
  });

  @override
  Widget build(BuildContext context) {
    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);

    final hasAntiphons = antiphons.isNotEmpty;

    Widget? antiphonBlock;
    if (hasAntiphons) {
      final antiphonWidgets = <Widget>[];
      final entries = antiphons.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final label = _antiphonLabels[entry.key] ?? entry.key;
        if (i > 0) {
          antiphonWidgets.add(const SizedBox(height: 12.0));
        }
        antiphonWidgets.add(
          AntiphonWidget(
            antiphon1: entry.value,
            label1: label,
          ),
        );
      }

      antiphonBlock = Padding(
        padding: kContentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: antiphonWidgets,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: kContentPadding,
          child: LiturgyPartTitle(psalm.title ?? ''),
        ),
        SizedBox(height: spaceBetweenElements),
        if (antiphonBlock != null) ...[
          antiphonBlock,
          SizedBox(height: spaceBetweenElements),
        ],
        PsalmFromMarkdown(content: psalm.getContent),
        if (antiphonBlock != null) ...[
          SizedBox(height: spaceBetweenElements),
          antiphonBlock,
        ],
      ],
    );
  }
}
