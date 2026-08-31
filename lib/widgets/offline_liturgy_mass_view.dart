import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/libraries/biblical_book_labels.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/base_office_view_state.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_header_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
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

  @override
  Future<Mass> exportOffice(CelebrationContext ctx) => massExport(ctx);

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
      calendar: widget.calendar,
      date: widget.date,
    );
  }
}

/// Returns the tab-bar label for each readingPart, in the order the data
/// provides them. Also used as the base title passed down to each
/// alternative content item of the part — PSALM/CANTICLE items each add
/// their own psalm number / biblical reference on top of it individually
/// (see _MassPsalmContent), since a part can hold several alternative
/// propositions (separated by "ou") with different numbers/references.
List<String> _readingPartLabels(List<MassReadingPart> parts) {
  return [for (final part in parts) _readingPartTabLabel(part)];
}

/// readingsTypeLabels[part.partType] (falling back to the raw partType),
/// with every alternative PSALM/CANTICLE proposition's number/reference
/// appended, e.g. "Psaume 103 / 32" for a part offering two alternative
/// psalms — matches the single-proposition format used by
/// _psalmDisplayTitle/_canticleDisplayTitle.
String _readingPartTabLabel(MassReadingPart part) {
  final baseLabel = readingsTypeLabels[part.partType] ?? part.partType;
  final psalms = part.partContents.whereType<MassPsalm>().toList();
  if (psalms.isEmpty) return baseLabel;

  if (part.partType == 'CANTICLE') {
    final refs = psalms
        .map((p) => _canticleChapterRef(p.biblicalRef))
        .whereType<String>()
        .toList();
    return refs.isEmpty ? baseLabel : '$baseLabel (${refs.join(' / ')})';
  }

  final numbers = psalms
      .map((p) => _psalmNumberFromRefAbbr(p.refAbbr))
      .whereType<String>()
      .toList();
  return numbers.isEmpty ? baseLabel : '$baseLabel ${numbers.join(' / ')}';
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
  final Calendar calendar;
  final DateTime date;

  @override
  State<MassOfficeDisplay> createState() => _MassOfficeDisplayState();
}

class _MassOfficeDisplayState extends State<MassOfficeDisplay> {
  // Whether the memorial's own proper readingParts are shown instead of the
  // day's — only meaningful when widget.massDefinition.hasProperReadingParts
  // (see _OfficeTab). Ephemeral: reset to the default (day) whenever a
  // different celebration/Mass is selected, see didUpdateWidget.
  bool _useProperReadings = false;
  bool _isSwitchingReadingSource = false;
  late Mass _effectiveMassData = widget.massData;

