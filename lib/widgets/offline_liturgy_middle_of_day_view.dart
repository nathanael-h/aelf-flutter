import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_header_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_section_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';

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

class _MiddleOfDayOfficeViewState extends State<MiddleOfDayOfficeView> {
  bool _isLoading = true;
  String? _celebrationKey;
  CelebrationContext? _selectedDefinition;
  MiddleOfDay? _officeData;
  String? _selectedCommon;
  String? _errorMessage;
  bool _imprecatoryVerses = false;

  @override
  void initState() {
    super.initState();
    _loadOffice();
  }

  @override
  void didUpdateWidget(MiddleOfDayOfficeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.middleOfDayList != widget.middleOfDayList) {
      _loadOffice();
    }
  }

  Future<void> _loadOffice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firstOption = widget.middleOfDayList.entries
          .where((entry) => entry.value.isCelebrable)
          .firstOrNull;

      if (firstOption == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = liturgyLabels['no-office']!;
        });
        return;
      }

      // Try to use globally remembered celebration
      final globalState = context.read<SelectedCelebrationState>();
      final globalKey = globalState.celebrationKey;
      final globalEntry = (globalKey != null)
          ? widget.middleOfDayList.entries
              .where((e) => e.key == globalKey && e.value.isCelebrable)
              .firstOrNull
          : null;

      final selectedEntry = globalEntry ?? firstOption;
      _celebrationKey = selectedEntry.key;
      _selectedDefinition = selectedEntry.value;
      _imprecatoryVerses = await getImprecatoryVerses();

      // Determine common
      String? autoCommon;
      final commonList = _selectedDefinition!.commonList;
      if (commonList != null && commonList.isNotEmpty) {
        if (_selectedDefinition!.celebrationCode !=
            _selectedDefinition!.ferialCode) {
          if (globalState.commonSet) {
            final globalCommon = globalState.common;
            if (globalCommon == null) {
              autoCommon = null;
            } else if (commonList.contains(globalCommon)) {
              autoCommon = globalCommon;
            } else {
              autoCommon = commonList.first;
            }
          } else {
            autoCommon = commonList.first;
          }
        }
      }
      _selectedCommon = autoCommon;

      final celebrationContext = _selectedDefinition!.copyWith(
        commonList: autoCommon != null
            ? [autoCommon]
            : (_selectedDefinition!.commonList ?? []),
        showImprecatoryVerses: _imprecatoryVerses,
      );
      final officeData = await middleOfDayExport(celebrationContext);

      if (mounted) {
        setState(() {
          _officeData = officeData;
          _isLoading = false;
        });
        globalState.setCelebration(_celebrationKey);
        globalState.setCommon(autoCommon);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels["error-office"]!}: $e';
        });
      }
    }
  }

  Future<void> _onCelebrationChanged(String key) async {
    final definition = widget.middleOfDayList[key];
    if (definition == null) return;

    setState(() => _isLoading = true);

    try {
      String? autoCommon;
      final commonList = definition.commonList;
      if (commonList != null && commonList.isNotEmpty) {
        if (definition.celebrationCode != definition.ferialCode) {
          autoCommon = commonList.first;
        }
      }

      final celebrationContext = definition.copyWith(
        commonList:
            autoCommon != null ? [autoCommon] : (definition.commonList ?? []),
        showImprecatoryVerses: _imprecatoryVerses,
      );
      final officeData = await middleOfDayExport(celebrationContext);

      if (mounted) {
        setState(() {
          _celebrationKey = key;
          _selectedDefinition = definition;
          _selectedCommon = autoCommon;
          _officeData = officeData;
          _isLoading = false;
        });
        context.read<SelectedCelebrationState>().setCelebration(key);
        context.read<SelectedCelebrationState>().setCommon(autoCommon);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels["error"]!}: $e';
        });
      }
    }
  }

  Future<void> _onCommonChanged(String? common) async {
    if (_selectedDefinition == null) return;

    setState(() => _isLoading = true);

    try {
      final celebrationContext = _selectedDefinition!.copyWith(
        commonList: common != null ? [common] : [],
        showImprecatoryVerses: _imprecatoryVerses,
      );
      final officeData = await middleOfDayExport(celebrationContext);

      if (mounted) {
        setState(() {
          _selectedCommon = common;
          _officeData = officeData;
          _isLoading = false;
        });
        context.read<SelectedCelebrationState>().setCommon(common);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels["error"]!}: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOffice,
              child: Text(liturgyLabels['retry']!),
            ),
          ],
        ),
      );
    }
    if (_celebrationKey != null &&
        _selectedDefinition != null &&
        _officeData != null) {
      return _OfficeDisplay(
        celebrationKey: _celebrationKey!,
        definition: _selectedDefinition!.copyWith(showImprecatoryVerses: _imprecatoryVerses),
        officeData: _officeData!,
        selectedCommon: _selectedCommon,
        middleOfDayList: widget.middleOfDayList,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
        hymnSelector: widget.hymnSelector,
        hourOfficeSelector: widget.hourOfficeSelector,
        psalmodySelector: widget.psalmodySelector,
        calendar: widget.calendar,
        date: widget.date,
      );
    }
    return Center(child: Text(liturgyLabels['no-data']!));
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
    return DefaultTabController(
      length: _calculateTabCount(),
      child: Column(
        children: [
          _buildTabBar(context),
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
    // Introduction + Hymne + Psaumes + Capitule (+ Office tab if needed)
    return 3 +
        (psalmodySelector(officeData)?.length ?? 0) +
        (_hasOfficeTab() ? 1 : 0);
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: TabBar(
          isScrollable: true,
          indicatorColor: Theme.of(context).tabBarTheme.labelColor ??
              Theme.of(context).colorScheme.secondary,
          labelColor: Theme.of(context).tabBarTheme.labelColor ??
              Theme.of(context).colorScheme.secondary,
          unselectedLabelColor:
              Theme.of(context).tabBarTheme.unselectedLabelColor ??
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          tabs: _buildTabs(),
        ),
      ),
    );
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
          hasMultipleCelebrations: _hasMultipleCelebrations(),
          needsCommonSelection: _needsCommonSelection(),
        ),
      );
    }
    views.add(_IntroductionTab(definition: definition, calendar: calendar, date: date));
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
            imprecatory: definition.showImprecatoryVerses,
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
    required this.hasMultipleCelebrations,
    required this.needsCommonSelection,
  });

  final String celebrationKey;
  final CelebrationContext definition;
  final Map<String, CelebrationContext> middleOfDayList;
  final String? selectedCommon;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;
  final bool hasMultipleCelebrations;
  final bool needsCommonSelection;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        if (hasMultipleCelebrations) ...[
          OfficeSectionTitle(liturgyLabels['select-office']!),
          CelebrationChipsSelector(
            celebrationMap: middleOfDayList,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
          ),
          const SizedBox(height: 12.0),
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
          const SizedBox(height: 12.0),
        ],
      ],
    );
  }
}

