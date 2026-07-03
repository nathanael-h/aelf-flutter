import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/base_office_view_state.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_header_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';

/// Readings View
///
/// Architecture:
/// 1. ReadingsView (StatefulWidget) - Manages UI state and data resolution
/// 2. ReadingsOfficeDisplay (StatelessWidget) - Pure display widget
class ReadingsView extends StatefulWidget {
  const ReadingsView({
    super.key,
    required this.readingsDefinitions,
    required this.date,
    required this.calendar,
  });

  final Map<String, CelebrationContext> readingsDefinitions;
  final DateTime date;
  final Calendar calendar;

  @override
  State<ReadingsView> createState() => _ReadingsViewState();
}

class _ReadingsViewState extends BaseOfficeViewState<ReadingsView, Readings> {
  @override
  Map<String, CelebrationContext> get celebrationList =>
      widget.readingsDefinitions;

  @override
  DateTime get date => widget.date;

  @override
  Calendar get calendar => widget.calendar;

  @override
  String get debugOfficeName => 'Readings';

  @override
  bool hasInputChanged(ReadingsView oldWidget) =>
      oldWidget.date != widget.date ||
      oldWidget.readingsDefinitions != widget.readingsDefinitions;

  @override
  Future<Readings> exportOffice(CelebrationContext ctx) => readingsExport(ctx);

  @override
  Widget buildOfficeDisplay(
    BuildContext context, {
    required String celebrationKey,
    required CelebrationContext definition,
    required Readings officeData,
    required String? selectedCommon,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
    required void Function(String, int?) onPrecedenceOverridden,
  }) {
    return ReadingsOfficeDisplay(
      celebrationKey: celebrationKey,
      readingsDefinition: definition,
      readingsData: officeData,
      selectedCommon: selectedCommon,
      readingsDefinitions: widget.readingsDefinitions,
      onCelebrationChanged: onCelebrationChanged,
      onCommonChanged: onCommonChanged,
      onPrecedenceOverridden: onPrecedenceOverridden,
      calendar: widget.calendar,
      date: widget.date,
    );
  }
}

/// Pure display widget for Readings Office
class ReadingsOfficeDisplay extends StatelessWidget {
  const ReadingsOfficeDisplay({
    super.key,
    required this.celebrationKey,
    required this.readingsDefinition,
    required this.readingsData,
    required this.selectedCommon,
    required this.readingsDefinitions,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.calendar,
    required this.date,
  });

  final String celebrationKey;
  final CelebrationContext readingsDefinition;
  final Readings readingsData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> readingsDefinitions;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;
  final void Function(String key, int? precedence) onPrecedenceOverridden;
  final Calendar calendar;
  final DateTime date;

  bool _hasMultipleCelebrations() =>
      readingsDefinitions.values.where((d) => d.isCelebrable).length > 1;

  bool _needsCommonSelection() {
    final d = readingsDefinition;
    if (d.commonList == null || d.commonList!.isEmpty) return false;
    if (['paschaloctave', 'christmasoctave'].contains(d.liturgicalTime)) {
      return false;
    }
    return d.celebrationCode != d.ferialCode;
  }

