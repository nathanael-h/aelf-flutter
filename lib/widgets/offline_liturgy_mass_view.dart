import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
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
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
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

/// Returns a display label for each readingPart, based on its position among
/// parts of the same family (reading vs psalm); Gospel is always unique.
/// e.g. weekday: ["Lecture", "Psaume", "Évangile"]
///      Sunday:  ["1ère lecture", "Psaume", "2ème lecture", "Évangile"]
///      Vigil:   ["1ère lecture", "Psaume", "2ème lecture", "Psaume 2", ..., "Évangile"]
List<String> _readingPartLabels(List<MassReadingPart> parts) {
  const frenchOrdinals = [
    '1ère',
    '2ème',
    '3ème',
    '4ème',
    '5ème',
    '6ème',
    '7ème'
  ];
  String ordinalLabel(int position, int total, String singular, String noun) {
    if (total <= 1) return singular;
    final ordinal = position < frenchOrdinals.length
        ? frenchOrdinals[position]
        : '${position + 1}ème';
    return '$ordinal $noun';
  }

  final readingIndices = <int>[];
  final psalmIndices = <int>[];
  for (var i = 0; i < parts.length; i++) {
    final t = parts[i].partType;
    if (t == 'READING' || t == 'EPISTLE') {
      readingIndices.add(i);
    } else if (t == 'PSALM' || t == 'CANTICLE') {
      psalmIndices.add(i);
    }
  }

  final labels = List<String>.filled(parts.length, 'Évangile');
  for (var pos = 0; pos < readingIndices.length; pos++) {
    labels[readingIndices[pos]] =
        ordinalLabel(pos, readingIndices.length, 'Lecture', 'lecture');
  }
  for (var pos = 0; pos < psalmIndices.length; pos++) {
    labels[psalmIndices[pos]] =
        ordinalLabel(pos, psalmIndices.length, 'Psaume', 'psaume');
  }
  return labels;
}

/// Handles the TabBar navigation and layout of the Mass Office.
class MassOfficeDisplay extends StatelessWidget {
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

  bool get _hasMultipleCelebrations =>
      massList.values.where((d) => d.isCelebrable).length > 1;

  bool get _needsCommonSelection {
    final d = massDefinition;
    if (d.commonList == null || d.commonList!.isEmpty) return false;
    if (['paschaloctave', 'christmasoctave'].contains(d.liturgicalTime)) {
      return false;
    }
    return d.celebrationCode != d.ferialCode;
  }

  bool get _hasOfficeTab {
    if (_hasMultipleCelebrations) return true;
    if (!_needsCommonSelection) return false;
    return (massDefinition.commonList?.length ?? 0) > 1 ||
        (massDefinition.precedence ?? 13) > 8;
  }

  bool get _hasOfferingTab =>
      (massData.offeringPrayer?.isNotEmpty ?? false) ||
      (massData.prefaceList?.isNotEmpty ?? false);

  bool get _hasCommunionTab =>
      (massData.communionAntiphon?.isNotEmpty ?? false) ||
      (massData.prayerAfterCommunion?.isNotEmpty ?? false);

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

  bool get _hasReadingParts => massData.readingParts?.isNotEmpty ?? false;

  int _calculateTabCount() {
    final readingTabs = massData.readingParts?.length ?? 0;
    return (_hasReadingParts ? 0 : 1) +
        readingTabs +
        (_hasOfficeTab ? 1 : 0) +
        (_hasOfferingTab ? 1 : 0) +
        (_hasCommunionTab ? 1 : 0);
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[];
    if (_hasOfficeTab) {
      tabs.add(Tab(text: liturgyLabels['office'] ?? 'Office'));
    }
    if (!_hasReadingParts) {
      tabs.add(Tab(text: liturgyLabels['introduction']));
    }
    for (final label in _readingPartLabels(massData.readingParts ?? [])) {
      tabs.add(Tab(text: label));
    }
    if (_hasOfferingTab) tabs.add(const Tab(text: 'Offrandes'));
    if (_hasCommunionTab) tabs.add(const Tab(text: 'Communion'));
    return tabs;
  }