  @override
  void didUpdateWidget(MassOfficeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.massData != oldWidget.massData) {
      _useProperReadings = false;
      _effectiveMassData = widget.massData;
    }
  }

  Future<void> _setReadingSource(bool useProper) async {
    if (useProper == _useProperReadings) return;
    setState(() => _isSwitchingReadingSource = true);
    final newMassData = await massExport(
      widget.massDefinition.copyWith(useProperReadingsForMemorial: useProper),
    );
    if (!mounted) return;
    setState(() {
      _useProperReadings = useProper;
      _effectiveMassData = newMassData;
      _isSwitchingReadingSource = false;
    });
  }

  bool get _hasMultipleCelebrations =>
      widget.massList.values.where((d) => d.isCelebrable).length > 1;

  bool get _needsCommonSelection {
    final d = widget.massDefinition;
    if (d.commonList == null || d.commonList!.isEmpty) return false;
    if (['paschaloctave', 'christmasoctave'].contains(d.liturgicalTime)) {
      return false;
    }
    return d.celebrationCode != d.ferialCode;
  }

  bool get _hasOfficeTab {
    if (_hasMultipleCelebrations) return true;
    if (!_needsCommonSelection) return false;
    return (widget.massDefinition.commonList?.length ?? 0) > 1 ||
        (widget.massDefinition.precedence ?? 13) > 8;
  }

  bool get _hasOfferingTab =>
      _effectiveMassData.offeringPrayer?.isNotEmpty ?? false;

  /// Reading-part index -> its short-form (forme brève) projection, for the
  /// parts that have one. See _shortFormPart.
  Map<int, MassReadingPart> get _shortFormParts {
    final parts = _effectiveMassData.readingParts ?? [];
    final result = <int, MassReadingPart>{};
    for (var i = 0; i < parts.length; i++) {
      final shortPart = _shortFormPart(parts[i]);
      if (shortPart != null) result[i] = shortPart;
    }
    return result;
  }

  bool get _hasCommunionTab =>
      (_effectiveMassData.communionAntiphon?.isNotEmpty ?? false) ||
      (_effectiveMassData.prayerAfterCommunion?.isNotEmpty ?? false) ||
      (_effectiveMassData.prayerOnThePeople?.isNotEmpty ?? false) ||
      (_effectiveMassData.solemnBlessingList?.isNotEmpty ?? false);

  // The proper sequence (e.g. Victimae Paschali Laudes, Veni Sancte
  // Spiritus) — optional, only a handful of days a year.
  bool get _hasSequence => _effectiveMassData.sequence?.isNotEmpty ?? false;

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
    final readingTabs = _effectiveMassData.readingParts?.length ?? 0;
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
    final labels = _readingPartLabels(_effectiveMassData.readingParts ?? []);
    final shortForms = _shortFormParts;
    if (_hasSequence && labels.isEmpty) {
      tabs.add(const Tab(text: 'Séquence'));
    }
    for (var i = 0; i < labels.length; i++) {
      // The sequence is sung right before the Gospel acclamation, which is
      // always the last reading part — see _readingPartLabels.
      if (_hasSequence && i == labels.length - 1) {
        tabs.add(const Tab(text: 'Séquence'));
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
          useProperReadings: _useProperReadings,
          onReadingSourceChanged:
              _isSwitchingReadingSource ? null : _setReadingSource,
        ),
      );
    }
    views.add(_IntroductionTab(
      massDefinition: widget.massDefinition,
      massData: _effectiveMassData,
      calendar: widget.calendar,
      date: widget.date,
    ));
    final parts = _effectiveMassData.readingParts ?? [];
    final labels = _readingPartLabels(parts);
    final shortForms = _shortFormParts;
    if (_hasSequence && parts.isEmpty) {
      views.add(HymnsTabWidget(
          hymns: _effectiveMassData.sequence!, title: 'Séquence'));
    }
    for (var i = 0; i < parts.length; i++) {
      if (_hasSequence && i == parts.length - 1) {
        views.add(HymnsTabWidget(
            hymns: _effectiveMassData.sequence!, title: 'Séquence'));
      }
      views.add(_ReadingPartTab(
        part: parts[i],
        label: labels[i],
        liturgicalTime: widget.massDefinition.liturgicalTime,
      ));
      final shortPart = shortForms[i];
      if (shortPart != null) {
        views.add(_ReadingPartTab(
          part: shortPart,
          label: '${labels[i]} (forme brève)',
          liturgicalTime: widget.massDefinition.liturgicalTime,
          isShortForm: true,
          hideAlleluiaInShortForm: false,
        ));
      }
    }
    if (_hasOfferingTab) {
      views.add(_OfferingTab(massData: _effectiveMassData));
    }
    if (_hasCommunionTab) {
      views.add(_CommunionTab(massData: _effectiveMassData));
    }
    return views;
  }

  Widget _buildScrollView(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final parts = _effectiveMassData.readingParts ?? [];
    final labels = _readingPartLabels(parts);
    final shortForms = _shortFormParts;
    final shortFormKeys = {
      for (final i in shortForms.keys) i: GlobalKey(),
    };

    return PinchZoomSelectionArea(
      child: CustomScrollView(
        slivers: [
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
                useProperReadings: _useProperReadings,
                onReadingSourceChanged:
                    _isSwitchingReadingSource ? null : _setReadingSource,
                shrinkWrap: true,
              ),
            ),
          SliverToBoxAdapter(
            child: _IntroductionTab(
              massDefinition: widget.massDefinition,
              massData: _effectiveMassData,
              calendar: widget.calendar,
              date: widget.date,
              shrinkWrap: true,
            ),
          ),
          if (_hasSequence && parts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0 * zoom / 100),
                child: HymnsTabWidget(
                  hymns: _effectiveMassData.sequence!,
                  title: 'Séquence',
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
                  child: HymnsTabWidget(
                    hymns: _effectiveMassData.sequence!,
                    title: 'Séquence',
                    shrinkWrap: true,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: i > 0 ? 8.0 * zoom / 100 : 0),
                child: _ReadingPartTab(
                  part: parts[i],
                  label: labels[i],
                  liturgicalTime: widget.massDefinition.liturgicalTime,
                  shrinkWrap: true,
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
                    label: '${labels[i]} (forme brève)',
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
                    massData: _effectiveMassData, shrinkWrap: true)),
          if (_hasCommunionTab)
            SliverToBoxAdapter(
                child: _CommunionTab(
                    massData: _effectiveMassData, shrinkWrap: true)),
        ],
      ),
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
    required this.useProperReadings,
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
  // Whether the memorial's own proper readingParts are currently shown
  // instead of the day's — see _needsReadingSourceSelection below.
  final bool useProperReadings;
  // Null while a switch is already in flight, to disable the chip meanwhile.
  final ValueChanged<bool>? onReadingSourceChanged;
  final bool shrinkWrap;

  // Only a memorial/commemoration (precedence > 5, i.e. not a Feast or
  // Solemnity, which always use their own proper readingParts regardless —
  // see massExport) whose own YAML actually declares readingParts can offer
  // this choice.
  bool get _needsReadingSourceSelection =>
      (massDefinition.precedence ?? 13) > 5 &&
      massDefinition.hasProperReadingParts;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      children: [
        if (hasMultipleCelebrations) ...[
          if ((massDefinition.celebrationTitle ?? '').isNotEmpty)
            _CelebrationTitleHeader(title: massDefinition.celebrationTitle!),
          OfficeSectionTitle(liturgyLabels['select-mass']!),
          CelebrationChipsSelector(
            celebrationMap: massList,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
            onPrecedenceOverridden: onPrecedenceOverridden,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (hasMultipleCelebrations &&
            (needsCommonSelection || _needsReadingSourceSelection))
          const Divider(height: 1),
        if (needsCommonSelection) ...[
          if ((massDefinition.commonList?.length ?? 0) > 1 ||
              (massDefinition.precedence ?? 13) > 8)
            OfficeSectionTitle(liturgyLabels['select-common']!),
          CommonChipsSelector(
            commonList: massDefinition.commonList ?? [],
            commonTitles: massDefinition.commonTitles,
            selectedCommon: selectedCommon,
            precedence: massDefinition.precedence ?? 13,
            onCommonChanged: onCommonChanged,
            forceCommon:
                massDefinition.celebrationCode == 'roman/virgin-mary-memory',
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (_needsReadingSourceSelection) ...[
          OfficeSectionTitle(liturgyLabels['select-reading-source']!),
          _ReadingSourceChipsSelector(
            useProperReadings: useProperReadings,
            onChanged: onReadingSourceChanged,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
      ],
    );
  }
}

/// Lets the reader pick between the day's readings and the memorial's own,
/// when both are available — see _OfficeTab._needsReadingSourceSelection.
class _ReadingSourceChipsSelector extends StatelessWidget {
  const _ReadingSourceChipsSelector({
    required this.useProperReadings,
    required this.onChanged,
  });

  final bool useProperReadings;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    Widget buildChip(bool value, String label) {
      return ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12.0 * zoom / 100)),
        selected: useProperReadings == value,
        onSelected: onChanged == null ? null : (_) => onChanged!(value),
      );
    }

    return Wrap(
      spacing: 8.0 * zoom / 100,
      runSpacing: 8.0 * zoom / 100,
      children: [
        buildChip(false, liturgyLabels['reading-source-day']!),
        buildChip(true, liturgyLabels['reading-source-proper']!),
      ],
    );
  }
}

