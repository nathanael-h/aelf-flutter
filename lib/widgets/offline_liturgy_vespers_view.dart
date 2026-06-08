import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/usual_texts.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/base_office_view_state.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_header_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// Vespers View
///
/// Architecture:
/// 1. VespersView (StatefulWidget) - Manages UI state and data loading
/// 2. VespersOfficeDisplay (StatelessWidget) - Pure display widget
class VespersView extends StatefulWidget {
  const VespersView(
      {super.key,
      required this.vespersList,
      required this.date,
      required this.calendar});

  final Map<String, CelebrationContext> vespersList;
  final DateTime date;
  final Calendar calendar;

  @override
  State<VespersView> createState() => _VespersViewState();
}

class _VespersViewState extends BaseOfficeViewState<VespersView, Vespers> {
  @override
  Map<String, CelebrationContext> get celebrationList => widget.vespersList;

  @override
  DateTime get date => widget.date;

  @override
  Calendar get calendar => widget.calendar;

  @override
  String get debugOfficeName => 'Vespers';

  @override
  bool hasInputChanged(VespersView oldWidget) =>
      oldWidget.date != widget.date ||
      oldWidget.vespersList != widget.vespersList;

  @override
  Future<Vespers> exportOffice(CelebrationContext ctx) => vespersExport(ctx);

  @override
  Widget buildOfficeDisplay(
    BuildContext context, {
    required String celebrationKey,
    required CelebrationContext definition,
    required Vespers officeData,
    required String? selectedCommon,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
    required void Function(String, int?) onPrecedenceOverridden,
  }) {
    return VespersOfficeDisplay(
      celebrationKey: celebrationKey,
      vespersDefinition: definition,
      vespersData: officeData,
      selectedCommon: selectedCommon,
      vespersList: widget.vespersList,
      onCelebrationChanged: onCelebrationChanged,
      onCommonChanged: onCommonChanged,
      onPrecedenceOverridden: onPrecedenceOverridden,
      calendar: widget.calendar,
      date: widget.date,
    );
  }
}

/// Pure display widget - receives all data, no async logic
class VespersOfficeDisplay extends StatelessWidget {
  const VespersOfficeDisplay({
    super.key,
    required this.celebrationKey,
    required this.vespersDefinition,
    required this.vespersData,
    required this.selectedCommon,
    required this.vespersList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.calendar,
    required this.date,
  });

  final String celebrationKey;
  final CelebrationContext vespersDefinition;
  final Vespers vespersData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> vespersList;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;
  final void Function(String key, int? precedence) onPrecedenceOverridden;
  final Calendar calendar;
  final DateTime date;

  bool _hasMultipleCelebrations() =>
      vespersList.values.where((d) => d.isCelebrable).length > 1;

  bool _needsCommonSelection() {
    final d = vespersDefinition;
    if (d.commonList == null || d.commonList!.isEmpty) return false;
    if (['paschaloctave', 'christmasoctave'].contains(d.liturgicalTime)) {
      return false;
    }
    return d.celebrationCode != d.ferialCode;
  }