  bool _hasOfficeTab() {
    if (_hasMultipleCelebrations()) return true;
    if (!_needsCommonSelection()) return false;
    final d = readingsDefinition;
    return (d.commonList?.length ?? 0) > 1 || (d.precedence ?? 13) > 8;
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
              child: TabBarView(
                children: _buildTabViews(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollView(BuildContext context) {
    final hasMultipleCelebrations = _hasMultipleCelebrations();
    final needsCommonSelection = _needsCommonSelection();
    final hasOfficeTab = _hasOfficeTab();
    return PinchZoomSelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasOfficeTab) ...[
              _OfficeTab(
                celebrationKey: celebrationKey,
                readingsDefinition: readingsDefinition,
                readingsDefinitions: readingsDefinitions,
                selectedCommon: selectedCommon,
                onCelebrationChanged: onCelebrationChanged,
                onCommonChanged: onCommonChanged,
                onPrecedenceOverridden: onPrecedenceOverridden,
                hasMultipleCelebrations: hasMultipleCelebrations,
                needsCommonSelection: needsCommonSelection,
                shrinkWrap: true,
              ),
            ],
            _IntroductionTab(
              readingsDefinition: readingsDefinition,
              calendar: calendar,
              date: date,
              shrinkWrap: true,
            ),
            HymnsTabWidget(
              hymns: readingsData.hymn ?? [],
              emptyMessage: liturgyLabels['no-hymn']!,
              shrinkWrap: true,
            ),
            LiturgyPartTitle(
              liturgyLabels['psalmody'] ?? 'Psalmodie',
              hideVerseIdPlaceholder: false,
            ),
            if (readingsData.psalmody != null) ...[
              for (final psalmEntry in readingsData.psalmody!)
                if (psalmEntry.psalm != null)
                  PsalmTabWidget(
                    psalm: psalmEntry.psalmData,
                    antiphon1: (psalmEntry.antiphon?.isNotEmpty ?? false)
                        ? psalmEntry.antiphon![0]
                        : null,
                    antiphon2: (psalmEntry.antiphon?.length ?? 0) > 1
                        ? psalmEntry.antiphon![1]
                        : null,
                    shrinkWrap: true,
                  ),
            ],
            _BiblicalReadingTab(readingsData: readingsData, shrinkWrap: true),
            _PatristicReadingTab(readingsData: readingsData, shrinkWrap: true),
            if (readingsData.tedeum == true)
              _TeDeumTab(readingsData: readingsData, shrinkWrap: true),
            _OrationTab(readingsData: readingsData, shrinkWrap: true),
          ],
        ),
      ),
    );
  }

  int _calculateTabCount() {
    return 2 // Intro + Hymn
        +
        (readingsData.psalmody?.length ?? 0) +
        1 // Biblical
        +
        1 // Patristic
        +
        (readingsData.tedeum == true ? 1 : 0) +
        1 // Oration
        +
        (_hasOfficeTab() ? 1 : 0);
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[];

    if (_hasOfficeTab()) {
      tabs.add(Tab(text: liturgyLabels['office'] ?? 'Office'));
    }

    tabs.add(Tab(text: liturgyLabels['introduction']));
    tabs.add(Tab(text: liturgyLabels['hymns']));

    if (readingsData.psalmody != null) {
      for (var psalmEntry in readingsData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final tabText =
            getPsalmDisplayTitle(psalmEntry.psalmData, psalmEntry.psalm!);
        tabs.add(Tab(text: tabText));
      }
    }

    tabs.addAll([
      Tab(text: liturgyLabels['biblical_reading']),
      Tab(text: liturgyLabels['patristic_reading']),
    ]);

    if (readingsData.tedeum == true) {
      tabs.add(const Tab(text: 'Te Deum'));
    }

    tabs.add(Tab(text: liturgyLabels['oration']));

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[];
    final hasMultipleCelebrations = _hasMultipleCelebrations();
    final needsCommonSelection = _needsCommonSelection();

    if (_hasOfficeTab()) {
      views.add(_OfficeTab(
        celebrationKey: celebrationKey,
        readingsDefinition: readingsDefinition,
        readingsDefinitions: readingsDefinitions,
        selectedCommon: selectedCommon,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
        onPrecedenceOverridden: onPrecedenceOverridden,
        hasMultipleCelebrations: hasMultipleCelebrations,
        needsCommonSelection: needsCommonSelection,
      ));
    }

    views.add(_IntroductionTab(
      readingsDefinition: readingsDefinition,
      calendar: calendar,
      date: date,
    ));

    views.add(HymnsTabWidget(
      hymns: readingsData.hymn ?? [],
      emptyMessage: liturgyLabels['no-hymn']!,
    ));

    if (readingsData.psalmody != null) {
      int psalmIndex = 0;
      for (var psalmEntry in readingsData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final antiphons = psalmEntry.antiphon ?? [];

        views.add(PsalmTabWidget(
          psalm: psalmEntry.psalmData,
          antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
          antiphon2: antiphons.length > 1 ? antiphons[1] : null,
          verseAfter: psalmIndex == 2 ? readingsData.verse : null,
        ));
        psalmIndex++;
      }
    }

    views.addAll([
      _BiblicalReadingTab(readingsData: readingsData),
      _PatristicReadingTab(readingsData: readingsData),
    ]);

    if (readingsData.tedeum == true) {
      views.add(_TeDeumTab(readingsData: readingsData));
    }

    views.add(_OrationTab(readingsData: readingsData));

    return views;
  }
}

