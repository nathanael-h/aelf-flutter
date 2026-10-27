import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:offline_liturgy/tools/date_tools.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/localSolemnitiesState.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_frame.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/choice_selectors.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_selector.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_widget.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

/// ============================================
/// CELEBRATION AND COMMON SELECTORS
/// ============================================

/// The office's name ("Laudes", "Vêpres"...) heading its Office tab, in
/// bold small capitals, above the ornament of psalm antiphons.
class OfficeNameHeader extends StatelessWidget {
  const OfficeNameHeader(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return Padding(
      padding:
          EdgeInsets.only(top: 12.0 * zoom / 100, bottom: 12.0 * zoom / 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LiturgyRow(
            builder: (context, _) => Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0 * zoom / 100,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature('smcp')],
              ),
            ),
          ),
          SizedBox(height: 4.0 * zoom / 100),
          const AntiphonSeparator(),
        ],
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
    this.onPrecedenceOverridden,
    this.eveCandidates = const {},
  });

  final Map<String, CelebrationContext> celebrationMap;
  final String selectedKey;
  final ValueChanged<String> onCelebrationChanged;
  // A long press on a memorial or a feast (canToggleLocalSolemnity) makes
  // it a local solemnity (e.g. the titular of the place), another brings it
  // back to its own rank
  final void Function(String key, int? precedence)? onPrecedenceOverridden;
  // See EveCandidatesList
  final Map<String, CelebrationContext> eveCandidates;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final localSolemnities = context.watch<LocalSolemnitiesState>();

    final celebrableEntries =
        celebrationMap.entries.where((e) => e.value.isCelebrable).toList();
    final nonCelebrableEntries = celebrationMap.entries
        .where((e) =>
            !e.value.isCelebrable &&
            e.value.celebrationCode != e.value.ferialCode)
        .toList();

    final hasNonCelebrable = nonCelebrableEntries.isNotEmpty;
    final hasRaisableRows = onPrecedenceOverridden != null &&
        celebrableEntries
            .any((e) => canToggleLocalSolemnity(localSolemnities, e.value));
    final hasEveCandidates =
        onPrecedenceOverridden != null && eveCandidates.isNotEmpty;

    ChoiceRow buildRow(MapEntry<String, CelebrationContext> entry,
            {bool muted = false}) =>
        _celebrationRow(
          context,
          entry,
          selected: entry.key == selectedKey,
          muted: muted,
          onTap: () {
            if (entry.key == selectedKey) return;
            onCelebrationChanged(entry.key);
          },
          onPrecedenceOverridden: onPrecedenceOverridden,
        );

    final rowsWidget =
        ChoiceList(rows: [for (final e in celebrableEntries) buildRow(e)]);

    if (!hasRaisableRows && !hasNonCelebrable && !hasEveCandidates) {
      return rowsWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        rowsWidget,
        if (hasRaisableRows) const _LocalSolemnityHint(),
        if (hasEveCandidates)
          EveCandidatesList(
            candidates: eveCandidates,
            onPrecedenceOverridden: onPrecedenceOverridden!,
          ),
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

/// A celebration's row in a selector: its rank below its name ("Solennité
/// forcée" for a local solemnity), and a long press making it a local
/// solemnity or bringing it back (canToggleLocalSolemnity). [title], when
/// given, in place of its office's description.
ChoiceRow _celebrationRow(
  BuildContext context,
  MapEntry<String, CelebrationContext> entry, {
  required bool selected,
  required VoidCallback? onTap,
  String? title,
  bool muted = false,
  void Function(String key, int? precedence)? onPrecedenceOverridden,
}) {
  final localSolemnities = context.read<LocalSolemnitiesState>();
  final celebration = entry.value;
  // The rank, e.g. "Mémoire facultative" or "Europe : solennité": the
  // label's parenthesis alone, as in "(Mémoire facultative)"
  final typeLabel = localSolemnities.isLocalSolemnity(celebration)
      ? 'Solennité forcée'
      : celebration.celebrationDisplayLabel.replaceAll(RegExp(r'^\(|\)$'), '');

  return ChoiceRow(
    title: title ?? celebration.officeDescription ?? '',
    subtitle: typeLabel,
    selected: selected,
    showDot: true,
    dotColor: celebration.liturgicalColor,
    markColor: choiceMarkColor(context, celebration.liturgicalColor),
    barColor: getLiturgicalColor(celebration.liturgicalColor),
    boldTitle: false,
    muted: muted,
    onTap: onTap,
    onLongPress: onPrecedenceOverridden == null ||
            !canToggleLocalSolemnity(localSolemnities, celebration)
        ? null
        : () => toggleLocalSolemnity(
            context, entry.key, celebration, onPrecedenceOverridden),
  );
}

class _LocalSolemnityHint extends StatelessWidget {
  const _LocalSolemnityHint(
      [this.text = 'Appui long : passage en solennité locale']);

  final String text;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(16.0, 6.0 * zoom / 100, 16.0, 6.0 * zoom / 100),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 11.0 * zoom / 100,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Vespers: a link showing tomorrow's memorials and feasts, whose First
/// Vespers are only prayed once one is made a local solemnity — by a long
/// press on its row, which LiturgyState then lists among the Vespers.
class EveCandidatesList extends StatefulWidget {
  const EveCandidatesList({
    super.key,
    required this.candidates,
    required this.onPrecedenceOverridden,
  });

  final Map<String, CelebrationContext> candidates;
  final void Function(String key, int? precedence) onPrecedenceOverridden;

  @override
  State<EveCandidatesList> createState() => _EveCandidatesListState();
}

class _EveCandidatesListState extends State<EveCandidatesList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) return const SizedBox.shrink();
    final zoom = context.watch<CurrentZoom>().value;
    final accent = Theme.of(context).colorScheme.secondary;
    return SelectionContainer.disabled(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0 * zoom / 100),
              child: Row(
                children: [
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18 * zoom / 100, color: accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _expanded
                          ? 'Masquer les fêtes et mémoires de demain'
                          : 'Afficher les fêtes et mémoires de demain',
                      style:
                          TextStyle(color: accent, fontSize: 13.0 * zoom / 100),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            ChoiceList(rows: [
              for (final entry in widget.candidates.entries)
                _celebrationRow(
                  context,
                  entry,
                  selected: false,
                  // The feast's name, its First Vespers being only prayed
                  // once it is made a local solemnity
                  title: entry.value.celebrationGlobalName,
                  muted: true,
                  onTap: null,
                  onPrecedenceOverridden: widget.onPrecedenceOverridden,
                ),
            ]),
            const _LocalSolemnityHint('Appui long : passage en solennité '
                'locale et affichage des Premières Vêpres'),
          ],
        ],
      ),
    );
  }
}

