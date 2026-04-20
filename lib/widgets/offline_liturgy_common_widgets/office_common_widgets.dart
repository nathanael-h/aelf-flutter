import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_selector.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';

/// ============================================
/// SELECTION CHIPS WIDGETS
/// ============================================

/// Builds a [Text.rich] for chip labels, rendering ^word as superscript.
Widget _buildRichChipText(String text, TextStyle style) {
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
                style: style.copyWith(fontSize: (style.fontSize ?? 12.0) * 0.65),
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
    return Text(text, style: style, softWrap: true, maxLines: 3, textAlign: TextAlign.center);
  }

  return Text.rich(
    TextSpan(children: spans),
    softWrap: true,
    maxLines: 3,
    textAlign: TextAlign.center,
  );
}

class CelebrationChipsSelector extends StatelessWidget {
  const CelebrationChipsSelector({
    super.key,
    required this.celebrationMap,
    required this.selectedKey,
    required this.onCelebrationChanged,
  });

  final Map<String, CelebrationContext> celebrationMap;
  final String selectedKey;
  final ValueChanged<String> onCelebrationChanged;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final chipMaxWidth = MediaQuery.of(context).size.width - 80;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: celebrationMap.entries
            .where((e) => e.value.isCelebrable)
            .map((entry) {
          final isSelected = entry.key == selectedKey;
          final color = getLiturgicalColor(entry.value.liturgicalColor);
          final description = entry.value.officeDescription ?? '';
          final firstVespersTag = entry.value.isFirstVespers ? ' (IV)' : '';
          final typeLabel =
              getCelebrationTypeLabel(entry.value.precedence ?? 13);

          final textColor =
              color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

          return ChoiceChip(
            label: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: chipMaxWidth),
              child: _buildRichChipText(
                '$description$firstVespersTag $typeLabel',
                TextStyle(color: textColor, fontSize: 12.0 * zoom / 100),
              ),
            ),
            labelStyle:
                TextStyle(color: textColor, fontSize: 12.0 * zoom / 100),
            selected: isSelected,
            onSelected: (bool selected) {
              if (selected) onCelebrationChanged(entry.key);
            },
            showCheckmark: true,
            checkmarkColor: textColor,
            backgroundColor: color.withValues(alpha: 0.6),
            selectedColor: color,
          );
        }).toList(),
      ),
    );
  }
}

class CommonChipsSelector extends StatelessWidget {
  const CommonChipsSelector({
    super.key,
    required this.commonList,
    required this.commonTitles,
    required this.selectedCommon,
    required this.precedence,
    required this.onCommonChanged,
  });

  final List<String> commonList;
  final Map<String, String> commonTitles;
  final String? selectedCommon;
  final int precedence;
  final ValueChanged<String?> onCommonChanged;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final chipMaxWidth = MediaQuery.of(context).size.width - 80;
    final bool showNoCommon = precedence > 8;

    // Single common without "no common" option: just show informational text
    if (commonList.length == 1 && !showNoCommon) {
      final title = commonTitles[commonList.first] ?? commonList.first;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }

    final labelStyle = TextStyle(fontSize: 12.0 * zoom / 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.start,
        children: [
          if (showNoCommon)
            ChoiceChip(
              label: const Text('Pas de commun'),
              labelStyle: labelStyle,
              selected: selectedCommon == null,
              onSelected: (selected) {
                if (selected) onCommonChanged(null);
              },
            ),
          ...commonList.map((commonKey) {
            return ChoiceChip(
              label: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: chipMaxWidth),
                child: _buildRichChipText(
                  commonTitles[commonKey] ?? commonKey,
                  labelStyle,
                ),
              ),
              labelStyle: labelStyle,
              selected: selectedCommon == commonKey,
              onSelected: (selected) {
                if (selected) onCommonChanged(commonKey);
              },
            );
          }),
        ],
      ),
    );
  }
}

/// ============================================
/// UTILITY FUNCTIONS
/// ============================================

/// Renders a list of orations separated by [liturgyLabels['or']] between each.
List<Widget> buildOrationWidgets(List<String>? orations) {
  if (orations == null || orations.isEmpty) {
    return [
      YamlTextFromString(liturgyLabels['no-oration']!, textAlign: TextAlign.justify),
    ];
  }
  final widgets = <Widget>[];
  for (var i = 0; i < orations.length; i++) {
    if (i > 0) {
      widgets.add(const SizedBox(height: 12.0));
      widgets.add(YamlTextFromString(liturgyLabels['or']!));
      widgets.add(const SizedBox(height: 12.0));
    }
    widgets.add(YamlTextFromString(orations[i], textAlign: TextAlign.justify));
  }
  return widgets;
}

String getPsalmDisplayTitle(Psalm? psalm, String psalmKey) {
  if (psalm?.title != null && psalm!.title!.isNotEmpty) {
    return psalm.title!;
  }
  return psalm?.shortReference ?? psalm?.subtitle ?? psalmKey;
}

/// ============================================
/// COMMON WIDGETS
/// ============================================

class HymnsTabWidget extends StatelessWidget {
  const HymnsTabWidget({
    super.key,
    required this.hymns,
    this.emptyMessage,
  });

  final List<HymnEntry> hymns;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (hymns.isEmpty) {
      return Center(
        child: Text(emptyMessage ?? 'No hymn available'),
      );
    }
    return HymnSelectorWithTitle(
      title: liturgyLabels['hymns'] ?? 'Hymnes',
      hymns: hymns,
    );
  }
}

class PsalmTabWidget extends StatelessWidget {
  const PsalmTabWidget({
    super.key,
    required this.psalm,
    this.antiphon1,
    this.antiphon2,
    this.verseAfter,
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? verseAfter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // MODIFICATION : On garde la marge verticale, mais on met 0 en horizontal
      // pour éviter le double padding avec le contenu du psaume.
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      children: [
        PsalmDisplayWidget(
          psalm: psalm,
          antiphon1: antiphon1,
          antiphon2: antiphon2,
          verseAfter: verseAfter,
        ),
      ],
    );
  }
}
