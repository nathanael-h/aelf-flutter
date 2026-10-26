import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:offline_liturgy/tools/date_tools.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/choice_selectors.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_selector.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_widget.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

/// ============================================
/// CELEBRATION AND COMMON SELECTORS
/// ============================================

/// The office's name ("Laudes", "Vêpres"...) heading its Office tab, in
/// bold small capitals, framed in the accent color.
class OfficeNameHeader extends StatelessWidget {
  const OfficeNameHeader(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final accent = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding:
          EdgeInsets.only(top: 12.0 * zoom / 100, bottom: 12.0 * zoom / 100),
      child: LiturgyRow(
        builder: (context, _) => Center(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 10.0 * zoom / 100, vertical: 2.0 * zoom / 100),
            decoration: BoxDecoration(
              border: Border.all(color: accent, width: 1.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.0 * zoom / 100,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature('smcp')],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CelebrationSelector extends StatelessWidget {
  const CelebrationSelector({
    super.key,
    required this.celebrationMap,
    required this.selectedKey,
    required this.onCelebrationChanged,
  });

  final Map<String, CelebrationContext> celebrationMap;
  final String selectedKey;
  final ValueChanged<String> onCelebrationChanged;

  String _forcedLabel(int precedence) {
    if (precedence == 8) return 'Fête forcée';
    return 'Solennité forcée';
  }

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final overrides = context.watch<SelectedCelebrationState>();

    final celebrableEntries =
        celebrationMap.entries.where((e) => e.value.isCelebrable).toList();
    final nonCelebrableEntries = celebrationMap.entries
        .where((e) =>
            !e.value.isCelebrable &&
            e.value.celebrationCode != e.value.ferialCode)
        .toList();

    final hasNonCelebrable = nonCelebrableEntries.isNotEmpty;

    ChoiceRow buildRow(MapEntry<String, CelebrationContext> entry,
        {bool muted = false}) {
      final precedenceOverride = overrides.getPrecedenceOverride(entry.key);
      // The rank, e.g. "Mémoire facultative" or "Europe : solennité"
      final typeLabel = precedenceOverride != null
          ? _forcedLabel(precedenceOverride)
          : splitTrailingParenthesis(entry.value.celebrationDisplayLabel).$2;

      return ChoiceRow(
        title: entry.value.officeDescription ?? '',
        subtitle: typeLabel,
        selected: entry.key == selectedKey,
        showDot: true,
        dotColor: entry.value.liturgicalColor,
        markColor: choiceMarkColor(context, entry.value.liturgicalColor),
        barColor: getLiturgicalColor(entry.value.liturgicalColor),
        boldTitle: false,
        muted: muted,
        onTap: () {
          if (entry.key == selectedKey) return;
          overrides.clearPrecedenceOverrides();
          onCelebrationChanged(entry.key);
        },
      );
    }

    final rowsWidget =
        ChoiceList(rows: [for (final e in celebrableEntries) buildRow(e)]);

    if (!hasNonCelebrable) return rowsWidget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        rowsWidget,
        if (hasNonCelebrable) ...[
          const Divider(height: 24),
          OfficeSectionTitle('Fêtes non célébrées'),
          ChoiceList(rows: [
            for (final e in nonCelebrableEntries) buildRow(e, muted: true)
          ]),
          SizedBox(height: 8.0 * zoom / 100),
        ],
      ],
    );
  }
}

/// Whether [celebration], as detected (at its own rank), may be celebrated
/// at a higher one (see CelebrationRankSelector): a memorial or a feast
/// replacing the day — not a solemnity, a ferial day, nor the Saturday
/// memory of the Virgin Mary.
bool celebrationCanChangeRank(CelebrationContext? celebration) =>
    celebration != null &&
    celebration.celebrationCode != celebration.ferialCode &&
    celebration.celebrationCode != 'roman/virgin_mary_memory' &&
    (celebration.precedence ?? 13) > 4;

/// The rank the selected celebration is celebrated at: its own, or raised
/// to a feast or a solemnity (e.g. a patronal feast) — kept for every
/// office by SelectedCelebrationState. Radio buttons below the title, one
/// rank per line; nothing for a celebration whose rank can't change
/// (celebrationCanChangeRank).
class CelebrationRankSelector extends StatelessWidget {
  const CelebrationRankSelector({
    super.key,
    required this.celebrationMap,
    required this.selectedKey,
    required this.onPrecedenceOverridden,
  });

  final Map<String, CelebrationContext> celebrationMap;
  final String selectedKey;
  final void Function(String key, int? precedence) onPrecedenceOverridden;

  // The celebration's own rank (no override)
  static const _originalRank = 0;