/// Whether [celebration], as detected (at its own rank), may be celebrated
/// as a local solemnity (see toggleLocalSolemnity): a memorial or a feast
/// replacing the day — not a solemnity, a ferial day, nor the Saturday
/// memory of the Virgin Mary.
bool celebrationCanChangeRank(CelebrationContext? celebration) =>
    celebration != null &&
    celebration.celebrationCode != celebration.ferialCode &&
    celebration.celebrationCode != 'roman/virgin_mary_memory' &&
    (celebration.precedence ?? 13) > 4;

/// Whether [celebration] may be made a local solemnity
/// (celebrationCanChangeRank), or is one and may be brought back — the
/// evening offices detect it at its new rank.
bool canToggleLocalSolemnity(LocalSolemnitiesState localSolemnities,
        CelebrationContext? celebration) =>
    celebration != null &&
    (celebrationCanChangeRank(celebration) ||
        localSolemnities.isLocalSolemnity(celebration));

/// Makes [celebration] (the row [key]) the local solemnity of its day (e.g.
/// the titular of the place), or brings it back to its own rank if it
/// already is one — kept for every office by LocalSolemnitiesState.
void toggleLocalSolemnity(
    BuildContext context,
    String key,
    CelebrationContext celebration,
    void Function(String key, int? precedence) onPrecedenceOverridden) {
  final isSolemnity =
      context.read<LocalSolemnitiesState>().isLocalSolemnity(celebration);
  if (isSolemnity) {
    HapticFeedback.lightImpact();
    onPrecedenceOverridden(key, null);
  } else {
    HapticFeedback.heavyImpact();
    onPrecedenceOverridden(key, 4);
  }
}

