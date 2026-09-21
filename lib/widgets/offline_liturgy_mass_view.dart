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
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
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
              child: TabBarView(children: _buildTabViews()),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTabCount() {
    final readingTabs = massData.readingParts?.length ?? 0;
    return 4 + readingTabs + (_hasOfficeTab ? 1 : 0);
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[];
    if (_hasOfficeTab) {
      tabs.add(Tab(text: liturgyLabels['office'] ?? 'Office'));
    }
    tabs.add(Tab(text: liturgyLabels['introduction']));
    for (final label in _readingPartLabels(massData.readingParts ?? [])) {
      tabs.add(Tab(text: label));
    }
    tabs.addAll(const [
      Tab(text: 'Offrandes'),
      Tab(text: 'Communion'),
      Tab(text: 'Bénédiction'),
    ]);
    return tabs;
  }

  List<Widget> _buildTabViews() {
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
    views.add(_IntroductionTab(
      massDefinition: massDefinition,
      massData: massData,
      calendar: calendar,
      date: date,
    ));
    final parts = massData.readingParts ?? [];
    final labels = _readingPartLabels(parts);
    for (var i = 0; i < parts.length; i++) {
      views.add(_ReadingPartTab(part: parts[i], label: labels[i]));
    }
    views.addAll([
      _OfferingTab(massData: massData),
      _CommunionTab(massData: massData),
      _BlessingTab(massData: massData),
    ]);
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
                  shrinkWrap: true,
                ),
              ),
            ),
          SliverToBoxAdapter(
              child: _OfferingTab(massData: massData, shrinkWrap: true)),
          SliverToBoxAdapter(
              child: _CommunionTab(massData: massData, shrinkWrap: true)),
          SliverToBoxAdapter(
              child: _BlessingTab(massData: massData, shrinkWrap: true)),
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
    final additionalInfo =
        officeAdditionalInfo(massDefinition.liturgicalTime, calendar, date);
    final entrance = massData.entranceAntiphon ?? [];

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: shrinkWrap
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
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
          ),
          SizedBox(height: 16.0 * zoom / 100),
        ],
        LiturgyPartTitle('Prière d\'ouverture', left: LiturgyRowLeft.indent),
        ...buildOrationWidgets(massData.collect, zoom: zoom),
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
    required this.part,
    required this.label,
    this.shrinkWrap = false,
  });

  final MassReadingPart part;
  final String label;
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
          widgets.add(ScriptureWidget(
            title: label,
            reference: r.biblicalRef,
            content: r.content,
          ));
        case MassPsalm p:
          widgets.add(_MassPsalmContent(psalm: p, title: label));
        case MassGospel g:
          widgets.add(_MassGospelContent(gospel: g, title: label));
      }
    }
    return widgets;
  }
}

class _MassPsalmContent extends StatelessWidget {
  const _MassPsalmContent({required this.psalm, required this.title});

  final MassPsalm psalm;
  final String title;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final reference = psalm.refAbbr ?? psalm.biblicalRef;
    final chorus = psalm.chorus ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiturgyPartTitle(title, left: LiturgyRowLeft.indent),
        if (reference != null && reference.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => Align(
              alignment: Alignment.centerRight,
              child: Text(reference,
                  style: TextStyle(fontSize: 13.0 * zoom / 100)),
            ),
          ),
        SizedBox(height: 6.0 * zoom / 100),
        if (chorus.isNotEmpty) ...[
          AntiphonWidget(
            antiphon1: chorus[0].chorus ?? '',
            antiphon2: chorus.length > 1 ? chorus[1].chorus : null,
            antiphon3: chorus.length > 2 ? chorus[2].chorus : null,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (psalm.content != null && psalm.content!.isNotEmpty)
          LiturgyRow(
            builder: (context, _) => YamlTextFromString(
              psalm.content!,
              textAlign: TextAlign.justify,
            ),
          ),
      ],
    );
  }
}

class _MassGospelContent extends StatelessWidget {
  const _MassGospelContent({required this.gospel, required this.title});

  final MassGospel gospel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final before = gospel.beforeAcclamationAntiphon;
    final acclamation = gospel.acclamationAntiphon;
    final after = gospel.afterAcclamationAntiphon;
    final hasAcclamation = (before?.isNotEmpty ?? false) ||
        (acclamation?.isNotEmpty ?? false) ||
        (after?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAcclamation) ...[
          if (before != null && before.isNotEmpty)
            LiturgyRow(
              left: LiturgyRowLeft.none,
              builder: (context, _) =>
                  YamlTextFromString(before, textAlign: TextAlign.center),
            ),
          if (acclamation != null && acclamation.isNotEmpty)
            LiturgyRow(
              left: LiturgyRowLeft.none,
              builder: (context, _) =>
                  YamlTextFromString(acclamation, textAlign: TextAlign.center),
            ),
          if (after != null && after.isNotEmpty)
            LiturgyRow(
              left: LiturgyRowLeft.none,
              builder: (context, _) =>
                  YamlTextFromString(after, textAlign: TextAlign.center),
            ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        ScriptureWidget(
          title: title,
          reference: gospel.biblicalRef,
          content: gospel.content,
        ),
      ],
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
        LiturgyPartTitle('Prière sur les offrandes',
            left: LiturgyRowLeft.indent),
        ...buildOrationWidgets(massData.offeringPrayer, zoom: zoom),
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
          ),
          SizedBox(height: 16.0 * zoom / 100),
        ],
        LiturgyPartTitle('Prière après la communion',
            left: LiturgyRowLeft.indent),
        ...buildOrationWidgets(massData.prayerAfterCommunion, zoom: zoom),
      ],
    );
  }
}

class _BlessingTab extends StatelessWidget {
  const _BlessingTab({required this.massData, this.shrinkWrap = false});

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
        LiturgyPartTitle('Bénédiction', left: LiturgyRowLeft.indent),
        ...buildOrationWidgets(massData.solemnBlessingList, zoom: zoom),
      ],
    );
  }
}