  List<Widget> _buildTabViews(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final views = <Widget>[];
    if (_hasOfficeTab) {
      views.add(
        _OfficeTab(
          celebrationKey: celebrationKey,
          massDefinition: massDefinition,
          massList: massList,
          selectedCommon: selectedCommon,
          onCelebrationChanged: onCelebrationChanged,
          onCommonChanged: onCommonChanged,
          onPrecedenceOverridden: onPrecedenceOverridden,
          hasMultipleCelebrations: _hasMultipleCelebrations,
          needsCommonSelection: _needsCommonSelection,
        ),
      );
    }
    final parts = massData.readingParts ?? [];
    final labels = _readingPartLabels(parts);
    if (!_hasReadingParts) {
      views.add(_IntroductionTab(
        massDefinition: massDefinition,
        massData: massData,
        calendar: calendar,
        date: date,
      ));
    }
    for (var i = 0; i < parts.length; i++) {
      views.add(_ReadingPartTab(
        part: parts[i],
        label: labels[i],
        liturgicalTime: massDefinition.liturgicalTime,
        leading: (i == 0 && _hasReadingParts)
            ? _buildIntroductionChildren(
                massDefinition: massDefinition,
                massData: massData,
                calendar: calendar,
                date: date,
                zoom: zoom,
              )
            : const [],
      ));
    }
    if (_hasOfferingTab) views.add(_OfferingTab(massData: massData));
    if (_hasCommunionTab) views.add(_CommunionTab(massData: massData));
    return views;
  }