/// Below the title of a memorial or a feast with no celebration selector —
/// so no row to long-press (see CelebrationSelector): a checkbox making it a
/// local solemnity, unchecked to bring it back to its own rank. Nothing for
/// a celebration whose rank can't change (canToggleLocalSolemnity).
class LocalSolemnityButton extends StatelessWidget {
  const LocalSolemnityButton({
    super.key,
    required this.celebrationMap,
    required this.selectedKey,
    required this.onPrecedenceOverridden,
  });

  final Map<String, CelebrationContext> celebrationMap;
  final String selectedKey;
  final void Function(String key, int? precedence) onPrecedenceOverridden;

  @override
  Widget build(BuildContext context) {
    final localSolemnities = context.watch<LocalSolemnitiesState>();
    final celebration = celebrationMap[selectedKey];
    if (celebration == null ||
        !canToggleLocalSolemnity(localSolemnities, celebration)) {
      return const SizedBox.shrink();
    }
    final zoom = context.watch<CurrentZoom>().value;
    final isSolemnity = localSolemnities.isLocalSolemnity(celebration);
    final accent = Theme.of(context).colorScheme.secondary;
    return SelectionContainer.disabled(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => toggleLocalSolemnity(
                context, selectedKey, celebration, onPrecedenceOverridden),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSolemnity
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 18 * zoom / 100,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Solennité locale',
                      style: TextStyle(fontSize: 13.0 * zoom / 100),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

/// Above a reading offering several choices (a Mass reading, the Office of
/// Readings' biblical or patristic one): a ChoiceList of them — each a
/// title (a reference, an author) and a subtitle —, the selected one being
/// the only text shown below. Up to [_alwaysVisibleMax] choices the list is
/// always visible; beyond (a Common's long lists), it folds under a
/// "Choisir parmi N [noun]" header that shows the current choice.
class ReadingChoiceSelector extends StatefulWidget {
  const ReadingChoiceSelector({
    super.key,
    required this.label,
    required this.noun,
    required this.choices,
    required this.selectedIndex,
    required this.liturgicalColor,
    required this.onSelected,
    this.boldTitles = true,
  });

  // The reading's name, e.g. "Première lecture"
  final String label;
  // What the folded header counts, e.g. "lectures"
  final String noun;
  // Each choice's title and subtitle; blank ones are null
  final List<(String?, String?)> choices;
  final int selectedIndex;
  final String? liturgicalColor;
  final ValueChanged<int> onSelected;
  // False for long titles in capitals (a patristic reading's author)
  final bool boldTitles;

  static const _alwaysVisibleMax = 4;

  @override
  State<ReadingChoiceSelector> createState() => _ReadingChoiceSelectorState();
}

class _ReadingChoiceSelectorState extends State<ReadingChoiceSelector> {
  bool _expanded = false;

  bool get _isFoldable =>
      widget.choices.length > ReadingChoiceSelector._alwaysVisibleMax;

  void _select(int index) {
    if (_isFoldable) setState(() => _expanded = false);
    if (index != widget.selectedIndex) widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final count = widget.choices.length;

    return SelectionContainer.disabled(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.0 * zoom / 100),
          if (_isFoldable)
            _buildFoldHeader(context, zoom, count)
          else
            OfficeSectionTitle('${widget.label} — $count choix possibles'),
          if (!_isFoldable || _expanded) _buildList(context),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildFoldHeader(BuildContext context, double zoom, int count) {
    final (title, subtitle) = widget
        .choices[widget.selectedIndex.clamp(0, widget.choices.length - 1)];
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0 * zoom / 100),
        child: LiturgyRow(
          builder: (context, _) => Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choisir parmi $count ${widget.noun}',
                      style: TextStyle(
                        fontSize: 15 * zoom / 100,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [title, subtitle].whereType<String>().join(' — '),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12 * zoom / 100,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final markColor = choiceMarkColor(context, widget.liturgicalColor);
    return ChoiceList(rows: [
      for (final (i, (title, subtitle)) in widget.choices.indexed)
        ChoiceRow(
          title: title ?? '${i + 1}',
          subtitle: subtitle,
          selected: i == widget.selectedIndex,
          markColor: markColor,
          boldTitle: widget.boldTitles,
          onTap: () => _select(i),
        ),
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
