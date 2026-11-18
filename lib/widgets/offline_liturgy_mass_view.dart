import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/libraries/biblical_book_labels.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/reading_margin.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/base_office_view_state.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_footer_widget.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_header_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_frame.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/choice_selectors.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';

/// Main entry point for the Mass view.
class MassView extends StatefulWidget {
  const MassView(
      {super.key,
      required this.massList,
      required this.date,
      required this.calendar});

  final Map<String, CelebrationContext> massList;
  final DateTime date;
  final Calendar calendar;

  @override
  State<MassView> createState() => _MassViewState();
}

class _MassViewState extends BaseOfficeViewState<MassView, Mass> {
  @override
  Map<String, CelebrationContext> get celebrationList => widget.massList;

  @override
  DateTime get date => widget.date;

  @override
  Calendar get calendar => widget.calendar;

  @override
  String get debugOfficeName => 'Mass';

  @override
  bool hasInputChanged(MassView oldWidget) =>
      oldWidget.date != widget.date || oldWidget.massList != widget.massList;

  // Where the selected memorial's readings come from (see
  // MassReadingSource). Held here rather than in MassOfficeDisplay, which
  // a reload (e.g. another Common) recreates: it must survive those, and
  // only go back to the day's readings for another Mass (see exportOffice).
  MassReadingSource _readingSource = MassReadingSource.day;
  String? _readingSourceMass;

  @override
  Future<Mass> exportOffice(CelebrationContext ctx) {
    final mass = '${ctx.celebrationCode} ${ctx.massName}';
    if (mass != _readingSourceMass) {
      _readingSource = MassReadingSource.day;
      _readingSourceMass = mass;
    }
    return massExport(ctx.copyWith(
      massReadingSource: ctx.massReadingSources.contains(_readingSource)
          ? _readingSource
          : MassReadingSource.day,
    ));
  }

  // Sets the reading source without reloading on its own — the texts
  // choice selector always follows it with an onCommonChanged call (even
  // when the Common itself doesn't change), which does the single reload
  // with both settled together (see _MassTextsChoiceSelector, exportOffice).
  void _onReadingSourceChanged(MassReadingSource source) {
    _readingSource = source;
  }

  @override
  Widget buildOfficeDisplay(
    BuildContext context, {
    required String celebrationKey,
    required CelebrationContext definition,
    required Mass officeData,
    required String? selectedCommon,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
    required void Function(String, int?) onPrecedenceOverridden,
  }) {
    return MassOfficeDisplay(
      celebrationKey: celebrationKey,
      massDefinition: definition,
      massData: officeData,
      selectedCommon: selectedCommon,
      massList: widget.massList,
      onCelebrationChanged: onCelebrationChanged,
      onCommonChanged: onCommonChanged,
      onPrecedenceOverridden: onPrecedenceOverridden,
      readingSource: _readingSource,
      onReadingSourceChanged: _onReadingSourceChanged,
      calendar: widget.calendar,
      date: widget.date,
    );
  }
}

/// Returns the tab-bar label for each readingPart, in the order the data
/// provides them. This is the tab-only label (see _readingPartTabLabel).
/// Content titles must use _readingPartBaseLabel instead (see its doc) to
/// avoid double-appending a psalm number.
List<String> _readingPartLabels(List<MassReadingPart> parts) {
  return [for (final part in parts) _readingPartTabLabel(part)];
}

/// readingsTypeLabels[part.partType], falling back to the raw partType —
/// the base title passed down to each alternative content item of the part
/// (see _ReadingPartTab/_MassPsalmContent). PSALM items each add their own
/// psalm number / biblical reference on top of this individually,
/// since a part can hold several alternative propositions with different
/// numbers/references — unlike _readingPartTabLabel, this carries no number
/// so that appending doesn't double it up.
String _readingPartBaseLabel(MassReadingPart part) =>
    readingsTypeLabels[part.partType] ?? part.partType;

/// _readingPartBaseLabel(part) for the tab strip. A single PSALM proposition
/// adds its own number/reference, e.g. "Psaume 103" or "Cantique (Ex 15)" —
/// matching _massPsalmDisplayTitle; several only show "Psaume" (or
/// "Cantique" when they all are), the choice being made in the tab (see
/// ReadingChoiceSelector). Only meant for display in the tab strip (see
/// _readingPartLabels) — content titles must use _readingPartBaseLabel.
String _readingPartTabLabel(MassReadingPart part) {
  final baseLabel = _readingPartBaseLabel(part);
  final psalms = part.partContents.whereType<MassPsalm>().toList();
  if (psalms.isEmpty) return baseLabel;
  if (psalms.length == 1) {
    return _massPsalmDisplayTitle(baseLabel, psalms.single);
  }
  return psalms.every(_isCanticle) ? _canticleLabel : baseLabel;
}

/// Whether [part] offers several choices, one to select — but the Gospel
/// acclamation's, all shown one after another (see _MassAcclamationContent).
bool _offersChoices(MassReadingPart part) =>
    part.partContents.length > 1 && part.partType != 'ALLELUIA';

/// _readingPartBaseLabel(part) above a part's several choices, or "Psaume
/// ou cantique" when they mix both (see _isCanticle), "Cantique" when all
/// are canticles.
String _choiceSelectorLabel(MassReadingPart part) {
  final baseLabel = _readingPartBaseLabel(part);
  final psalms = part.partContents.whereType<MassPsalm>();
  if (!psalms.any(_isCanticle)) return baseLabel;
  return psalms.every(_isCanticle)
      ? _canticleLabel
      : '$baseLabel ou ${_canticleLabel.toLowerCase()}';
}

/// Returns a synthetic MassReadingPart holding only the forme brève (short
/// form) of each content item in [part] that has one — biblicalRef/content
/// swapped for their short* counterparts — or null if none do. Psalms have
/// no short-form concept and are always skipped. Used to reuse
/// _ReadingPartTab's rendering (including its "ou" alternation between
/// several contents) for the short-form block, instead of a parallel widget.
MassReadingPart? _shortFormPart(MassReadingPart part) {
  final shortContents = <MassReadingContent>[];
  for (final content in part.partContents) {
    switch (content) {
      case MassReading r:
        if (r.shortReadingContent?.isNotEmpty ?? false) {
          shortContents.add(MassReading(
            biblicalRef: r.shortReadingRef,
            content: r.shortReadingContent,
          ));
        }
      case MassGospel g:
        if (g.shortContent?.isNotEmpty ?? false) {
          shortContents.add(MassGospel(
            biblicalRef: g.shortBiblicalRef,
            content: g.shortContent,
            headline: g.headline,
            acclamationAntiphon: g.acclamationAntiphon,
            acclamationAntiphonReference: g.acclamationAntiphonReference,
          ));
        }
      case MassPsalm _:
        break;
    }
  }
  if (shortContents.isEmpty) return null;
  return MassReadingPart(partType: part.partType, partContents: shortContents);
}