  @override
  Widget build(BuildContext context) {
    final celebration = celebrationMap[selectedKey];
    if (!celebrationCanChangeRank(celebration)) return const SizedBox.shrink();
    final zoom = context.watch<CurrentZoom>().value;
    final theme = Theme.of(context);
    final isMemorial = (celebration!.precedence ?? 13) > 8;
    final override = context
            .watch<SelectedCelebrationState>()
            .getPrecedenceOverride(selectedKey) ??
        _originalRank;

    // From the celebration's own rank up to a solemnity
    final ranks = <int, String>{
      if (isMemorial) _originalRank: 'Mémoire (rang originel)',
      isMemorial ? 8 : _originalRank:
          isMemorial ? 'Fête' : 'Fête (rang originel)',
      4: 'Solennité',
    };
    final textStyle = TextStyle(fontSize: 13.0 * zoom / 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Changer le rang de la célébration :',
            style: textStyle.copyWith(color: theme.hintColor),
          ),
          SizedBox(height: 4.0 * zoom / 100),
          // One rank per line, indented under the title
          for (final MapEntry(key: rank, value: label) in ranks.entries)
            Padding(
              padding: EdgeInsets.only(left: 16.0 * zoom / 100),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: rank == override
                      ? null
                      : () => onPrecedenceOverridden(
                          selectedKey, rank == _originalRank ? null : rank),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rank == override
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 18 * zoom / 100,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(label, style: textStyle),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CommonSelector extends StatelessWidget {
  const CommonSelector({
    super.key,
    required this.commonList,
    required this.commonTitles,
    required this.selectedCommon,
    required this.precedence,
    required this.onCommonChanged,
    this.forceCommon = false,
    this.dayTextsDescription,
  });

  final List<String> commonList;
  final Map<String, String> commonTitles;
  final String? selectedCommon;
  final int precedence;
  final ValueChanged<String?> onCommonChanged;
  final bool forceCommon;
  // Lauds, Vespers and the Office of Readings: each choice says what it
  // brings below its whole title, "Pas de commun" first (see
  // _noCommonDescription), and a memorial's Commons what the day keeps
  // (dayPsalmody, dayPsalmodyAndReading). Without it, a Common's precision
  // goes below it, "Pas de commun" last.
  final String? dayTextsDescription;

  static const dayPsalmody = '+ psalmodie du jour';
  static const dayPsalmodyAndReading =
      '+ psalmodie et lecture biblique du jour';

  bool get _describeChoices => dayTextsDescription != null;

  // A memorial keeps the day's psalmody under its Common; a feast or a
  // solemnity, forced ones included, takes the Common's (see
  // CelebrationContext.isMemorial and composeOffice).
  bool get _keepsDayPsalmody => precedence > 9;

  static const _noCommonDescription =
      'Seulement textes propres au saint et oraison';

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
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

    final markColor = choiceMarkColor(context, null);
    final noCommonRow = ChoiceRow(
      title: 'Pas de commun',
      subtitle: _describeChoices ? _noCommonDescription : null,
      selected: selectedCommon == null,
      leading: const ChoiceDiamond(),
      markColor: markColor,
      boldTitle: false,
      onTap: () {
        if (selectedCommon != null) onCommonChanged(null);
      },
    );
    return ChoiceList(rows: [
      if (showNoCommon && _describeChoices) noCommonRow,
      for (final commonKey in commonList)
        () {
          final title = commonTitles[commonKey] ?? commonKey;
          // Elsewhere "Commun des Pasteurs (papes)" puts its precision below
          final (shortTitle, precision) = splitTrailingParenthesis(title);
          return ChoiceRow(
            title: _describeChoices ? title : shortTitle,
            subtitle: _describeChoices
                ? (_keepsDayPsalmody ? dayTextsDescription : null)
                : precision,
            selected: selectedCommon == commonKey,
            leading: const ChoiceDiamond(),
            markColor: markColor,
            boldTitle: false,
            onTap: () {
              if (selectedCommon != commonKey) onCommonChanged(commonKey);
            },
          );
        }(),
      if (showNoCommon && !_describeChoices) noCommonRow,
    ]);
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
    this.title,
    this.emptyMessage,
    this.shrinkWrap = false,
    this.footer,
  });

  final List<HymnEntry> hymns;
  // Section title shown above the hymn(s) — defaults to "Hymnes". Pass an
  // override for non-hymn uses of this same selector (e.g. the Mass
  // sequence, which is code-referenced and resolved exactly like a hymn but
  // shouldn't be labelled "Hymnes").
  final String? title;
  final String? emptyMessage;
  final bool shrinkWrap;

  /// Widget appended after the hymn content, only when [shrinkWrap] is
  /// false. Used to append [OfficeFooterWidget] when this is the last tab
  /// of an office (e.g. Compline's Marial hymns).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    if (hymns.isEmpty) {
      if (footer == null || shrinkWrap) {
        return Center(
          child: Text(emptyMessage ?? 'No hymn available'),
        );
      }
      final zoom = context.watch<CurrentZoom>().value;
      return ListView(
        padding: tabScrollPadding(context, zoom, shrinkWrap: shrinkWrap),
        children: [
          Center(child: Text(emptyMessage ?? 'No hymn available')),
          footer!,
        ],
      );
    }
    return HymnSelectorWithTitle(
      title: title ?? liturgyLabels['hymns'] ?? 'Hymnes',
      hymns: hymns,
      shrinkWrap: shrinkWrap,
      footer: footer,
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
    final hasSvg = svgData != null && svgData!.isNotEmpty;

    // Tab mode with SVG: CustomScrollView keeps the tone partition pinned while
    // the user scrolls through the psalm. The next psalm's header pushes it off.
    if (hasSvg && !shrinkWrap) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PsalmDisplayHeader(
              psalm: psalm,
              antiphon1: antiphon1,
              antiphon2: antiphon2,
              isScrollMode: false,
            ),
          ),
          SliverStickyHeader(
            header: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: PsalmToneWidget(svgData: svgData!),
            ),
            sliver: SliverToBoxAdapter(
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
          ),
          SliverToBoxAdapter(child: SizedBox(height: 24.0 * zoom / 100)),
        ],
      );
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: tabScrollPadding(context, zoom,
          shrinkWrap: shrinkWrap,
          base: EdgeInsets.only(bottom: 16.0 * zoom / 100)),
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

