import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/base_office_view_state.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_header_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// Generic widget shared by TierceView, SexteView and NoneView.
/// [hymnSelector] extracts the relevant hymn list from [MiddleOfDay].
/// [hourOfficeSelector] extracts the relevant [HourOffice] from [MiddleOfDay].
class MiddleOfDayOfficeView extends StatefulWidget {
  const MiddleOfDayOfficeView({
    super.key,
    required this.middleOfDayList,
    required this.date,
    required this.calendar,
    required this.hymnSelector,
    required this.hourOfficeSelector,
    required this.psalmodySelector,
  });

  final Map<String, CelebrationContext> middleOfDayList;
  final DateTime date;
  final Calendar calendar;
  final List<HymnEntry>? Function(MiddleOfDay) hymnSelector;
  final HourOffice? Function(MiddleOfDay) hourOfficeSelector;
  final List<PsalmEntry>? Function(MiddleOfDay) psalmodySelector;

  @override
  State<MiddleOfDayOfficeView> createState() => _MiddleOfDayOfficeViewState();
}

class _MiddleOfDayOfficeViewState
    extends BaseOfficeViewState<MiddleOfDayOfficeView, MiddleOfDay> {
  @override
  Map<String, CelebrationContext> get celebrationList => widget.middleOfDayList;

  @override
  DateTime get date => widget.date;

  @override
  Calendar get calendar => widget.calendar;

  @override
  String get debugOfficeName => 'MiddleOfDay';

  @override
  bool hasInputChanged(MiddleOfDayOfficeView oldWidget) =>
      oldWidget.date != widget.date ||
      oldWidget.middleOfDayList != widget.middleOfDayList;

  @override
  Future<MiddleOfDay> exportOffice(CelebrationContext ctx) =>
      middleOfDayExport(ctx);

  @override
  Widget buildOfficeDisplay(
    BuildContext context, {
    required String celebrationKey,
    required CelebrationContext definition,
    required MiddleOfDay officeData,
    required String? selectedCommon,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
    required void Function(String, int?) onPrecedenceOverridden,
  }) {
    return _OfficeDisplay(
      celebrationKey: celebrationKey,
      definition: definition,
      officeData: officeData,
      selectedCommon: selectedCommon,
      middleOfDayList: widget.middleOfDayList,
      onCelebrationChanged: onCelebrationChanged,
      onCommonChanged: onCommonChanged,
      onPrecedenceOverridden: onPrecedenceOverridden,
      hymnSelector: widget.hymnSelector,
      hourOfficeSelector: widget.hourOfficeSelector,
      psalmodySelector: widget.psalmodySelector,
      calendar: widget.calendar,
      date: widget.date,
    );
  }
}

class _OfficeDisplay extends StatelessWidget {
  const _OfficeDisplay({
    required this.celebrationKey,
    required this.definition,
    required this.officeData,
    required this.selectedCommon,
    required this.middleOfDayList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.hymnSelector,
    required this.hourOfficeSelector,
    required this.psalmodySelector,
    required this.calendar,
    required this.date,
  });

  final String celebrationKey;
  final CelebrationContext definition;
  final MiddleOfDay officeData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> middleOfDayList;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;
  final void Function(String key, int? precedence) onPrecedenceOverridden;
  final List<HymnEntry>? Function(MiddleOfDay) hymnSelector;
  final HourOffice? Function(MiddleOfDay) hourOfficeSelector;
  final List<PsalmEntry>? Function(MiddleOfDay) psalmodySelector;
  final Calendar calendar;
  final DateTime date;

  bool _hasMultipleCelebrations() {
    return middleOfDayList.values.where((d) => d.isCelebrable).length > 1;
  }

  bool _needsCommonSelection() {
    final commonList = definition.commonList;
    final liturgicalTime = definition.liturgicalTime;

    if (commonList == null || commonList.isEmpty) return false;
    if (liturgicalTime == 'paschaloctave' ||
        liturgicalTime == 'christmasoctave') {
      return false;
    }
    if (definition.celebrationCode == definition.ferialCode) return false;

    return true;
  }

