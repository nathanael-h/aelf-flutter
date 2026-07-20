import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:offline_liturgy/tools/date_tools.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_selector.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_sliver_delegate.dart';
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

class CelebrationChipsSelector extends StatelessWidget {
  const CelebrationChipsSelector({
    super.key,
    required this.celebrationMap,
    required this.selectedKey,
    required this.onCelebrationChanged,
    this.onPrecedenceOverridden,
  });

  final Map<String, CelebrationContext> celebrationMap;
  final String selectedKey;
  final ValueChanged<String> onCelebrationChanged;
  final void Function(String key, int? precedence)? onPrecedenceOverridden;

  String _forcedLabel(int precedence) {
    if (precedence == 8) return '(FÊTE FORCÉE)';
    return '(SOLENNITÉ FORCÉE)';
  }

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final overrides = context.watch<SelectedCelebrationState>();
    final chipMaxWidth = MediaQuery.of(context).size.width - 80;

    final celebrableEntries =
        celebrationMap.entries.where((e) => e.value.isCelebrable).toList();
    final nonCelebrableEntries = celebrationMap.entries
        .where((e) =>
            !e.value.isCelebrable &&
            e.value.celebrationCode != e.value.ferialCode)
        .toList();

    final hasFeastChips = onPrecedenceOverridden != null &&
        celebrableEntries
            .any((e) => e.value.celebrationCode != e.value.ferialCode);
    final hasNonCelebrable = nonCelebrableEntries.isNotEmpty;