  bool _hasOfficeTab() {
    if (_hasMultipleCelebrations()) return true;
    if (!_needsCommonSelection()) return false;
    final d = vespersDefinition;
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
              child: TabBarView(children: _buildTabViews()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollView(BuildContext context) {
    return PinchZoomSelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasOfficeTab()) ...[
              _OfficeTab(
                celebrationKey: celebrationKey,
                vespersDefinition: vespersDefinition,
                vespersList: vespersList,
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
              vespersDefinition: vespersDefinition,
              vespersData: vespersData,
              calendar: calendar,
              date: date,
              shrinkWrap: true,
            ),
            const Divider(height: 1),
            HymnsTabWidget(
              hymns: vespersData.hymn ?? [],
              emptyMessage: liturgyLabels['no-hymn']!,
              shrinkWrap: true,
            ),
            if (vespersData.psalmody != null)
              for (var psalmEntry in vespersData.psalmody!)
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
            _ReadingTab(vespersData: vespersData, shrinkWrap: true),
            const Divider(height: 1),
            _CanticleTab(vespersData: vespersData, shrinkWrap: true),
            const Divider(height: 1),
            _IntercessionTab(vespersData: vespersData, shrinkWrap: true),
            const Divider(height: 1),
            _OrationTab(vespersData: vespersData, shrinkWrap: true),
          ],
        ),
      ),
    );
  }

  int _calculateTabCount() {
    // (Office), Introduction, Hymnes, Psalms..., Lecture, Magnificat, Intercession, Oraison
    return 6 + (vespersData.psalmody?.length ?? 0) + (_hasOfficeTab() ? 1 : 0);
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[];

    if (_hasOfficeTab()) {
      tabs.add(Tab(text: liturgyLabels['office'] ?? 'Office'));
    }

    tabs.add(Tab(text: liturgyLabels['introduction']));
    tabs.add(Tab(text: liturgyLabels['hymns']));

    if (vespersData.psalmody != null) {
      for (var psalmEntry in vespersData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final tabText = getPsalmDisplayTitle(
          psalmEntry.psalmData,
          psalmEntry.psalm!,
        );
        tabs.add(Tab(text: tabText));
      }
    }

    tabs.addAll([
      Tab(text: liturgyLabels['reading']),
      const Tab(text: 'Magnificat'),
      Tab(text: liturgyLabels['intercession']),
      Tab(text: liturgyLabels['oration']),
    ]);

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[];

    if (_hasOfficeTab()) {
      views.add(
        _OfficeTab(
          celebrationKey: celebrationKey,
          vespersDefinition: vespersDefinition,
          vespersList: vespersList,
          selectedCommon: selectedCommon,
          onCelebrationChanged: onCelebrationChanged,
          onCommonChanged: onCommonChanged,
          onPrecedenceOverridden: onPrecedenceOverridden,
          hasMultipleCelebrations: _hasMultipleCelebrations(),
          needsCommonSelection: _needsCommonSelection(),
        ),
      );
    }

    views.add(
      _IntroductionTab(
        vespersDefinition: vespersDefinition,
        vespersData: vespersData,
        calendar: calendar,
        date: date,
      ),
    );

    views.add(
      HymnsTabWidget(
        hymns: vespersData.hymn ?? [],
        emptyMessage: liturgyLabels['no-hymn']!,
      ),
    );

    if (vespersData.psalmody != null) {
      for (var psalmEntry in vespersData.psalmody!) {
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

    views.addAll([
      _ReadingTab(vespersData: vespersData),
      _CanticleTab(vespersData: vespersData),
      _IntercessionTab(vespersData: vespersData),
      _OrationTab(vespersData: vespersData),
    ]);

    return views;
  }
}

/// Office tab - displays celebration/common selectors and celebration description
class _OfficeTab extends StatelessWidget {
  const _OfficeTab({
    required this.celebrationKey,
    required this.vespersDefinition,
    required this.vespersList,
    required this.selectedCommon,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.hasMultipleCelebrations,
    required this.needsCommonSelection,
    this.shrinkWrap = false,
  });

  final String celebrationKey;
  final CelebrationContext vespersDefinition;
  final Map<String, CelebrationContext> vespersList;
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
            celebrationMap: vespersList,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
            onPrecedenceOverridden: onPrecedenceOverridden,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (hasMultipleCelebrations && needsCommonSelection)
          const Divider(height: 1),
        if (needsCommonSelection) ...[
          if ((vespersDefinition.commonList?.length ?? 0) > 1 ||
              (vespersDefinition.precedence ?? 13) > 8)
            OfficeSectionTitle(liturgyLabels['select-common']!),
          CommonChipsSelector(
            commonList: vespersDefinition.commonList ?? [],
            commonTitles: vespersDefinition.commonTitles,
            selectedCommon: selectedCommon,
            precedence: vespersDefinition.precedence ?? 13,
            onCommonChanged: onCommonChanged,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
      ],
    );
  }
}