/// Office tab - displays celebration/common selectors and celebration description
class _OfficeTab extends StatelessWidget {
  const _OfficeTab({
    required this.celebrationKey,
    required this.readingsDefinition,
    required this.readingsDefinitions,
    required this.selectedCommon,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.hasMultipleCelebrations,
    required this.needsCommonSelection,
    this.shrinkWrap = false,
  });

  final String celebrationKey;
  final CelebrationContext readingsDefinition;
  final Map<String, CelebrationContext> readingsDefinitions;
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
            celebrationMap: readingsDefinitions,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
            onPrecedenceOverridden: onPrecedenceOverridden,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (hasMultipleCelebrations && needsCommonSelection)
          const Divider(height: 1),
        if (needsCommonSelection) ...[
          if ((readingsDefinition.commonList?.length ?? 0) > 1 ||
              (readingsDefinition.precedence ?? 13) > 8)
            OfficeSectionTitle(liturgyLabels['select-common']!),
          CommonChipsSelector(
            commonList: readingsDefinition.commonList ?? [],
            commonTitles: readingsDefinition.commonTitles,
            selectedCommon: selectedCommon,
            precedence: readingsDefinition.precedence ?? 13,
            onCommonChanged: onCommonChanged,
            forceCommon: readingsDefinition.celebrationCode ==
                'roman/virgin-mary-memory',
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
      ],
    );
  }
}

/// Introduction tab
class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.readingsDefinition,
    required this.calendar,
    required this.date,
    this.shrinkWrap = false,
  });

  final CelebrationContext readingsDefinition;
  final Calendar calendar;
  final DateTime date;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final isLent = readingsDefinition.liturgicalTime == 'lent' ||
        readingsDefinition.liturgicalTime == 'holyweek';
    final introText = isLent
        ? liturgyLabels['officeIntroductionLent']!
        : liturgyLabels['officeIntroduction']!;
    final additionalInfo =
        officeAdditionalInfo(readingsDefinition.liturgicalTime, calendar, date);

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      children: [
        OfficeHeaderDisplay(
          officeDescription: readingsDefinition.officeDescription,
          liturgicalColor: readingsDefinition.liturgicalColor,
          typeLabel: readingsDefinition.celebrationDisplayLabel,
          celebrationDescription: readingsDefinition.celebrationDescription,
          additionalInfo: additionalInfo,
        ),
        LiturgyPartTitle(liturgyLabels['introduction'],
            hideVerseIdPlaceholder: false),
        LiturgyRow(
          hideVerseIdPlaceholder: true,
          builder: (context, _) =>
              YamlTextFromString(introText, useSymbolColumn: true),
        ),
        SizedBox(height: 12.0 * zoom / 100),
      ],
    );
  }
}

class _BiblicalReadingTab extends StatelessWidget {
  const _BiblicalReadingTab(
      {required this.readingsData, this.shrinkWrap = false});
  final Readings readingsData;
  final bool shrinkWrap;
  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final biblicalReadings = readingsData.biblicalReading;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        LiturgyPartTitle(liturgyLabels['biblical_reading'],
            hideVerseIdPlaceholder: false),
        SizedBox(height: 16.0 * zoom / 100),
        if (biblicalReadings != null) ...[
          for (var i = 0; i < biblicalReadings.length; i++) ...[
            if (i > 0) SizedBox(height: 24.0 * zoom / 100),
            _buildBiblicalReading(biblicalReadings[i], zoom: zoom),
          ]
        ] else
          LiturgyRow(
            builder: (context, zoom) =>
                Text(liturgyLabels['no-biblical-reading']!),
          ),
      ],
    );
  }

  Widget _buildBiblicalReading(BiblicalReading reading,
      {required double zoom}) {
    Widget Function(double z)? refTrailing;
    if (reading.ref != null && reading.ref!.isNotEmpty) {
      refTrailing =
          (z) => BiblicalReferenceButton(reference: reading.ref!, zoom: z);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reading.title != null)
          LiturgyContentTitle(reading.title!, showBullet: false),
        if (reading.subtitle != null) ...[
          SizedBox(height: 4.0 * zoom / 100),
          LiturgyRow(
            builder: (context, z) => YamlTextFromString(reading.subtitle!,
                textStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14 * (z ?? 100) / 100)),
          ),
        ],
        if (refTrailing != null)
          LiturgyRow(
            builder: (context, z) => Align(
              alignment: Alignment.centerRight,
              child: refTrailing!(zoom),
            ),
          ),
        if (reading.content != null) ...[
          SizedBox(height: 12.0 * zoom / 100),
          LiturgyRow(
            builder: (context, z) => YamlTextFromString(reading.content!,
                textAlign: TextAlign.justify),
          ),
        ],
        if (reading.responsory != null) ...[
          SizedBox(height: 24.0 * zoom / 100),
          LiturgyPartTitle(liturgyLabels['responsory'],
              hideVerseIdPlaceholder: false),
          LiturgyRow(
            builder: (context, z) => YamlTextFromString(reading.responsory!),
          ),
        ],
      ],
    );
  }
}