/// Handles the TabBar navigation and layout of the Mass Office.
class MassOfficeDisplay extends StatefulWidget {
  const MassOfficeDisplay({
    super.key,
    required this.celebrationKey,
    required this.massDefinition,
    required this.massData,
    required this.selectedCommon,
    required this.massList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.readingSource,
    required this.onReadingSourceChanged,
    required this.calendar,
    required this.date,
  });

  final String celebrationKey;
  final CelebrationContext massDefinition;
  final Mass massData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> massList;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;
  final void Function(String key, int? precedence) onPrecedenceOverridden;
  // Where a memorial's readings come from, among the sources it offers
  // (massDefinition.massReadingSources, see _OfficeTab) — massData was
  // exported with it; a change reloads the Mass (see _MassViewState).
  final MassReadingSource readingSource;
  final ValueChanged<MassReadingSource> onReadingSourceChanged;
  final Calendar calendar;
  final DateTime date;

  @override
  State<MassOfficeDisplay> createState() => _MassOfficeDisplayState();
}

class _MassOfficeDisplayState extends State<MassOfficeDisplay> {
  // Reading-part index -> the index of its selected choice, for the parts
  // offering several (see ReadingChoiceSelector); a part absent from the
  // map shows its first one. Reset with the readings themselves.
  final Map<int, int> _selectedChoices = {};