/// Height of the system navigation bar drawn over the bottom of the screen.
/// Android 15+ enforces edge-to-edge and the home page's SafeArea leaves the
/// bottom free, so the office scroll views add it after their last line: the
/// text scrolls under the bar but can always be brought above it.
/// [MediaQuery.viewPaddingOf] rather than paddingOf so it doesn't jump when
/// the keyboard opens.
double officeBottomInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).bottom;

/// Padding for a standalone tab's [ListView]. Applies [base] plus a bottom
/// spacer so the text doesn't sit flush against the bottom of the screen,
/// above the system navigation bar ([officeBottomInset]).
/// Returns [EdgeInsets.zero] when [shrinkWrap] is true (the widget is
/// embedded in the scroll-mode page, which keeps its original spacing and
/// only gets a trailing spacer once, at the very end of the page).
EdgeInsetsGeometry tabScrollPadding(
  BuildContext context,
  double zoom, {
  required bool shrinkWrap,
  EdgeInsets base = EdgeInsets.zero,
}) {
  if (shrinkWrap) return EdgeInsets.zero;
  return base.add(
      EdgeInsets.only(bottom: 24.0 * zoom / 100 + officeBottomInset(context)));
}

String? officeAdditionalInfo(
    String? liturgicalTime, Calendar calendar, DateTime date) {
  final dayContent = calendar.getDayContent(date);
  if (liturgicalTime == 'christmasoctave') {
    // Dec 26-28 (Étienne, Jean, Saints Innocents) have their own full proper
    // office. Some years the Sainte Famille also lands within Dec 29-31
    // (e.g. Noël un mardi -> 30 déc.) and likewise has its own proper office.
    // Outside of those, Dec 29-31 borrow everything (psalmodie, hymne,
    // lecture brève) from the Nativity octave itself — only an optional
    // commemoration's oration/antienne, if any, is proper to that day.
    final isGenericOctaveDay = dayContent != null &&
        date.month == 12 &&
        date.day >= 29 &&
        date.day <= 31 &&
        dayContent.defaultCelebrationTitle != 'roman/holy_family';
    return isGenericOctaveDay
        ? "Repris de l'office de l'octave de la Nativité"
        : null;
  }
  if (liturgicalTime == 'paschaloctave') {
    return null;
  }
  if (dayContent == null) return null;
  final year = sundayCycle(dayContent.liturgicalYear);
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
                height: 1.2,
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

/// A traditional liturgical text (Notre Père, Confiteor, séquence...)
/// collapsed by default behind its title, expanded on tap — spares screen
/// space for texts the reader usually knows by heart. Shared by Vespers'
/// and Morning's Our Father, Compline's Confiteor, and the Mass's sequence.
class CollapsibleLiturgyText extends StatelessWidget {
  const CollapsibleLiturgyText({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
  });

  final String title;
  // E.g. a sequence hymn's author — shown in italic above the content.
  final String? subtitle;
  final String content;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: LiturgyPartTitle(title,
            left: LiturgyRowLeft.indent, topPadding: false),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        minTileHeight: 0,
        collapsedTextColor: Theme.of(context).textTheme.headlineSmall?.color,
        textColor: Theme.of(context).textTheme.headlineSmall?.color,
        collapsedIconColor: Theme.of(context).iconTheme.color,
        iconColor: Theme.of(context).iconTheme.color,
        children: [
          LiturgyRow(
            left: LiturgyRowLeft.none,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  Opacity(
                    opacity: 0.7,
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10 * zoom / 100,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                  SizedBox(height: 8 * zoom / 100),
                ],
                HymnContentDisplay(content: content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