    Widget buildChip(MapEntry<String, CelebrationContext> entry,
        {bool italic = false}) {
      final isSelected = entry.key == selectedKey;
      final color = getLiturgicalColor(entry.value.liturgicalColor);
      final description = entry.value.officeDescription ?? '';
      final precedenceOverride = overrides.getPrecedenceOverride(entry.key);
      final typeLabel = precedenceOverride != null
          ? _forcedLabel(precedenceOverride)
          : entry.value.celebrationDisplayLabel;
      final textColor =
          color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
      final chipTextStyle = TextStyle(
        color: textColor,
        fontSize: 12.0 * zoom / 100,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

      final chip = ChoiceChip(
        label: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: chipMaxWidth),
          child: _buildRichChipText('$description $typeLabel', chipTextStyle),
        ),
        labelStyle: chipTextStyle,
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            overrides.clearPrecedenceOverrides();
            onCelebrationChanged(entry.key);
          }
        },
        showCheckmark: true,
        checkmarkColor: textColor,
        backgroundColor: color.withValues(alpha: 0.6),
        selectedColor: color,
      );

      final naturalPrecedence = entry.value.precedence ?? 13;
      final isFeast = entry.value.celebrationCode != entry.value.ferialCode &&
          entry.value.celebrationCode != 'roman/virgin-mary-memory' &&
          naturalPrecedence > 3;
      if (onPrecedenceOverridden == null || !isFeast) {
        return SelectionContainer.disabled(child: chip);
      }

      return GestureDetector(
        onLongPress: () {
          final currentOverride = overrides.getPrecedenceOverride(entry.key);
          final effectivePrecedence = currentOverride ?? naturalPrecedence;

          if (currentOverride == 4) {
            HapticFeedback.lightImpact();
            onPrecedenceOverridden?.call(entry.key, null);
          } else if (effectivePrecedence == 5 ||
              effectivePrecedence == 7 ||
              effectivePrecedence == 8) {
            HapticFeedback.heavyImpact();
            onPrecedenceOverridden?.call(entry.key, 4);
          } else {
            HapticFeedback.mediumImpact();
            onPrecedenceOverridden?.call(entry.key, 8);
          }
        },
        child: chip,
      );
    }

    final chipsWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0 * zoom / 100,
        runSpacing: 8.0 * zoom / 100,
        children: celebrableEntries.map((e) => buildChip(e)).toList(),
      ),
    );

    if (!hasFeastChips && !hasNonCelebrable) return chipsWidget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chipsWidget,
        if (hasFeastChips)
          Padding(
            padding: EdgeInsets.fromLTRB(
                16.0, 6.0 * zoom / 100, 16.0, 6.0 * zoom / 100),
            child: Text(
              'Appui long : normal -> fête -> solennité -> normal (utile pour les fêtes patronales)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontStyle: FontStyle.italic,
                fontSize: 11.0 * zoom / 100,
                height: 1.4,
              ),
            ),
          ),
        if (hasNonCelebrable) ...[
          const Divider(height: 24),
          OfficeSectionTitle('Fêtes non célébrées'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0 * zoom / 100,
              runSpacing: 8.0 * zoom / 100,
              children: nonCelebrableEntries
                  .map((e) => buildChip(e, italic: true))
                  .toList(),
            ),
          ),
          SizedBox(height: 8.0 * zoom / 100),
        ],
      ],
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
    this.forceCommon = false,
  });

  final List<String> commonList;
  final Map<String, String> commonTitles;
  final String? selectedCommon;
  final int precedence;
  final ValueChanged<String?> onCommonChanged;
  final bool forceCommon;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final chipMaxWidth = MediaQuery.of(context).size.width - 80;
    final bool showNoCommon = !forceCommon && precedence > 8;

    // Single common without "no common" option: just show informational text
    if (commonList.length == 1 && !showNoCommon) {
      final title = commonTitles[commonList.first] ?? commonList.first;
      return Padding(
        padding:
            EdgeInsets.fromLTRB(16.0, 4.0 * zoom / 100, 16.0, 4.0 * zoom / 100),
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
        spacing: 8.0 * zoom / 100,
        runSpacing: 8.0 * zoom / 100,
        alignment: WrapAlignment.start,
        children: [
          if (showNoCommon)
            ChoiceChip(
              label: const Text('Pas de commun'),
              labelStyle: labelStyle,
              selected: selectedCommon == null,
              showCheckmark: true,
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
              showCheckmark: true,
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
List<Widget> buildOrationWidgets(
  List<String>? orations, {
  double zoom = 100,
  double rightIndentMultiplier = 1.5,
  TextAlign textAlign = TextAlign.justify,
}) {
  if (orations == null || orations.isEmpty) {
    return [
      LiturgyRow(
        builder: (context, zoom) => YamlTextFromString(
            liturgyLabels['no-oration']!,
            textAlign: textAlign,
            rightIndentMultiplier: rightIndentMultiplier),
      ),
    ];
  }
  final widgets = <Widget>[];
  for (var i = 0; i < orations.length; i++) {
    if (i > 0) {
      widgets.add(SizedBox(height: 12.0 * zoom / 100));
      widgets.add(LiturgyRow(
        builder: (context, zoom) => YamlTextFromString(liturgyLabels['or']!),
      ));
      widgets.add(SizedBox(height: 12.0 * zoom / 100));
    }
    widgets.add(LiturgyRow(
      builder: (context, zoom) => YamlTextFromString(orations[i],
          textAlign: textAlign, rightIndentMultiplier: rightIndentMultiplier),
    ));
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
    this.shrinkWrap = false,
  });

  final List<HymnEntry> hymns;
  final String? emptyMessage;
  final bool shrinkWrap;

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
      shrinkWrap: shrinkWrap,
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
    this.shrinkWrap = false,
    this.svgData,
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? verseAfter;
  final bool shrinkWrap;
  final List<String>? svgData;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final themeNotifier = context.watch<ThemeNotifier>();
    final themeKey = '${themeNotifier.darkTheme}_${themeNotifier.serifFont}';
    final hasSvg = svgData != null && svgData!.isNotEmpty;

    // Tab mode with SVG: CustomScrollView keeps the tone partition pinned while
    // the user scrolls through the psalm. The next psalm's header pushes it off.
    if (hasSvg && !shrinkWrap) {
      final screenWidth = MediaQuery.of(context).size.width;
      final extent = psalmToneSliverExtent(svgData!, screenWidth, zoom);
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 16.0 * zoom / 100),
              child: PsalmDisplayHeader(
                psalm: psalm,
                antiphon1: antiphon1,
                antiphon2: antiphon2,
                isScrollMode: false,
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: PsalmToneSliverDelegate(
                svgData: svgData!, extent: extent, themeKey: themeKey),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.0 * zoom / 100),
              child: PsalmDisplayBody(
                psalm: psalm,
                antiphon1: antiphon1,
                antiphon2: antiphon2,
                verseAfter: verseAfter,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: shrinkWrap
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        PsalmDisplayWidget(
          psalm: psalm,
          antiphon1: antiphon1,
          antiphon2: antiphon2,
          verseAfter: verseAfter,
          svgData: svgData,
          isScrollMode: shrinkWrap,
        ),
      ],
    );
  }
}

String? officeAdditionalInfo(
    String? liturgicalTime, Calendar calendar, DateTime date) {
  if (liturgicalTime == 'christmasoctave' ||
      liturgicalTime == 'paschaloctave') {
    return null;
  }
  final dayContent = calendar.getDayContent(date);
  if (dayContent == null) return null;
  final year = liturgicalYear(dayContent.liturgicalYear);
  final week = dayContent.breviaryWeek;
  return week != null
      ? 'Année $year - Semaine ${breviaryWeekToRoman(week)}'
      : 'Année $year';
}

/// ============================================
/// SMALL SHARED WIDGETS
/// ============================================

class OfficeSectionTitle extends StatelessWidget {
  const OfficeSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0 * zoom / 100),
          child: LiturgyRow(
            builder: (context, _) => Text(
              title,
              style: TextStyle(
                fontSize: 15 * zoom / 100,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

class LiturgyTabBar extends StatelessWidget {
  const LiturgyTabBar({super.key, required this.tabs});

  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor =
        theme.tabBarTheme.labelColor ?? theme.colorScheme.secondary;
    return Container(
      color: theme.primaryColor,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: TabBar(
          isScrollable: true,
          indicatorColor: labelColor,
          labelColor: labelColor,
          unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor ??
              theme.colorScheme.secondary.withValues(alpha: 0.7),
          tabs: tabs,
        ),
      ),
    );
  }
}

class HymnContentDisplay extends StatelessWidget {
  const HymnContentDisplay({super.key, required this.content, this.baseStyle});

  final String content;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoomValue = currentZoom.value;
        return YamlTextWidget(
          paragraphs: YamlTextParser.parseText(content),
          textStyle: baseStyle ??
              TextStyle(
                fontSize: 16.0 * zoomValue / 100,
                height: 1.3,
                color: bodyColor,
              ),
          paragraphSpacing: 15.0 * zoomValue / 100,
          redColor: Theme.of(context).colorScheme.secondary,
          useSymbolColumn: true,
        );
      },
    );
  }
}