  @override
  void didUpdateWidget(MassOfficeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.massData != oldWidget.massData) _selectedChoices.clear();
  }

  bool get _hasMultipleCelebrations => hasCelebrationChoice(
      context.watch<FeatureFlagsState>().advancedModeEnabled, widget.massList);

  // A feast alone has no celebration selector to long-press: its title
  // offers the passage to a local solemnity instead
  Widget? get _localSolemnityButton => _hasMultipleCelebrations
      ? null
      : LocalSolemnityButton(
          celebrationMap: widget.massList,
          selectedKey: widget.celebrationKey,
          onPrecedenceOverridden: widget.onPrecedenceOverridden,
        );

  // Which Common, once the texts choice (_needsTextsChoice) has settled on
  // using one at all (selectedCommon != null) — moot with a single one.
  bool get _needsCommonSelection {
    if (widget.selectedCommon == null) return false;
    final d = widget.massDefinition;
    if ((d.commonList?.length ?? 0) < 2) return false;
    if (['paschaloctave', 'christmasoctave'].contains(d.liturgicalTime)) {
      return false;
    }
    return true;
  }

  // Whether this memorial offers a choice between using a Common at all —
  // replacing the Office's celebration/common selectors (see
  // office_common_widgets.dart), which simplified mode hides the same way.
  bool get _needsTextsChoice {
    final d = widget.massDefinition;
    return (d.precedence ?? 13) > 9 &&
        d.celebrationCode != d.ferialCode &&
        (d.commonList?.isNotEmpty ?? false);
  }

  // Simplified mode never offers a common or texts choice here, which then
  // stays at its default (MassReadingSource.day, no Common — see
  // _MassViewState.exportOffice and BaseOfficeViewState._defaultCommon) —
  // so that part of the tab/section would be empty, never shown for that
  // reason in that mode. A celebration choice (_hasMultipleCelebrations)
  // can still apply, though: several obligatory memorials colliding the
  // same day.
  bool get _hasOfficeTab {
    if (_hasMultipleCelebrations) return true;
    if (!context.watch<FeatureFlagsState>().advancedModeEnabled) return false;
    return _needsTextsChoice || _needsCommonSelection;
  }

  bool get _hasOfferingTab =>
      widget.massData.offeringPrayer?.isNotEmpty ?? false;

  /// The reading parts as displayed: a part offering several choices is
  /// reduced to its selected one (see _selectedChoices).
  List<MassReadingPart> get _displayedParts => [
        for (final (i, part) in (widget.massData.readingParts ?? []).indexed)
          _offersChoices(part)
              ? MassReadingPart(partType: part.partType, partContents: [
                  part.partContents[(_selectedChoices[i] ?? 0)
                      .clamp(0, part.partContents.length - 1)]
                ])
              : part,
      ];

  /// The choice selector shown above part [i]'s text, or null when [part]
  /// (as provided by the data, before _displayedParts) offers a single one.
  Widget? _choiceSelector(int i, MassReadingPart part) => _offersChoices(part)
      ? ReadingChoiceSelector(
          label: _choiceSelectorLabel(part),
          choices: [for (final c in part.partContents) _choiceTexts(c)],
          selectedIndex: _selectedChoices[i] ?? 0,
          liturgicalColor: widget.massDefinition.liturgicalColor,
          onSelected: (choice) => setState(() => _selectedChoices[i] = choice),
        )
      : null;

  /// Reading-part index -> its short-form (forme brève) projection, for the
  /// parts whose selected choice has one. See _shortFormPart.
  Map<int, MassReadingPart> get _shortFormParts {
    final parts = _displayedParts;
    final result = <int, MassReadingPart>{};
    for (var i = 0; i < parts.length; i++) {
      final shortPart = _shortFormPart(parts[i]);
      if (shortPart != null) result[i] = shortPart;
    }
    return result;
  }

  bool get _hasCommunionTab =>
      (widget.massData.communionAntiphon?.isNotEmpty ?? false) ||
      (widget.massData.prayerAfterCommunion?.isNotEmpty ?? false) ||
      (widget.massData.prayerOnThePeople?.isNotEmpty ?? false) ||
      (widget.massData.solemnBlessingList?.isNotEmpty ?? false);

  // The proper sequence (e.g. Victimae Paschali Laudes, Veni Sancte
  // Spiritus) — optional, only a handful of days a year.
  bool get _hasSequence => widget.massData.sequence?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    if (context.watch<LiturgyState>().useScrollMode) {
      return _buildScrollView(context);
    }
    return DefaultTabController(
      length: _calculateTabCount(),
      child: Column(
        children: [
          LiturgyTabBar(tabs: _buildTabs()),
          Expanded(
            child: PinchZoomSelectionArea(
              child: TabBarView(children: _buildTabViews(context)),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTabCount() {
    final readingTabs = widget.massData.readingParts?.length ?? 0;
    return 1 + // "Ouverture" tab
        readingTabs +
        _shortFormParts.length +
        (_hasSequence ? 1 : 0) +
        (_hasOfficeTab ? 1 : 0) +
        (_hasOfferingTab ? 1 : 0) +
        (_hasCommunionTab ? 1 : 0);
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[];
    if (_hasOfficeTab) {
      tabs.add(Tab(text: liturgyLabels['office'] ?? 'Office'));
    }
    tabs.add(const Tab(text: 'Ouverture'));
    final labels = _readingPartLabels(widget.massData.readingParts ?? []);
    final shortForms = _shortFormParts;
    if (_hasSequence && labels.isEmpty) {
      tabs.add(Tab(text: liturgyLabels['sequence'] ?? 'Séquence'));
    }
    for (var i = 0; i < labels.length; i++) {
      // The sequence is sung right before the Gospel acclamation, which is
      // always the last reading part — see _readingPartLabels.
      if (_hasSequence && i == labels.length - 1) {
        tabs.add(Tab(text: liturgyLabels['sequence'] ?? 'Séquence'));
      }
      tabs.add(Tab(text: labels[i]));
      if (shortForms.containsKey(i)) {
        tabs.add(Tab(text: '${labels[i]} (forme brève)'));
      }
    }
    if (_hasOfferingTab) tabs.add(const Tab(text: 'Offrandes'));
    if (_hasCommunionTab) tabs.add(const Tab(text: 'Communion'));
    return tabs;
  }

  List<Widget> _buildTabViews(BuildContext context) {
    final views = <Widget>[];
    if (_hasOfficeTab) {
      views.add(
        _OfficeTab(
          celebrationKey: widget.celebrationKey,
          massDefinition: widget.massDefinition,
          massList: widget.massList,
          selectedCommon: widget.selectedCommon,
          onCelebrationChanged: widget.onCelebrationChanged,
          onCommonChanged: widget.onCommonChanged,
          onPrecedenceOverridden: widget.onPrecedenceOverridden,
          hasMultipleCelebrations: _hasMultipleCelebrations,
          needsCommonSelection: _needsCommonSelection,
          needsTextsChoice: _needsTextsChoice,
          readingSource: widget.readingSource,
          onReadingSourceChanged: widget.onReadingSourceChanged,
        ),
      );
    }
    final allParts = widget.massData.readingParts ?? [];
    final parts = _displayedParts;
    final shortForms = _shortFormParts;
    // Which section ends up rendering the last tab overall, so only that
    // tab's footer ornament (see OfficeFooterWidget) is shown — matching the
    // other offices, where it's attached to their single, fixed last tab.
    final hasReadingSection =
        parts.isNotEmpty || (_hasSequence && parts.isEmpty);
    final introIsLast =
        !hasReadingSection && !_hasOfferingTab && !_hasCommunionTab;
    final readingSectionIsLast =
        hasReadingSection && !_hasOfferingTab && !_hasCommunionTab;
    final offeringIsLast = _hasOfferingTab && !_hasCommunionTab;

    views.add(_IntroductionTab(
      belowTitle: _localSolemnityButton,
      massDefinition: widget.massDefinition,
      massData: widget.massData,
      calendar: widget.calendar,
      date: widget.date,
      showFooter: introIsLast,
    ));
    if (_hasSequence && parts.isEmpty) {
      views.add(_MassSequenceTab(
        sequence: widget.massData.sequence!,
        showFooter: readingSectionIsLast,
      ));
    }
    for (var i = 0; i < parts.length; i++) {
      final isLastPart = i == parts.length - 1;
      if (_hasSequence && isLastPart) {
        views.add(_MassSequenceTab(sequence: widget.massData.sequence!));
      }
      final shortPart = shortForms[i];
      final isLastInReadingSection = readingSectionIsLast && isLastPart;
      views.add(_ReadingPartTab(
        part: parts[i],
        label: _readingPartBaseLabel(parts[i]),
        liturgicalTime: widget.massDefinition.liturgicalTime,
        choiceSelector: _choiceSelector(i, allParts[i]),
        showFooter: isLastInReadingSection && shortPart == null,
      ));
      if (shortPart != null) {
        views.add(_ReadingPartTab(
          part: shortPart,
          label: '${_readingPartBaseLabel(parts[i])} (forme brève)',
          liturgicalTime: widget.massDefinition.liturgicalTime,
          isShortForm: true,
          hideAlleluiaInShortForm: false,
          showFooter: isLastInReadingSection,
        ));
      }
    }
    if (_hasOfferingTab) {
      views.add(_OfferingTab(
        massData: widget.massData,
        showFooter: offeringIsLast,
      ));
    }
    if (_hasCommunionTab) {
      views.add(_CommunionTab(massData: widget.massData, showFooter: true));
    }
    return views;
  }

  Widget _buildScrollView(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final allParts = widget.massData.readingParts ?? [];
    final parts = _displayedParts;
    final shortForms = _shortFormParts;
    final shortFormKeys = {
      for (final i in shortForms.keys) i: GlobalKey(),
    };

    return PinchZoomSelectionArea.scrollAnchored(
      builder: (context, scrollController) => CustomScrollView(
        controller: scrollController,
        slivers: [
          // Inside the scroll view, so the scrollbar stays on the screen
          // edge and the margins still scroll.
          SliverPadding(
            padding:
                EdgeInsets.symmetric(horizontal: officeSideMargin(context)),
            sliver: SliverMainAxisGroup(slivers: [
              if (_hasOfficeTab)
                SliverToBoxAdapter(
                  child: _OfficeTab(
                    celebrationKey: widget.celebrationKey,
                    massDefinition: widget.massDefinition,
                    massList: widget.massList,
                    selectedCommon: widget.selectedCommon,
                    onCelebrationChanged: widget.onCelebrationChanged,
                    onCommonChanged: widget.onCommonChanged,
                    onPrecedenceOverridden: widget.onPrecedenceOverridden,
                    hasMultipleCelebrations: _hasMultipleCelebrations,
                    needsCommonSelection: _needsCommonSelection,
                    needsTextsChoice: _needsTextsChoice,
                    readingSource: widget.readingSource,
                    onReadingSourceChanged: widget.onReadingSourceChanged,
                    shrinkWrap: true,
                  ),
                ),
              SliverToBoxAdapter(
                child: _IntroductionTab(
                  belowTitle: _localSolemnityButton,
                  massDefinition: widget.massDefinition,
                  massData: widget.massData,
                  calendar: widget.calendar,
                  date: widget.date,
                  shrinkWrap: true,
                ),
              ),
              if (_hasSequence && parts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.0 * zoom / 100),
                    child: _MassSequenceTab(
                      sequence: widget.massData.sequence!,
                      shrinkWrap: true,
                    ),
                  ),
                ),
              for (var i = 0; i < parts.length; i++) ...[
                // The sequence is sung right before the Gospel acclamation,
                // which is always the last reading part.
                if (_hasSequence && i == parts.length - 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0 * zoom / 100),
                      child: _MassSequenceTab(
                        sequence: widget.massData.sequence!,
                        shrinkWrap: true,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: i > 0 ? 8.0 * zoom / 100 : 0),
                    child: _ReadingPartTab(
                      part: parts[i],
                      label: _readingPartBaseLabel(parts[i]),
                      liturgicalTime: widget.massDefinition.liturgicalTime,
                      shrinkWrap: true,
                      choiceSelector: _choiceSelector(i, allParts[i]),
                      shortFormAnnouncement: shortFormKeys.containsKey(i)
                          ? _ShortFormAnnouncement(targetKey: shortFormKeys[i]!)
                          : null,
                    ),
                  ),
                ),
                if (shortFormKeys.containsKey(i))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0 * zoom / 100),
                      child: _ReadingPartTab(
                        key: shortFormKeys[i],
                        part: shortForms[i]!,
                        label:
                            '${_readingPartBaseLabel(parts[i])} (forme brève)',
                        liturgicalTime: widget.massDefinition.liturgicalTime,
                        shrinkWrap: true,
                        isShortForm: true,
                      ),
                    ),
                  ),
              ],
              if (_hasOfferingTab)
                SliverToBoxAdapter(
                    child: _OfferingTab(
                        massData: widget.massData, shrinkWrap: true)),
              if (_hasCommunionTab)
                SliverToBoxAdapter(
                    child: _CommunionTab(
                        massData: widget.massData, shrinkWrap: true)),
              const SliverToBoxAdapter(child: OfficeFooterWidget()),
            ]),
          ),
        ],
      ),
    );
  }
}