class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({required this.definition, required this.calendar, required this.date});

  final CelebrationContext definition;
  final Calendar calendar;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isLent = definition.liturgicalTime == 'lent' ||
        definition.liturgicalTime == 'holyweek';
    final introText = isLent
        ? (liturgyLabels['officeIntroductionLent'] ?? '')
        : (liturgyLabels['officeIntroduction'] ?? '');
    final additionalInfo = officeAdditionalInfo(definition.liturgicalTime, calendar, date);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        OfficeHeaderDisplay(
          officeDescription: definition.officeDescription,
          liturgicalColor: definition.liturgicalColor,
          precedence: definition.precedence,
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
              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ],
    );
  }
}

class _CapituleTab extends StatelessWidget {
  const _CapituleTab({required this.hourOffice, required this.officeData});
  final HourOffice? hourOffice;
  final MiddleOfDay officeData;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScriptureWidget(
          title: liturgyLabels['word_of_god'] ?? 'Parole de Dieu',
          reference: hourOffice?.reading?.biblicalReference,
          content: hourOffice?.reading?.content,
        ),
        const SizedBox(height: 12.0),
        const SizedBox(height: 12.0),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
        YamlTextFromString(
          hourOffice?.responsory ?? liturgyLabels['no-responsory']!,
        ),
        const SizedBox(height: 12.0),
        const SizedBox(height: 12.0),
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        ...buildOrationWidgets(officeData.oration),
        const SizedBox(height: 24.0),
        LiturgyPartTitle(liturgyLabels['blessing']),
        YamlTextFromString(liturgyLabels['shortBlessing'] ?? 'shortBlessing'),
      ],
    );
  }
}
