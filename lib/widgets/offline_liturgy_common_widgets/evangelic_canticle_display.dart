import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:aelf_flutter/utils/bible_reference_fetcher.dart';

const _antiphonLabels = {
  'antiphon': 'Ant.',
  'A': 'Year A',
  'B': 'Year B',
  'C': 'Year C',
};

class CanticleWidget extends StatelessWidget {
  final Map<String, String> antiphons;
  final Psalm psalm;
  final bool imprecatory;

  const CanticleWidget({
    super.key,
    required this.antiphons,
    required this.psalm,
    this.imprecatory = true,
  });

  @override
  Widget build(BuildContext context) {
    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);

    // --- Build Multi-Antiphon Column ---
    Widget? antiphonBlock;
    if (antiphons.isNotEmpty) {
      final antiphonWidgets = <Widget>[];
      final entries = antiphons.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final label = _antiphonLabels[entry.key] ?? entry.key;
        if (i > 0) antiphonWidgets.add(const SizedBox(height: 12.0));
        antiphonWidgets
            .add(AntiphonWidget(antiphon1: entry.value, label1: label));
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
      biblicalRefTrailing = (zoom) => GestureDetector(
            onTap: () => refButtonPressed(psalm.biblicalReference!, context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book,
                    size: 13 * zoom / 100,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 4),
                Text(psalm.biblicalReference!,
                    style: TextStyle(
                        fontSize: 12 * zoom / 100,
                        color: Theme.of(context).colorScheme.secondary)),
              ],
            ),
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: kContentPadding,
          child: LiturgyPartContentTitle(displayTitle, trailing: biblicalRefTrailing),
        ),
        const SizedBox(height: 12.0),
        if (antiphonBlock != null) ...[
          antiphonBlock,
          const SizedBox(height: 12.0),
        ],
        PsalmFromMarkdown(content: psalm.content, imprecatory: imprecatory),
        if (antiphonBlock != null) ...[
          const SizedBox(height: 12.0),
          antiphonBlock,
        ],
      ],
    );
  }
}