/// The Mass's proper sequence (e.g. Stabat Mater, Victimae Paschali Laudes),
/// sung right before the Gospel acclamation. Collapsed by default like the
/// Our Father — see CollapsibleLiturgyText. Current data never proposes more
/// than one sequence for a given day, so only the first entry is rendered.
class _MassSequenceTab extends StatelessWidget {
  const _MassSequenceTab({
    required this.sequence,
    this.shrinkWrap = false,
    this.showFooter = false,
  });

  final List<HymnEntry> sequence;
  final bool shrinkWrap;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final entry = sequence.first;
    final hymn = entry.hymnData;
    final baseTitle = liturgyLabels['sequence'] ?? 'Séquence';

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: tabScrollPadding(zoom,
          shrinkWrap: shrinkWrap,
          base: EdgeInsets.only(bottom: 16.0 * zoom / 100)),
      children: [
        if (hymn == null)
          Center(child: Text('Hymne introuvable: ${entry.code}'))
        else
          CollapsibleLiturgyText(
            title: hymn.title.isNotEmpty
                ? '$baseTitle — ${hymn.title}'
                : baseTitle,
            subtitle: hymn.author,
            content: hymn.content,
          ),
        if (showFooter) const OfficeFooterWidget(),
      ],
    );
  }
}

class _OfficeTab extends StatelessWidget {
  const _OfficeTab({
    required this.celebrationKey,
    required this.massDefinition,
    required this.massList,
    required this.selectedCommon,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.hasMultipleCelebrations,
    required this.needsCommonSelection,
    required this.needsTextsChoice,
    required this.readingSource,
    required this.onReadingSourceChanged,
    this.shrinkWrap = false,
  });

  final String celebrationKey;
  final CelebrationContext massDefinition;
  final Map<String, CelebrationContext> massList;
  final String? selectedCommon;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;
  final void Function(String key, int? precedence) onPrecedenceOverridden;
  final bool hasMultipleCelebrations;
  final bool needsCommonSelection;
  // Whether a Common is used at all, picked alongside the reading source —
  // see _MassTextsChoiceSelector and _MassOfficeDisplayState._needsTextsChoice.
  final bool needsTextsChoice;
  // Where the memorial's readings currently come from, when needsTextsChoice.
  final MassReadingSource readingSource;
  // Null while a switch is already in flight, to disable the choice meanwhile.
  final ValueChanged<MassReadingSource>? onReadingSourceChanged;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    // A selector, nothing to copy: unlike the offices' texts, the whole
    // tab stays out of the reading view's text selection
    return SelectionContainer.disabled(
      child: ListView(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: tabScrollPadding(zoom, shrinkWrap: shrinkWrap),
        children: [
          OfficeNameHeader('Messe'),
          if (hasMultipleCelebrations) ...[
            OfficeSectionTitle(liturgyLabels['select-mass']!),
            CelebrationSelector(
              celebrationMap: massList,
              selectedKey: celebrationKey,
              onCelebrationChanged: onCelebrationChanged,
              onPrecedenceOverridden: onPrecedenceOverridden,
            ),
            SizedBox(height: 12.0 * zoom / 100),
          ],
          if (hasMultipleCelebrations &&
              (needsTextsChoice || needsCommonSelection))
            const Divider(height: 1),
          if (needsTextsChoice) ...[
            OfficeSectionTitle(liturgyLabels['select-reading-source']!),
            _MassTextsChoiceSelector(
              readingSource: readingSource,
              selectedCommon: selectedCommon,
              fullTextsSource:
                  _fullTextsSource(massDefinition.massReadingSources),
              commonList: massDefinition.commonList ?? const [],
              onReadingSourceChanged: onReadingSourceChanged,
              onCommonChanged: onCommonChanged,
            ),
            SizedBox(height: 12.0 * zoom / 100),
          ],
          if (needsTextsChoice && needsCommonSelection)
            const Divider(height: 1),
          if (needsCommonSelection) ...[
            OfficeSectionTitle(liturgyLabels['select-common']!),
            CommonSelector(
              commonList: massDefinition.commonList ?? [],
              commonTitles: massDefinition.commonTitles,
              selectedCommon: selectedCommon,
              precedence: massDefinition.precedence ?? 13,
              onCommonChanged: onCommonChanged,
              // Whether a Common is used at all is settled above, by
              // needsTextsChoice's selector — this one only picks which.
              forceCommon: true,
            ),
            SizedBox(height: 12.0 * zoom / 100),
          ],
          // Scroll mode: the same bar as under the office's title, closing
          // this part above it
          if (shrinkWrap &&
              (massDefinition.liturgicalColor ?? '').isNotEmpty) ...[
            SizedBox(height: 12.0 * zoom / 100),
            LiturgicalColorBar(color: massDefinition.liturgicalColor!),
          ],
        ],
      ),
    );
  }
}

/// The reading source behind the texts choice's third row — the saint's own
/// readings, exactly as massDefinition.massReadingSources (see
/// mass_detection.dart's memorialReadingSources) offers them: completed from
/// the Common when it does so differently from the day
/// (MassReadingSource.all), or alone otherwise (MassReadingSource.proper,
/// offered whenever the proper has readings of its own — regardless of
/// whether the Common would add anything). Null when the proper has none.
MassReadingSource? _fullTextsSource(List<MassReadingSource> sources) {
  if (sources.contains(MassReadingSource.all)) return MassReadingSource.all;
  if (sources.contains(MassReadingSource.proper)) {
    return MassReadingSource.proper;
  }
  return null;
}

/// The three ways a celebrated memorial's Mass texts can be made of, picked
/// together — see _MassOfficeDisplayState._needsTextsChoice: the day's
/// readings with no Common at all (the saint's own collect only, when it
/// has one); the day's readings with the Common filling what the saint's
/// proper lacks (today's long-standing default); or, when the saint's own
/// proper has readings of its own (fullTextsSource), those.
class _MassTextsChoiceSelector extends StatelessWidget {
  const _MassTextsChoiceSelector({
    required this.readingSource,
    required this.selectedCommon,
    required this.fullTextsSource,
    required this.commonList,
    required this.onReadingSourceChanged,
    required this.onCommonChanged,
  });

  final MassReadingSource readingSource;
  final String? selectedCommon;
  final MassReadingSource? fullTextsSource;
  final List<String> commonList;
  // Null while a switch is already in flight, to disable the choice meanwhile.
  final ValueChanged<MassReadingSource>? onReadingSourceChanged;
  final ValueChanged<String?>? onCommonChanged;