/// Introduction tab - displays office header and introduction text
class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.vespersDefinition,
    required this.vespersData,
    required this.calendar,
    required this.date,
    this.shrinkWrap = false,
  });

  final CelebrationContext vespersDefinition;
  final Vespers vespersData;
  final Calendar calendar;
  final DateTime date;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final isLent = vespersDefinition.liturgicalTime == 'lent' ||
        vespersDefinition.liturgicalTime == 'holyweek';
    final introText = isLent
        ? (liturgyLabels['officeIntroductionLent'] ?? '')
        : (liturgyLabels['officeIntroduction'] ?? '');
    final additionalInfo =
        officeAdditionalInfo(vespersDefinition.liturgicalTime, calendar, date);

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        OfficeHeaderDisplay(
          officeDescription: vespersDefinition.officeDescription,
          liturgicalColor: vespersDefinition.liturgicalColor,
          typeLabel: vespersDefinition.celebrationDisplayLabel,
          celebrationDescription: vespersDefinition.celebrationDescription,
          additionalInfo: additionalInfo,
        ),

        // Introduction text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiturgyPartTitle(liturgyLabels['introduction'] ?? 'introduction'),
              YamlTextFromString(introText),
              SizedBox(height: 12.0 * zoom / 100),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadingTab extends StatelessWidget {
  const _ReadingTab({required this.vespersData, this.shrinkWrap = false});
  final Vespers vespersData;
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
          reference: vespersData.reading?.biblicalReference,
          content: vespersData.reading?.content,
        ),
        SizedBox(height: 24.0 * zoom / 100),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
        YamlTextFromString(
          vespersData.responsory ?? liturgyLabels['no-responsory']!,
        ),
        SizedBox(height: 12.0 * zoom / 100),
      ],
    );
  }
}

class _CanticleTab extends StatelessWidget {
  const _CanticleTab({required this.vespersData, this.shrinkWrap = false});
  final Vespers vespersData;
  final bool shrinkWrap;
  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(vertical: 16.0 * zoom / 100, horizontal: 0),
      children: [
        CanticleWidget(
          antiphons: vespersData.evangelicAntiphon ?? {},
          psalm: vespersData.evangelicCanticle!,
        ),
      ],
    );
  }
}

class _IntercessionTab extends StatelessWidget {
  const _IntercessionTab({required this.vespersData, this.shrinkWrap = false});
  final Vespers vespersData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.all(16.0 * zoom / 100),
      children: [
        LiturgyPartTitle(liturgyLabels['intercession'] ?? 'Intercession'),
        if (vespersData.intercession?.content != null)
          YamlTextFromString(
            vespersData.intercession!.content!,
            textAlign: TextAlign.justify,
          )
        else
          Text(liturgyLabels['no-intercession']!),
        SizedBox(height: 24.0 * zoom / 100),
        ExpansionTile(
          title: LiturgyPartTitle(liturgyLabels['our_father']),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          collapsedTextColor: Theme.of(context).textTheme.headlineSmall?.color,
          textColor: Theme.of(context).textTheme.headlineSmall?.color,
          collapsedIconColor: Theme.of(context).iconTheme.color,
          iconColor: Theme.of(context).iconTheme.color,
          children: [
            HymnContentDisplay(content: notrePere.content),
          ],
        ),
      ],
    );
  }
}

class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.vespersData, this.shrinkWrap = false});
  final Vespers vespersData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.all(16.0 * zoom / 100),
      children: [
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        ...buildOrationWidgets(vespersData.oration, zoom: zoom),
        SizedBox(height: 24.0 * zoom / 100),
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'Bénédiction'),
        YamlTextFromString(
          liturgyLabels['officeBenediction'] ?? 'officeBenediction',
        ),
      ],
    );
  }
}