/// Shown above "Sélectionner un office" (see _OfficeTab) so the day's
/// overall celebration name stays visible now that the chips themselves
/// only name the Mass (see the massType-driven officeDescription built in
/// mass_detection.dart) rather than repeating the celebration on each chip.
class _CelebrationTitleHeader extends StatelessWidget {
  const _CelebrationTitleHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0 * zoom / 100),
      child: LiturgyRow(
        builder: (context, _) => Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.0 * zoom / 100,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Header + entrance antiphon + opening prayer, shared by _IntroductionTab
/// (scroll mode, and tab mode when there are no reading parts to merge it
/// into) and the first reading-part tab (tab mode's usual case, where a
/// separate Introduction tab is skipped — see MassOfficeDisplay).
List<Widget> _buildIntroductionChildren({
  required CelebrationContext massDefinition,
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
    ),
    if (entrance.isNotEmpty) ...[
      LiturgyPartTitle('Antienne d\'ouverture', left: LiturgyRowLeft.indent),
      AntiphonWidget(
        antiphon1: entrance[0].content ?? '',
        antiphon2: entrance.length > 1 ? entrance[1].content : null,
        antiphon3: entrance.length > 2 ? entrance[2].content : null,
        reference1: entrance[0].biblicalReference,
        reference2: entrance.length > 1 ? entrance[1].biblicalReference : null,
        reference3: entrance.length > 2 ? entrance[2].biblicalReference : null,
      ),
    ],
    if (massData.collect?.isNotEmpty ?? false) ...[
      LiturgyPartTitle('Collecte', left: LiturgyRowLeft.indent),
      ...buildOrationWidgets(massData.collect,
          zoom: zoom, rightIndentMultiplier: 0.75, textAlign: TextAlign.left),
    ],
  ];
}