  _Choice get _selected => selectedCommon == null
      ? _Choice.dayNoCommon
      : (fullTextsSource != null && readingSource == fullTextsSource
          ? _Choice.fullTexts
          : _Choice.dayWithCommon);

  void _select(_Choice choice) {
    switch (choice) {
      case _Choice.dayNoCommon:
        onReadingSourceChanged?.call(MassReadingSource.day);
        onCommonChanged?.call(null);
      case _Choice.dayWithCommon:
        onReadingSourceChanged?.call(MassReadingSource.day);
        onCommonChanged?.call(selectedCommon ?? commonList.first);
      case _Choice.fullTexts:
        onReadingSourceChanged?.call(fullTextsSource!);
        onCommonChanged?.call(selectedCommon ?? commonList.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markColor = choiceMarkColor(context, null);
    final selected = _selected;
    final enabled = onReadingSourceChanged != null && onCommonChanged != null;
    ChoiceRow row(_Choice choice, String titleKey, String subtitle) =>
        ChoiceRow(
          title: liturgyLabels[titleKey]!,
          subtitle: subtitle,
          selected: selected == choice,
          markColor: markColor,
          boldTitle: false,
          onTap: !enabled || selected == choice ? null : () => _select(choice),
        );
    return ChoiceList(rows: [
      row(_Choice.dayNoCommon, 'reading-source-day-no-common',
          'Lectures de la férie avec collecte et propre du saint'),
      row(_Choice.dayWithCommon, 'reading-source-day',
          'Lectures de la férie, oraisons du propre et du commun du saint'),
      if (fullTextsSource != null)
        row(_Choice.fullTexts, 'reading-source-all',
            'Lectures et oraisons du propre et du commun du saint'),
    ]);
  }
}

enum _Choice { dayNoCommon, dayWithCommon, fullTexts }

/// Header + entrance antiphon + opening prayer, shared by _IntroductionTab
/// (scroll mode, and tab mode when there are no reading parts to merge it
/// into) and the first reading-part tab (tab mode's usual case, where a
/// separate Introduction tab is skipped — see MassOfficeDisplay).
List<Widget> _buildIntroductionChildren({
  required CelebrationContext massDefinition,
  Widget? belowTitle,
  required Mass massData,
  required Calendar calendar,
  required DateTime date,
  required double zoom,
}) {
  final additionalInfo =
      officeAdditionalInfo(massDefinition.liturgicalTime, calendar, date);
  final entrance = massData.entranceAntiphon ?? [];

  return [
    OfficeHeaderDisplay(
      officeDescription: massDefinition.officeDescription,
      liturgicalColor: massDefinition.liturgicalColor,
      typeLabel: massDefinition.celebrationDisplayLabel,
      celebrationDescription: massDefinition.celebrationDescription,
      additionalInfo: additionalInfo,
      belowTitle: belowTitle,
    ),
    if (entrance.isNotEmpty) ...[
      LiturgyPartTitle('Antienne d\'ouverture', left: LiturgyRowLeft.indent),
      _MassAntiphonContent(antiphons: entrance),
    ],
    if (massData.collect?.isNotEmpty ?? false) ...[
      LiturgyPartTitle('Collecte', left: LiturgyRowLeft.indent),
      ...buildOrationWidgets(massData.collect,
          zoom: zoom, rightIndentMultiplier: 0.75, textAlign: TextAlign.left),
    ],
  ];
}

/// Entrance / communion antiphons, rendered like the other Mass texts
/// (plain body text, reference aligned right below it) rather than with the
/// Office's AntiphonWidget styling. Alternatives are separated by "ou".
class _MassAntiphonContent extends StatelessWidget {
  const _MassAntiphonContent({required this.antiphons});

  final List<MassAntiphon> antiphons;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final widgets = <Widget>[];
    for (var i = 0; i < antiphons.length; i++) {
      if (i > 0) {
        widgets.add(SizedBox(height: 12.0 * zoom / 100));
        widgets.add(LiturgyRow(
          builder: (context, _) =>
              YamlTextFromString(liturgyLabels['or'] ?? 'ou'),
        ));
        widgets.add(SizedBox(height: 12.0 * zoom / 100));
      }
      final reference = antiphons[i].biblicalReference;
      final content = antiphons[i].content;
      if (content != null && content.isNotEmpty) {
        widgets.add(LiturgyRow(
          builder: (context, _) => YamlTextFromString(
            content,
            textAlign: TextAlign.left,
            rightIndentMultiplier: 0.75,
          ),
        ));
      }
      if (reference != null && reference.isNotEmpty) {
        widgets.add(LiturgyRow(
          builder: (context, _) => Align(
            alignment: Alignment.centerRight,
            child: BiblicalReferenceButton(reference: reference, zoom: zoom),
          ),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.massDefinition,
    this.belowTitle,
    required this.massData,
    required this.calendar,
    required this.date,
    this.shrinkWrap = false,
    this.showFooter = false,
  });

  final CelebrationContext massDefinition;
  // See OfficeHeaderDisplay.belowTitle
  final Widget? belowTitle;
  final Mass massData;
  final Calendar calendar;
  final DateTime date;
  final bool shrinkWrap;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: tabScrollPadding(zoom,
          shrinkWrap: shrinkWrap,
          base: EdgeInsets.only(bottom: 16.0 * zoom / 100)),
      children: [
        ..._buildIntroductionChildren(
          massDefinition: massDefinition,
          belowTitle: belowTitle,
          massData: massData,
          calendar: calendar,
          date: date,
          zoom: zoom,
        ),
        if (showFooter) const OfficeFooterWidget(),
      ],
    );
  }
}

/// Renders one MassReadingPart: each partContents entry (usually one, but
/// several for alternative options like Easter Day's second-reading choice,
/// or the Easter Vigil's multiple Old Testament readings sharing a partType)
/// is rendered in turn, separated by "ou" when there is more than one.
class _ReadingPartTab extends StatelessWidget {
  const _ReadingPartTab({
    super.key,
    required this.part,
    required this.label,
    required this.liturgicalTime,
    this.shrinkWrap = false,
    this.isShortForm = false,
    this.hideAlleluiaInShortForm = true,
    this.shortFormAnnouncement,
    this.choiceSelector,
    this.showFooter = false,
  });

  final MassReadingPart part;
  final String label;
  final String? liturgicalTime;
  final bool shrinkWrap;
  // True when [part] is a forme-brève projection (see _shortFormPart).
  final bool isShortForm;
  // When isShortForm, whether the Gospel's Alléluia framing is hidden.
  // Scroll mode keeps this true (the Alléluia was just shown above, for the
  // long form, in the same continuous scroll) — tab mode passes false so its
  // forme-brève tab, viewed on its own, still gets the full framing.
  final bool hideAlleluiaInShortForm;
  // Forwarded to _MassGospelContent — see its own doc.
  final Widget? shortFormAnnouncement;
  // Shown above the text when the part offers several choices — see
  // ReadingChoiceSelector; [part] then only holds the selected one.
  final Widget? choiceSelector;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: tabScrollPadding(zoom,
          shrinkWrap: shrinkWrap,
          base: EdgeInsets.only(bottom: 16.0 * zoom / 100)),
      children: [
        if (choiceSelector != null) choiceSelector!,
        ..._buildPartContent(zoom),
        if (showFooter) const OfficeFooterWidget(),
      ],
    );
  }