class _PatristicReadingTab extends StatelessWidget {
  const _PatristicReadingTab(
      {required this.readingsData, this.shrinkWrap = false});
  final Readings readingsData;
  final bool shrinkWrap;
  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final patristicReadings = readingsData.patristicReading;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        LiturgyPartTitle(liturgyLabels['patristic_reading'],
            hideVerseIdPlaceholder: false),
        SizedBox(height: 16.0 * zoom / 100),
        if (patristicReadings != null) ...[
          for (var i = 0; i < patristicReadings.length; i++) ...[
            if (i > 0) SizedBox(height: 24.0 * zoom / 100),
            _buildPatristicReading(patristicReadings[i], zoom: zoom),
          ]
        ] else
          LiturgyRow(
            builder: (context, zoom) =>
                Text(liturgyLabels['no-patristic-reading']!),
          ),
      ],
    );
  }

  Widget _buildPatristicReading(PatristicReading reading,
      {required double zoom}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reading.title != null)
          LiturgyContentTitle(reading.title!, showBullet: false),
        if (reading.subtitle != null) ...[
          SizedBox(height: 4.0 * zoom / 100),
          LiturgyRow(
            builder: (context, z) => YamlTextFromString(reading.subtitle!,
                textStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14 * (z ?? 100) / 100)),
          ),
        ],
        if (reading.content != null) ...[
          SizedBox(height: 12.0 * zoom / 100),
          LiturgyRow(
            builder: (context, z) => YamlTextFromString(reading.content!,
                textAlign: TextAlign.justify),
          ),
        ],
        if (reading.responsory != null) ...[
          SizedBox(height: 24.0 * zoom / 100),
          LiturgyPartTitle(liturgyLabels['responsory'],
              hideVerseIdPlaceholder: false),
          LiturgyRow(
            builder: (context, z) => YamlTextFromString(reading.responsory!),
          ),
        ],
      ],
    );
  }
}

class _TeDeumTab extends StatelessWidget {
  const _TeDeumTab({required this.readingsData, this.shrinkWrap = false});
  final Readings readingsData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        LiturgyPartTitle(liturgyLabels['te-deum'],
            hideVerseIdPlaceholder: false),
        if (readingsData.tedeumContent != null) ...[
          SizedBox(height: 12.0 * zoom / 100),
          LiturgyRow(
            builder: (context, zoom) =>
                YamlTextFromString(readingsData.tedeumContent!),
          ),
        ] else
          LiturgyRow(
            builder: (context, zoom) => Text(liturgyLabels['no-te-deum']!),
          ),
      ],
    );
  }
}

class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.readingsData, this.shrinkWrap = false});
  final Readings readingsData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        LiturgyPartTitle(liturgyLabels['oration'],
            hideVerseIdPlaceholder: false),
        SizedBox(height: 12.0 * zoom / 100),
        ...buildOrationWidgets(readingsData.oration, zoom: zoom),
        LiturgyPartTitle(liturgyLabels['blessing'],
            hideVerseIdPlaceholder: false),
        LiturgyRow(
          hideVerseIdPlaceholder: true,
          builder: (context, zoom) => YamlTextFromString(
            liturgyLabels['shortBlessing'] ?? 'shortBlessing',
            useSymbolColumn: true,
          ),
        ),
      ],
    );
  }
}