class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.massDefinition,
    required this.massData,
    required this.calendar,
    required this.date,
    this.shrinkWrap = false,
  });

  final CelebrationContext massDefinition;
  final Mass massData;
  final Calendar calendar;
  final DateTime date;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: shrinkWrap
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: _buildIntroductionChildren(
        massDefinition: massDefinition,
        massData: massData,
        calendar: calendar,
        date: date,
        zoom: zoom,
      ),
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

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: shrinkWrap
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: _buildPartContent(zoom),
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
        case MassReading r:
          widgets.add(_MassScriptureWidget(
            title: label,
            reference: r.biblicalRef,
            headline: r.headline,
            content: r.content,
          ));
        case MassPsalm p:
          widgets.add(_MassPsalmContent(
            psalm: p,
            title: label,
            isCanticle: part.partType == 'CANTICLE',
          ));
        case MassGospel g:
          widgets.add(_MassGospelContent(
            gospel: g,
            title: label,
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

/// Title + right-aligned biblical reference + left-aligned content — like
/// ScriptureWidget, but left-aligned rather than justified. A separate
/// widget rather than a change to ScriptureWidget (which every other office
/// also uses and which justifies on purpose) to avoid touching shared
/// behaviour outside Mass.
class _MassScriptureWidget extends StatelessWidget {
  const _MassScriptureWidget({
    required this.title,
    this.reference,
    this.headline,
    this.content,
  });

  final String title;
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
        LiturgyPartTitle(title, left: LiturgyRowLeft.indent),
        if (announcement != null)
          LiturgyContentTitle(announcement, showBullet: false),
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
        if (content != null && content!.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => YamlTextFromString(
              content!,
              textAlign: TextAlign.left,
              rightIndentMultiplier: 0.75,
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
    this.isCanticle = false,
  });

  final MassPsalm psalm;
  final String title;
  // Whether [psalm] is actually a CANTICLE (they share MassPsalm as their
  // content type — see MassReadingPart.fromJson). Governs which of
  // refAbbr/biblicalRef gets appended to [title], since this widget can be
  // rendered several times for the same title when a part offers several
  // alternative propositions (see _ReadingPartTab), each with its own
  // number/reference.
  final bool isCanticle;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final reference = psalm.biblicalRef ?? psalm.refAbbr;
    final chorus = psalm.chorus ?? [];
    final displayTitle = isCanticle
        ? _canticleDisplayTitle(title, psalm.biblicalRef)
        : _psalmDisplayTitle(title, psalm.refAbbr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          for (var i = 0; i < chorus.length; i++) ...[
            if (i > 0) SizedBox(height: 8.0 * zoom / 100),
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
            AntiphonWidget(antiphon1: chorus[i].chorus ?? ''),
          ],
          SizedBox(height: 12.0 * zoom / 100),
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
    required this.liturgicalTime,
    this.isShortForm = false,
    this.hideAlleluiaInShortForm = true,
    this.shortFormAnnouncement,
  });

  final MassGospel gospel;
  final String title;
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
        LiturgyPartTitle(title, left: LiturgyRowLeft.indent),
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
        if (gospel.content != null && gospel.content!.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => YamlTextFromString(
              gospel.content!,
              textAlign: TextAlign.left,
              rightIndentMultiplier: 0.75,
            ),
          ),
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
                text: '✙ ',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
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
  const _OfferingTab({required this.massData, this.shrinkWrap = false});

  final Mass massData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: shrinkWrap
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        if (massData.offeringPrayer?.isNotEmpty ?? false) ...[
          LiturgyPartTitle('Prière sur les offrandes',
              left: LiturgyRowLeft.indent),
          ...buildOrationWidgets(massData.offeringPrayer,
              zoom: zoom,
              rightIndentMultiplier: 0.75,
              textAlign: TextAlign.left),
        ],
      ],
    );
  }
}

class _CommunionTab extends StatelessWidget {
  const _CommunionTab({required this.massData, this.shrinkWrap = false});

  final Mass massData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final communion = massData.communionAntiphon ?? [];
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: shrinkWrap
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        if (communion.isNotEmpty) ...[
          LiturgyPartTitle('Antienne de communion',
              left: LiturgyRowLeft.indent),
          AntiphonWidget(
            antiphon1: communion[0].content ?? '',
            antiphon2: communion.length > 1 ? communion[1].content : null,
            antiphon3: communion.length > 2 ? communion[2].content : null,
            reference1: communion[0].biblicalReference,
            reference2:
                communion.length > 1 ? communion[1].biblicalReference : null,
            reference3:
                communion.length > 2 ? communion[2].biblicalReference : null,
          ),
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
      ],
    );
  }
}