  List<Widget> _buildPartContent(double zoom) {
    final widgets = <Widget>[];
    final contents = part.partContents;
    for (var i = 0; i < contents.length; i++) {
      if (i > 0) {
        widgets.add(SizedBox(height: 12.0 * zoom / 100));
        widgets.add(LiturgyRow(
          builder: (context, _) =>
              YamlTextFromString(liturgyLabels['or'] ?? 'ou'),
        ));
        widgets.add(SizedBox(height: 12.0 * zoom / 100));
      }
      final content = contents[i];
      switch (content) {
        case MassReading r when part.partType == 'ALLELUIA':
          widgets.add(_MassAcclamationContent(
            acclamation: r,
            title: i == 0 ? label : null,
            liturgicalTime: liturgicalTime,
          ));
        case MassReading r:
          widgets.add(_MassScriptureWidget(
            title: label,
            isChoice: choiceSelector != null,
            reference: r.biblicalRef,
            headline: r.headline,
            content: r.content,
          ));
        case MassPsalm p:
          widgets.add(_MassPsalmContent(
            psalm: p,
            title: label,
            isChoice: choiceSelector != null,
          ));
        case MassGospel g:
          widgets.add(_MassGospelContent(
            gospel: g,
            title: label,
            isChoice: choiceSelector != null,
            liturgicalTime: liturgicalTime,
            isShortForm: isShortForm,
            hideAlleluiaInShortForm: hideAlleluiaInShortForm,
            // Only the first content gets the pointer — a part is expected
            // to hold a single Gospel; guards against a stray extra entry
            // (e.g. a malformed forme-brève) duplicating the framing.
            shortFormAnnouncement: i == 0 ? shortFormAnnouncement : null,
          ));
      }
    }
    return widgets;
  }
}

/// A choice's title and subtitle in its ReadingChoiceSelector: its reference
/// and headline for a reading or a Gospel ("1 Co 1, 18-25", "La folie de la
/// croix"), its title and the first line of its refrain for a psalm
/// ("Psaume 22", "Le Seigneur est mon berger :"). Blank ones are null.
(String?, String?) _choiceTexts(MassReadingContent content) {
  final (String? title, String? subtitle) = switch (content) {
    MassReading r => (r.biblicalRef, r.headline),
    MassGospel g => (g.biblicalRef, g.headline),
    MassPsalm p => (
        _massPsalmDisplayTitle(readingsTypeLabels['PSALM'] ?? 'Psaume', p),
        p.chorus?.firstOrNull?.content?.split('\n').first,
      ),
  };
  String? clean(String? text) =>
      (text?.trim().isEmpty ?? true) ? null : text!.trim();
  return (clean(title), clean(subtitle));
}

/// Returns [ref] with a leading "Ps " when it starts with a digit (chorusRef
/// is stored as a bare verse locator, e.g. "36, 5", unlike biblicalRef which
/// already spells out the book).
String? _formatChorusReference(String? ref) {
  if (ref == null || ref.isEmpty) return null;
  if (RegExp(r'^[0-9]').hasMatch(ref)) {
    return 'Ps $ref';
  }
  return ref;
}

/// Extracts the leading psalm number from a MassPsalm.refAbbr string, e.g.
/// "144, 10…" -> "144", "113A, 1…" -> "113A", "’116’" -> "116", tolerating
/// a leading "cf."/"Ps " marker and typographic quotes. Returns null when
/// refAbbr doesn't start with a number — e.g. a canticle reference like
/// "Lc 1, 49" or "cf. Is 12, 6b", which has no psalm number to show.
String? _psalmNumberFromRefAbbr(String? refAbbr) {
  if (refAbbr == null) return null;
  final match =
      RegExp(r"^(?:cf\.?\s*)?(?:Ps\s*)?['’]?(\d+[AB]?)\b").firstMatch(refAbbr);
  return match?.group(1);
}

/// Appends this instance's psalm number to [title] (e.g. "Psaume 103"),
/// or returns [title] unchanged when refAbbr carries none.
String _psalmDisplayTitle(String title, String? refAbbr) {
  final number = _psalmNumberFromRefAbbr(refAbbr);
  return number != null ? '$title $number' : title;
}

/// Extracts the book + chapter portion of a canticle's biblicalRef, dropping
/// the verse list that follows the first comma, e.g.
/// "Ex 15, 1b, 2, 3-4, 5-6, 17-18" -> "Ex 15".
String? _canticleChapterRef(String? biblicalRef) {
  if (biblicalRef == null || biblicalRef.isEmpty) return null;
  final chapter = biblicalRef.split(',').first.trim();
  return chapter.isEmpty ? null : chapter;
}

/// Appends this instance's chapter reference to [title] (e.g.
/// "Cantique (Ex 15)"), or returns [title] unchanged when absent.
String _canticleDisplayTitle(String title, String? biblicalRef) {
  final chapterRef = _canticleChapterRef(biblicalRef);
  return chapterRef != null ? '$title ($chapterRef)' : title;
}

final String _canticleLabel = readingsTypeLabels['CANTICLE'] ?? 'Cantique';

/// Whether a PSALM part's proposition is actually a canticle. The data only
/// knows the PSALM partType — a part can offer a psalm one weekday cycle and
/// a canticle the other (e.g. ot_16_2) — so this is read off biblicalRef: a
/// psalm's starts with "Ps". A missing biblicalRef counts as a psalm.
bool _isCanticle(MassPsalm psalm) {
  final ref = psalm.biblicalRef?.trim();
  return ref != null && ref.isNotEmpty && !ref.startsWith('Ps');
}

/// Display title of one PSALM proposition: "[psalmTitle] 103" for a psalm,
/// "Cantique (Ex 15)" for a canticle (see _isCanticle).
String _massPsalmDisplayTitle(String psalmTitle, MassPsalm psalm) =>
    _isCanticle(psalm)
        ? _canticleDisplayTitle(_canticleLabel, psalm.biblicalRef)
        : _psalmDisplayTitle(psalmTitle, psalm.refAbbr);

/// Title + right-aligned biblical reference + left-aligned content — like
/// ScriptureWidget, but left-aligned rather than justified. A separate
/// widget rather than a change to ScriptureWidget (which every other office
/// also uses and which justifies on purpose) to avoid touching shared
/// behaviour outside Mass.
class _MassScriptureWidget extends StatelessWidget {
  const _MassScriptureWidget({
    required this.title,
    this.isChoice = false,
    this.reference,
    this.headline,
    this.content,
  });