  bool _hasOfficeTab() {
    if (_hasMultipleCelebrations()) return true;
    if (!_needsCommonSelection()) return false;
    return (definition.commonList?.length ?? 0) > 1 ||
        (definition.precedence ?? 13) > 8;
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

  Widget _buildScrollView(BuildContext context) {
    final psalmody = psalmodySelector(officeData);
    return PinchZoomSelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasOfficeTab()) ...[
              _OfficeTab(
                celebrationKey: celebrationKey,
                definition: definition,
                middleOfDayList: middleOfDayList,
                selectedCommon: selectedCommon,
                onCelebrationChanged: onCelebrationChanged,
                onCommonChanged: onCommonChanged,
                onPrecedenceOverridden: onPrecedenceOverridden,
                hasMultipleCelebrations: _hasMultipleCelebrations(),
                needsCommonSelection: _needsCommonSelection(),
                shrinkWrap: true,
              ),
              const Divider(height: 1),
            ],
            _IntroductionTab(
                definition: definition,
                calendar: calendar,
                date: date,
                shrinkWrap: true),
            const Divider(height: 1),
            HymnsTabWidget(
              hymns: hymnSelector(officeData) ?? [],
              emptyMessage: liturgyLabels['no-hymn']!,
              shrinkWrap: true,
            ),
            if (psalmody != null)
              for (var psalmEntry in psalmody)
                if (psalmEntry.psalm != null) ...[
                  const Divider(height: 1),
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
            const Divider(height: 1),
            _CapituleTab(
              hourOffice: hourOfficeSelector(officeData),
              officeData: officeData,
              shrinkWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  int _calculateTabCount() {
    // Introduction + Hymne + Psaumes + Capitule (+ Office tab if needed)
    return 3 +
        (psalmodySelector(officeData)?.length ?? 0) +
        (_hasOfficeTab() ? 1 : 0);
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[];
    if (_hasOfficeTab()) {
      tabs.add(Tab(text: liturgyLabels['office'] ?? 'Office'));
    }
    tabs.add(Tab(text: liturgyLabels['introduction']));
    tabs.add(Tab(text: liturgyLabels['hymns']));
    final psalmody = psalmodySelector(officeData);
    if (psalmody != null) {
      for (var psalmEntry in psalmody) {
        if (psalmEntry.psalm == null) continue;
        final tabText = getPsalmDisplayTitle(
          psalmEntry.psalmData,
          psalmEntry.psalm!,
        );
        tabs.add(Tab(text: tabText));
      }
    }
    tabs.add(Tab(text: liturgyLabels['capitule']));
    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[];
    if (_hasOfficeTab()) {
      views.add(
        _OfficeTab(
          celebrationKey: celebrationKey,
          definition: definition,
          middleOfDayList: middleOfDayList,
          selectedCommon: selectedCommon,
          onCelebrationChanged: onCelebrationChanged,
          onCommonChanged: onCommonChanged,
          onPrecedenceOverridden: onPrecedenceOverridden,
          hasMultipleCelebrations: _hasMultipleCelebrations(),
          needsCommonSelection: _needsCommonSelection(),
        ),
      );
    }
    views.add(_IntroductionTab(
        definition: definition, calendar: calendar, date: date));
    views.add(
      HymnsTabWidget(
        hymns: hymnSelector(officeData) ?? <HymnEntry>[],
        emptyMessage: liturgyLabels['no-hymn']!,
      ),
    );
    final psalmody = psalmodySelector(officeData);
    if (psalmody != null) {
      for (var psalmEntry in psalmody) {
        if (psalmEntry.psalm == null) continue;
        final antiphons = psalmEntry.antiphon ?? [];
        views.add(
          PsalmTabWidget(
            psalm: psalmEntry.psalmData,
            antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
            antiphon2: antiphons.length > 1 ? antiphons[1] : null,
          ),
        );
      }
    }
    views.add(
      _CapituleTab(
        hourOffice: hourOfficeSelector(officeData),
        officeData: officeData,
      ),
    );
    return views;
  }
}

class _OfficeTab extends StatelessWidget {
  const _OfficeTab({
    required this.celebrationKey,
    required this.definition,
    required this.middleOfDayList,
    required this.selectedCommon,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.hasMultipleCelebrations,
    required this.needsCommonSelection,
    this.shrinkWrap = false,
  });

  final String celebrationKey;
  final CelebrationContext definition;
  final Map<String, CelebrationContext> middleOfDayList;
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
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        if (hasMultipleCelebrations) ...[
          OfficeSectionTitle(liturgyLabels['select-office']!),
          CelebrationChipsSelector(
            celebrationMap: middleOfDayList,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
            onPrecedenceOverridden: onPrecedenceOverridden,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (hasMultipleCelebrations && needsCommonSelection)
          const Divider(height: 1),
        if (needsCommonSelection) ...[
          if ((definition.commonList?.length ?? 0) > 1 ||
              (definition.precedence ?? 13) > 8)
            OfficeSectionTitle(liturgyLabels['select-common']!),
          CommonChipsSelector(
            commonList: definition.commonList ?? [],
            commonTitles: definition.commonTitles,
            selectedCommon: selectedCommon,
            precedence: definition.precedence ?? 13,
            onCommonChanged: onCommonChanged,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
      ],
    );
  }
}

class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab(
      {required this.definition,
      required this.calendar,
      required this.date,
      this.shrinkWrap = false});

  final CelebrationContext definition;
  final Calendar calendar;
  final DateTime date;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final isLent = definition.liturgicalTime == 'lent' ||
        definition.liturgicalTime == 'holyweek';
    final introText = isLent
        ? (liturgyLabels['officeIntroductionLent'] ?? '')
        : (liturgyLabels['officeIntroduction'] ?? '');
    final additionalInfo =
        officeAdditionalInfo(definition.liturgicalTime, calendar, date);

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        OfficeHeaderDisplay(
          officeDescription: definition.officeDescription,
          liturgicalColor: definition.liturgicalColor,
          typeLabel: definition.celebrationDisplayLabel,
          celebrationDescription: definition.celebrationDescription,
          additionalInfo: additionalInfo,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiturgyPartTitle(liturgyLabels['introduction'] ?? 'Introduction'),
              YamlTextFromString(introText),
              SizedBox(height: 12.0 * zoom / 100),
            ],
          ),
        ),
      ],
    );
  }
}

class _CapituleTab extends StatelessWidget {
  const _CapituleTab(
      {required this.hourOffice,
      required this.officeData,
      this.shrinkWrap = false});
  final HourOffice? hourOffice;
  final MiddleOfDay officeData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.all(16.0 * zoom / 100),
      children: [
        ScriptureWidget(
          title: liturgyLabels['word_of_god'] ?? 'Parole de Dieu',
          reference: hourOffice?.reading?.biblicalReference,
          content: hourOffice?.reading?.content,
        ),
        SizedBox(height: 24.0 * zoom / 100),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
        YamlTextFromString(
          hourOffice?.responsory ?? liturgyLabels['no-responsory']!,
        ),
        SizedBox(height: 24.0 * zoom / 100),
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        ...buildOrationWidgets(
          hourOffice?.oration != null
              ? [hourOffice!.oration!]
              : officeData.oration,
          zoom: zoom,
        ),
        SizedBox(height: 24.0 * zoom / 100),
        LiturgyPartTitle(liturgyLabels['blessing']),
        YamlTextFromString(liturgyLabels['shortBlessing'] ?? 'shortBlessing'),
      ],
    );
  }
}