  Widget _buildScrollView(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final parts = massData.readingParts ?? [];
    final labels = _readingPartLabels(parts);

    return PinchZoomSelectionArea(
      child: CustomScrollView(
        slivers: [
          if (_hasOfficeTab)
            SliverToBoxAdapter(
              child: _OfficeTab(
                celebrationKey: celebrationKey,
                massDefinition: massDefinition,
                massList: massList,
                selectedCommon: selectedCommon,
                onCelebrationChanged: onCelebrationChanged,
                onCommonChanged: onCommonChanged,
                onPrecedenceOverridden: onPrecedenceOverridden,
                hasMultipleCelebrations: _hasMultipleCelebrations,
                needsCommonSelection: _needsCommonSelection,
                shrinkWrap: true,
              ),
            ),
          SliverToBoxAdapter(
            child: _IntroductionTab(
              massDefinition: massDefinition,
              massData: massData,
              calendar: calendar,
              date: date,
              shrinkWrap: true,
            ),
          ),
          for (var i = 0; i < parts.length; i++)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: i > 0 ? 8.0 * zoom / 100 : 0),
                child: _ReadingPartTab(
                  part: parts[i],
                  label: labels[i],
                  liturgicalTime: massDefinition.liturgicalTime,
                  shrinkWrap: true,
                ),
              ),
            ),
          if (_hasOfferingTab)
            SliverToBoxAdapter(
                child: _OfferingTab(massData: massData, shrinkWrap: true)),
          if (_hasCommunionTab)
            SliverToBoxAdapter(
                child: _CommunionTab(massData: massData, shrinkWrap: true)),
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
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      children: [
        if (hasMultipleCelebrations) ...[
          OfficeSectionTitle(liturgyLabels['select-office']!),
          CelebrationChipsSelector(
            celebrationMap: massList,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
            onPrecedenceOverridden: onPrecedenceOverridden,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (hasMultipleCelebrations && needsCommonSelection)
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
      ],
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
      LiturgyPartTitle('Antienne d\'entrée', left: LiturgyRowLeft.indent),
      AntiphonWidget(
        antiphon1: entrance[0].content ?? '',
        antiphon2: entrance.length > 1 ? entrance[1].content : null,
        antiphon3: entrance.length > 2 ? entrance[2].content : null,
        reference1: entrance[0].biblicalReference,
        reference2: entrance.length > 1 ? entrance[1].biblicalReference : null,
        reference3: entrance.length > 2 ? entrance[2].biblicalReference : null,
      ),
      SizedBox(height: 16.0 * zoom / 100),
    ],
    if (massData.collect?.isNotEmpty ?? false) ...[
      LiturgyPartTitle('Prière d\'ouverture', left: LiturgyRowLeft.indent),
      ...buildOrationWidgets(massData.collect,
          zoom: zoom, rightIndentMultiplier: 0.75),
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
    required this.part,
    required this.label,
    required this.liturgicalTime,
    this.leading = const [],
    this.shrinkWrap = false,
  });

  final MassReadingPart part;
  final String label;
  final String? liturgicalTime;
  final List<Widget> leading;
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
      children: [...leading, ..._buildPartContent(zoom)],
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
            content: r.content,
          ));
        case MassPsalm p:
          widgets.add(_MassPsalmContent(psalm: p, title: label));
        case MassGospel g:
          widgets.add(_MassGospelContent(
            gospel: g,
            title: label,
            liturgicalTime: liturgicalTime,
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

/// Title + right-aligned biblical reference + left-aligned content — like
/// ScriptureWidget, but left-aligned rather than justified. A separate
/// widget rather than a change to ScriptureWidget (which every other office
/// also uses and which justifies on purpose) to avoid touching shared
/// behaviour outside Mass.
class _MassScriptureWidget extends StatelessWidget {
  const _MassScriptureWidget({
    required this.title,
    this.reference,
    this.content,
  });

  final String title;
  final String? reference;
  final String? content;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiturgyPartTitle(title, left: LiturgyRowLeft.indent),
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
  const _MassPsalmContent({required this.psalm, required this.title});

  final MassPsalm psalm;
  final String title;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final reference = psalm.biblicalRef ?? psalm.refAbbr;
    final chorus = psalm.chorus ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiturgyPartTitle(title, left: LiturgyRowLeft.indent),
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
  });

  final MassGospel gospel;
  final String title;
  final String? liturgicalTime;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final reference = gospel.biblicalRef;
    final suppressAlleluia = _noAlleluiaTimes.contains(liturgicalTime);
    final acclamation = gospel.acclamationAntiphon;

    final acclamationLines = [
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
          SizedBox(height: 12.0 * zoom / 100),
        ],
        LiturgyPartTitle(title, left: LiturgyRowLeft.indent),
        if (reference != null && reference.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: BiblicalReferenceButton(reference: reference, zoom: zoom),
            ),
          ),
        if (gospel.headline != null && gospel.headline!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _MassHeadlineCommentary(gospel.headline!),
          ),
          SizedBox(height: 6.0 * zoom / 100),
        ],
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

/// Same structure as LiturgyPartCommentary (verse-column left border, small
/// italic text) but with a tighter line-height for the Gospel headline.
/// Not a change to the shared widget, which other offices use for Psalm
/// commentaries at their own line-height.
class _MassHeadlineCommentary extends StatelessWidget {
  const _MassHeadlineCommentary(this.content);

  final String content;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        verseIdPlaceholder(zoom: zoom),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.only(left: 8),
            child: YamlTextWidget(
              paragraphs: YamlTextParser.parseText(content),
              paragraphSpacing: 0,
              textStyle: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12.0 * zoom / 100,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
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
    final prefaceList = massData.prefaceList ?? [];
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
              zoom: zoom, rightIndentMultiplier: 0.75),
        ],
        if (prefaceList.isNotEmpty) ...[
          LiturgyPartTitle('Préface', left: LiturgyRowLeft.indent),
          LiturgyRow(
            left: LiturgyRowLeft.none,
            builder: (context, _) => YamlTextFromString(prefaceList.join(', ')),
          ),
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
          SizedBox(height: 16.0 * zoom / 100),
        ],
        if (massData.prayerAfterCommunion?.isNotEmpty ?? false) ...[
          LiturgyPartTitle('Prière après la communion',
              left: LiturgyRowLeft.indent),
          ...buildOrationWidgets(massData.prayerAfterCommunion,
              zoom: zoom, rightIndentMultiplier: 0.75),
        ],
      ],
    );
  }
}