  final String title;
  // Chosen among several: [title] is shown above them (see
  // ReadingChoiceSelector), the announcement marked like a psalm's title
  final bool isChoice;
  final String? reference;
  final String? headline;
  final String? content;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final announcement = readingAnnouncement(reference);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isChoice) LiturgyPartTitle(title, left: LiturgyRowLeft.indent),
        if (announcement != null)
          LiturgyContentTitle(announcement, showBullet: isChoice),
        if (headline != null && headline!.isNotEmpty) ...[
          SizedBox(height: 4.0 * zoom / 100),
          LiturgyRow(
            builder: (context, z) => YamlTextFromString(headline!,
                textStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14 * (z ?? 100) / 100)),
          ),
        ],
        if (reference != null && reference!.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: BiblicalReferenceButton(reference: reference!, zoom: zoom),
            ),
          ),
        SizedBox(height: 6.0 * zoom / 100),
        if (content != null && content!.isNotEmpty) ...[
          LiturgyRow(
            builder: (context, _) => YamlTextFromString(
              content!,
              textAlign: TextAlign.left,
              rightIndentMultiplier: 0.75,
              initialLetter: true,
            ),
          ),
          const _MassReadingConclusion('readingAcclamation'),
        ],
      ],
    );
  }
}

/// The dialogue closing a reading ("Parole du Seigneur") or the Gospel
/// ("Acclamons la Parole de Dieu"), from liturgyLabels[labelKey].
class _MassReadingConclusion extends StatelessWidget {
  const _MassReadingConclusion(this.labelKey);

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    // Spacing of the separator before a psalm's antiphon
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 14.0 * zoom / 100),
        const AntiphonSeparator(),
        SizedBox(height: 4.0 * zoom / 100),
        LiturgyRow(
          left: LiturgyRowLeft.none,
          builder: (context, _) => YamlTextFromString(
            liturgyLabels[labelKey] ?? labelKey,
            useSymbolColumn: true,
          ),
        ),
      ],
    );
  }
}

class _MassPsalmContent extends StatelessWidget {
  const _MassPsalmContent({
    required this.psalm,
    required this.title,
    this.isChoice = false,
  });

  final MassPsalm psalm;
  // The part's base "Psaume" label. This widget can be rendered several
  // times for the same title when a part offers several alternative
  // propositions (see _ReadingPartTab), each appending its own
  // number/reference — or switching to "Cantique" (see _isCanticle).
  final String title;
  // Chosen among several, under their title (see ReadingChoiceSelector):
  // its own title marked like a psalm of the psalmody
  final bool isChoice;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final reference = psalm.biblicalRef ?? psalm.refAbbr;
    final chorus = psalm.chorus ?? [];
    final displayTitle = _massPsalmDisplayTitle(title, psalm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isChoice)
          LiturgyContentTitle(displayTitle)
        else
          LiturgyPartTitle(displayTitle, left: LiturgyRowLeft.indent),
        if (reference != null && reference.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: BiblicalReferenceButton(reference: reference, zoom: zoom),
            ),
          ),
        SizedBox(height: 6.0 * zoom / 100),
        if (chorus.isNotEmpty) ...[
          SizedBox(height: 8.0 * zoom / 100),
          AntiphonFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < chorus.length; i++) ...[
                  if (i > 0) SizedBox(height: 8.0 * zoom / 100),
                  AntiphonWidget(antiphon1: chorus[i].content ?? ''),
                  if (_formatChorusReference(chorus[i].chorusRef) != null)
                    LiturgyRow(
                      builder: (context, _) => Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatChorusReference(chorus[i].chorusRef)!,
                          style: TextStyle(fontSize: 11.0 * zoom / 100),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          SizedBox(height: 14.0 * zoom / 100),
        ],
        if (psalm.content != null && psalm.content!.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => YamlTextFromString(
              psalm.content!,
              textAlign: TextAlign.left,
              rightIndentMultiplier: 0.75,
            ),
          ),
      ],
    );
  }
}

/// Liturgical times during which "Alléluia" is never said, so the
/// acclamation's fixed Alléluia framing is dropped (the propos verse itself,
/// if any, is kept — Lenten Gospels use an alternative acclamation there).
const _noAlleluiaTimes = {'lent', 'holyweek'};

class _MassGospelContent extends StatelessWidget {
  const _MassGospelContent({
    required this.gospel,
    required this.title,
    this.isChoice = false,
    required this.liturgicalTime,
    this.isShortForm = false,
    this.hideAlleluiaInShortForm = true,
    this.shortFormAnnouncement,
  });

  final MassGospel gospel;
  final String title;
  // Chosen among several: [title] is shown above them (see
  // ReadingChoiceSelector), and above the Alléluia
  final bool isChoice;
  final String? liturgicalTime;
  // True for the forme-brève block.
  final bool isShortForm;
  // When isShortForm, whether to hide the Alléluia/acclamation framing —
  // see _ReadingPartTab.hideAlleluiaInShortForm.
  final bool hideAlleluiaInShortForm;
  // Scroll-mode-only "forme brève plus bas" pointer, shown right after the
  // Alléluia block and before the "Évangile" title.
  final Widget? shortFormAnnouncement;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final reference = gospel.biblicalRef;
    final suppressAlleluia = _noAlleluiaTimes.contains(liturgicalTime);
    final acclamation = gospel.acclamationAntiphon;
    final hideAlleluia = isShortForm && hideAlleluiaInShortForm;

    final acclamationLines = hideAlleluia
        ? const <String>[]
        : [
            if (!suppressAlleluia) '[rubric]Alléluia, alléluia.[/rubric]',
            if (acclamation != null && acclamation.isNotEmpty) acclamation,
            if (!suppressAlleluia) '[rubric]Alléluia.[/rubric]',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (acclamationLines.isNotEmpty) ...[
          LiturgyPartTitle(
            suppressAlleluia ? 'Acclamation de l\'Évangile' : 'Alléluia',
            left: LiturgyRowLeft.indent,
          ),
          _MassAcclamationText(acclamationLines.join('\n'),
              left: LiturgyRowLeft.indent),
          if (gospel.acclamationAntiphonReference != null &&
              gospel.acclamationAntiphonReference!.isNotEmpty)
            LiturgyRow(
              builder: (context, _) => Align(
                alignment: Alignment.centerRight,
                child: BiblicalReferenceButton(
                  reference: gospel.acclamationAntiphonReference!,
                  zoom: zoom,
                ),
              ),
            ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (shortFormAnnouncement != null) ...[
          shortFormAnnouncement!,
          SizedBox(height: 6.0 * zoom / 100),
        ],
        if (!isChoice) LiturgyPartTitle(title, left: LiturgyRowLeft.indent),
        if (gospel.headline != null && gospel.headline!.isNotEmpty) ...[
          SizedBox(height: 4.0 * zoom / 100),
          LiturgyRow(
            builder: (context, z) => YamlTextFromString(gospel.headline!,
                textStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14 * (z ?? 100) / 100)),
          ),
        ],
        if (reference != null && reference.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: BiblicalReferenceButton(reference: reference, zoom: zoom),
            ),
          ),
        if (evangelistName(reference) != null) ...[
          _MassGospelAnnouncement(evangelistName(reference)!),
          SizedBox(height: 6.0 * zoom / 100),
        ],
        if (gospel.content != null && gospel.content!.isNotEmpty) ...[
          LiturgyRow(
            builder: (context, _) => YamlTextFromString(
              gospel.content!,
              textAlign: TextAlign.left,
              rightIndentMultiplier: 0.75,
              initialLetter: true,
            ),
          ),
          const _MassReadingConclusion('gospelAcclamation'),
        ],
      ],
    );
  }
}

/// Scroll-mode-only banner shown after the Alléluia of a Gospel that has a
/// forme brève further down the same scroll view — tapping it scrolls to the
/// block tagged with [targetKey]. Tab mode doesn't need this: the short form
/// gets its own separate tab there instead (see MassOfficeDisplay).
class _ShortFormAnnouncement extends StatelessWidget {
  const _ShortFormAnnouncement({required this.targetKey});

  final GlobalKey targetKey;

  void _scrollToShortForm() {
    final target = targetKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiturgyRow(
      left: LiturgyRowLeft.indent,
      builder: (context, zoom) {
        final fontSize = 12.0 * (zoom ?? 100) / 100;
        final color = Theme.of(context).colorScheme.secondary;
        return GestureDetector(
          onTap: _scrollToShortForm,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward, size: fontSize, color: color),
              SizedBox(width: 4.0 * (zoom ?? 100) / 100),
              Text(
                'Une forme brève est proposée plus bas',
                style: TextStyle(
                  fontSize: fontSize,
                  fontStyle: FontStyle.italic,
                  color: color,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Same structure as OfflineLiturgyPartSubtitle (italic, no border) but at
/// normal body text size (16) rather than the smaller subtitle size — used
/// for the Gospel's Alléluia-framed acclamation. Not a change to the shared
/// widget, which other offices use for Psalm subtitles at their own size.
/// One verse of the Gospel acclamation (an ALLELUIA part), framed by its
/// Alléluia as in _MassGospelContent, and its reference — under [title],
/// absent for the alternatives that follow the first.
class _MassAcclamationContent extends StatelessWidget {
  const _MassAcclamationContent({
    required this.acclamation,
    this.title,
    required this.liturgicalTime,
  });

  final MassReading acclamation;
  final String? title;
  final String? liturgicalTime;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final suppressAlleluia = _noAlleluiaTimes.contains(liturgicalTime);
    final content = acclamation.content;
    final reference = acclamation.biblicalRef;
    final lines = [
      if (!suppressAlleluia) '[rubric]Alléluia, alléluia.[/rubric]',
      if (content != null && content.isNotEmpty) content,
      if (!suppressAlleluia) '[rubric]Alléluia.[/rubric]',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) LiturgyPartTitle(title, left: LiturgyRowLeft.indent),
        _MassAcclamationText(lines.join('\n'), left: LiturgyRowLeft.indent),
        if (reference != null && reference.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: BiblicalReferenceButton(reference: reference, zoom: zoom),
            ),
          ),
      ],
    );
  }
}

class _MassAcclamationText extends StatelessWidget {
  const _MassAcclamationText(this.content, {this.left = LiturgyRowLeft.none});

  final String content;
  final LiturgyRowLeft left;

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();
    return LiturgyRow(
      left: left,
      builder: (context, zoom) => YamlTextWidget(
        paragraphs: YamlTextParser.parseText(content),
        textStyle: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 16.0 * (zoom ?? 100) / 100,
        ),
        paragraphSpacing: 0,
        redColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

/// Same size/weight as LiturgyPartTitle (the "Psaume XXX" title style,
/// without its small-caps), but — unlike LiturgyPartTitle, which colors its
/// whole string in the liturgical red — only the leading cross is in that
/// colour, matching the missal convention where the ceremonial cross mark is
/// printed in red and the spoken announcement itself stays in the normal
/// text colour.
class _MassGospelAnnouncement extends StatelessWidget {
  const _MassGospelAnnouncement(this.evangelistName);

  final String evangelistName;

  @override
  Widget build(BuildContext context) {
    final redColor = Theme.of(context).colorScheme.secondary;
    return LiturgyRow(
      left: LiturgyRowLeft.indent,
      builder: (context, zoom) {
        final fontSize = 16.0 * (zoom ?? 100) / 100;
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${YamlTextParser.outlinedCrossGlyph} ',
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: 'LiturgicalSymbols',
                  fontWeight: FontWeight.normal,
                  color: redColor,
                ),
              ),
              TextSpan(
                text: 'Évangile de Jésus-Christ selon saint $evangelistName',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfferingTab extends StatelessWidget {
  const _OfferingTab({
    required this.massData,
    this.shrinkWrap = false,
    this.showFooter = false,
  });

  final Mass massData;
  final bool shrinkWrap;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: tabScrollPadding(zoom,
          shrinkWrap: shrinkWrap,
          base: EdgeInsets.only(bottom: 16.0 * zoom / 100)),
      children: [
        if (massData.offeringPrayer?.isNotEmpty ?? false) ...[
          LiturgyPartTitle('Prière sur les offrandes',
              left: LiturgyRowLeft.indent),
          ...buildOrationWidgets(massData.offeringPrayer,
              zoom: zoom,
              rightIndentMultiplier: 0.75,
              textAlign: TextAlign.left),
        ],
        if (showFooter) const OfficeFooterWidget(),
      ],
    );
  }
}

class _CommunionTab extends StatelessWidget {
  const _CommunionTab({
    required this.massData,
    this.shrinkWrap = false,
    this.showFooter = false,
  });

  final Mass massData;
  final bool shrinkWrap;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final communion = massData.communionAntiphon ?? [];
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: tabScrollPadding(zoom,
          shrinkWrap: shrinkWrap,
          base: EdgeInsets.only(bottom: 16.0 * zoom / 100)),
      children: [
        if (communion.isNotEmpty) ...[
          LiturgyPartTitle('Antienne de communion',
              left: LiturgyRowLeft.indent),
          _MassAntiphonContent(antiphons: communion),
        ],
        if (massData.prayerAfterCommunion?.isNotEmpty ?? false) ...[
          LiturgyPartTitle('Prière après la communion',
              left: LiturgyRowLeft.indent),
          ...buildOrationWidgets(massData.prayerAfterCommunion,
              zoom: zoom,
              rightIndentMultiplier: 0.75,
              textAlign: TextAlign.left),
        ],
        if (massData.prayerOnThePeople?.isNotEmpty ?? false) ...[
          LiturgyPartTitle('Prière sur le peuple', left: LiturgyRowLeft.indent),
          ...buildOrationWidgets(massData.prayerOnThePeople,
              zoom: zoom,
              rightIndentMultiplier: 0.75,
              textAlign: TextAlign.left),
        ],
        if (massData.solemnBlessingList?.isNotEmpty ?? false) ...[
          LiturgyPartTitle('Bénédiction solennelle',
              left: LiturgyRowLeft.indent),
          for (final entry in massData.solemnBlessingList!)
            if (entry.hymnData?.content != null)
              LiturgyRow(
                left: LiturgyRowLeft.none,
                builder: (context, _) =>
                    HymnContentDisplay(content: entry.hymnData!.content),
              ),
        ],
        if (showFooter) const OfficeFooterWidget(),
      ],
    );
  }
}
