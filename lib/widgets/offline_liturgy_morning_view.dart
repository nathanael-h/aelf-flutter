import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/usual_texts.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/base_office_view_state.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_header_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_widget.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_sliver_delegate.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:aelf_flutter/states/liturgyState.dart';

/// Main entry point for the Morning Prayer (Lauds) view.
class MorningView extends StatefulWidget {
  const MorningView(
      {super.key,
      required this.morningList,
      required this.date,
      required this.calendar});

  final Map<String, CelebrationContext> morningList;
  final DateTime date;
  final Calendar calendar;

  @override
  State<MorningView> createState() => _MorningViewState();
}

class _MorningViewState extends BaseOfficeViewState<MorningView, Morning> {
  @override
  Map<String, CelebrationContext> get celebrationList => widget.morningList;

  @override
  DateTime get date => widget.date;

  @override
  Calendar get calendar => widget.calendar;

  @override
  String get debugOfficeName => 'Morning';

  @override
  bool hasInputChanged(MorningView oldWidget) =>
      oldWidget.date != widget.date ||
      oldWidget.morningList != widget.morningList;

  @override
  Future<Morning> exportOffice(CelebrationContext ctx) => morningExport(ctx);

  @override
  Widget buildOfficeDisplay(
    BuildContext context, {
    required String celebrationKey,
    required CelebrationContext definition,
    required Morning officeData,
    required String? selectedCommon,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
    required void Function(String, int?) onPrecedenceOverridden,
  }) {
    return MorningOfficeDisplay(
      celebrationKey: celebrationKey,
      morningDefinition: definition,
      morningData: officeData,
      selectedCommon: selectedCommon,
      morningList: widget.morningList,
      onCelebrationChanged: onCelebrationChanged,
      onCommonChanged: onCommonChanged,
      onPrecedenceOverridden: onPrecedenceOverridden,
      calendar: widget.calendar,
      date: widget.date,
    );
  }
}

/// Handles the TabBar navigation and layout of the Morning Office.
class MorningOfficeDisplay extends StatefulWidget {
  const MorningOfficeDisplay({
    super.key,
    required this.celebrationKey,
    required this.morningDefinition,
    required this.morningData,
    required this.selectedCommon,
    required this.morningList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.calendar,
    required this.date,
  });

  final String celebrationKey;
  final CelebrationContext morningDefinition;
  final Morning morningData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> morningList;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;
  final void Function(String key, int? precedence) onPrecedenceOverridden;
  final Calendar calendar;
  final DateTime date;

  @override
  State<MorningOfficeDisplay> createState() => _MorningOfficeDisplayState();
}

class _MorningOfficeDisplayState extends State<MorningOfficeDisplay> {
  int _selectedInvitatoryPsalmIndex = 0;

  @override
  void didUpdateWidget(MorningOfficeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKeys = oldWidget.morningData.invitatory?.psalms ?? const [];
    final newKeys = widget.morningData.invitatory?.psalms ?? const [];
    if (!listEquals(oldKeys, newKeys)) _selectedInvitatoryPsalmIndex = 0;
  }

  bool _hasMultipleCelebrations() =>
      widget.morningList.values.where((d) => d.isCelebrable).length > 1;

  bool _needsCommonSelection() {
    final d = widget.morningDefinition;
    if (d.commonList == null || d.commonList!.isEmpty) return false;
    if (['paschaloctave', 'christmasoctave'].contains(d.liturgicalTime)) {
      return false;
    }
    return d.celebrationCode != d.ferialCode;
  }

  bool _hasOfficeTab() {
    if (_hasMultipleCelebrations()) return true;
    if (!_needsCommonSelection()) return false;
    final d = widget.morningDefinition;
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
    final zoom = context.watch<CurrentZoom>().value;
    final morningData = widget.morningData;
    final morningDefinition = widget.morningDefinition;

    final invitatory = morningData.invitatory;
    final psalmsList =
        (invitatory?.psalms ?? []).map((e) => e.toString()).toList();
    final antiphons =
        (invitatory?.antiphon ?? []).map((e) => e.toString()).toList();
    final additionalInfo = officeAdditionalInfo(
        morningDefinition.liturgicalTime, widget.calendar, widget.date);
    final psalmsData = invitatory?.psalmsData;
    final selectedPsalm = (psalmsData != null &&
            _selectedInvitatoryPsalmIndex < psalmsData.length)
        ? psalmsData[_selectedInvitatoryPsalmIndex]
        : null;
    final psalmsSvgData = invitatory?.psalmsSvgData;
    final selectedSvgData = (psalmsSvgData != null &&
            _selectedInvitatoryPsalmIndex < psalmsSvgData.length)
        ? psalmsSvgData[_selectedInvitatoryPsalmIndex]
        : null;
    final hasSvg = selectedSvgData != null && selectedSvgData.isNotEmpty;

    return PinchZoomSelectionArea(
      child: CustomScrollView(
        slivers: [
          if (_hasOfficeTab()) ...[
            SliverToBoxAdapter(
              child: _OfficeTab(
                celebrationKey: widget.celebrationKey,
                morningDefinition: morningDefinition,
                morningList: widget.morningList,
                selectedCommon: widget.selectedCommon,
                onCelebrationChanged: widget.onCelebrationChanged,
                onCommonChanged: widget.onCommonChanged,
                onPrecedenceOverridden: widget.onPrecedenceOverridden,
                hasMultipleCelebrations: _hasMultipleCelebrations(),
                needsCommonSelection: _needsCommonSelection(),
                shrinkWrap: true,
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
          ],

          // Introduction: static header (office info + intro text + antiphon + chips)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OfficeHeaderDisplay(
                  officeDescription: morningDefinition.officeDescription,
                  liturgicalColor: morningDefinition.liturgicalColor,
                  typeLabel: morningDefinition.celebrationDisplayLabel,
                  celebrationDescription:
                      morningDefinition.celebrationDescription,
                  additionalInfo: additionalInfo,
                ),
                if (invitatory == null)
                  Center(child: Text(liturgyLabels['no-invitatory']!))
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LiturgyPartTitle(liturgyLabels['introduction']),
                        YamlTextFromString(
                          liturgyLabels['invitatoryIntroduction'] ??
                              'officeIntroduction',
                        ),
                        SizedBox(height: 12.0 * zoom / 100),
                        LiturgyPartTitle(
                            liturgyLabels['invitatory'] ?? 'Invitatory'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.0 * zoom / 100),
                  if (antiphons.isNotEmpty) ...[
                    AntiphonWidget(
                      antiphon1: antiphons[0],
                      antiphon2: antiphons.length > 1 ? antiphons[1] : null,
                      antiphon3: antiphons.length > 2 ? antiphons[2] : null,
                    ),
                    SizedBox(height: 16.0 * zoom / 100),
                  ],
                  if (psalmsList.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: psalmsList.asMap().entries.map((entry) {
                          final psalmIndex = entry.key;
                          final psalmKey = entry.value;
                          final psalm = (psalmsData != null &&
                                  psalmIndex < psalmsData.length)
                              ? psalmsData[psalmIndex]
                              : null;
                          return ChoiceChip(
                            label:
                                Text(getPsalmDisplayTitle(psalm, psalmKey)),
                            labelStyle:
                                TextStyle(fontSize: 12.0 * zoom / 100),
                            selected: _selectedInvitatoryPsalmIndex ==
                                psalmIndex,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() =>
                                    _selectedInvitatoryPsalmIndex =
                                        psalmIndex);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20.0 * zoom / 100),
                  ],
                ],
              ],
            ),
          ),

          // Invitatory psalm body (with or without sticky SVG)
          if (invitatory != null &&
              psalmsList.isNotEmpty &&
              selectedPsalm != null) ...[
            if (hasSvg)
              SliverStickyHeader(
                header: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: PsalmToneWidget(svgData: selectedSvgData),
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildInvitatoryPsalmBody(
                      selectedPsalm, antiphons, zoom),
                ),
              )
            else
              SliverToBoxAdapter(
                child:
                    _buildInvitatoryPsalmBody(selectedPsalm, antiphons, zoom),
              ),
          ],

          const SliverToBoxAdapter(child: Divider(height: 1)),
          SliverToBoxAdapter(
            child: HymnsTabWidget(
              hymns: morningData.hymn ?? [],
              emptyMessage: liturgyLabels['no-hymn']!,
              shrinkWrap: true,
            ),
          ),
          if (morningData.psalmody != null)
            for (final psalmEntry in morningData.psalmody!)
              if (psalmEntry.psalm != null) ...[
                const SliverToBoxAdapter(child: Divider(height: 1)),
                if (psalmEntry.svgData == null || psalmEntry.svgData!.isEmpty)
                  SliverToBoxAdapter(
                    child: PsalmTabWidget(
                      psalm: psalmEntry.psalmData,
                      antiphon1: (psalmEntry.antiphon?.isNotEmpty ?? false)
                          ? psalmEntry.antiphon![0]
                          : null,
                      antiphon2: (psalmEntry.antiphon?.length ?? 0) > 1
                          ? psalmEntry.antiphon![1]
                          : null,
                      shrinkWrap: true,
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 16.0 * zoom / 100),
                      child: PsalmDisplayHeader(
                        psalm: psalmEntry.psalmData,
                        antiphon1: (psalmEntry.antiphon?.isNotEmpty ?? false)
                            ? psalmEntry.antiphon![0]
                            : null,
                        antiphon2: (psalmEntry.antiphon?.length ?? 0) > 1
                            ? psalmEntry.antiphon![1]
                            : null,
                      ),
                    ),
                  ),
                  SliverStickyHeader(
                    header: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: PsalmToneWidget(svgData: psalmEntry.svgData!),
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 16.0 * zoom / 100),
                        child: PsalmDisplayBody(
                          psalm: psalmEntry.psalmData,
                          antiphon1: (psalmEntry.antiphon?.isNotEmpty ?? false)
                              ? psalmEntry.antiphon![0]
                              : null,
                          antiphon2: (psalmEntry.antiphon?.length ?? 0) > 1
                              ? psalmEntry.antiphon![1]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
          const SliverToBoxAdapter(child: Divider(height: 1)),
          SliverToBoxAdapter(
              child: _ReadingTab(morningData: morningData, shrinkWrap: true)),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          if (morningData.canticleSvgData == null ||
              morningData.canticleSvgData!.isEmpty ||
              morningData.evangelicCanticle == null)
            SliverToBoxAdapter(
                child:
                    _CanticleTab(morningData: morningData, shrinkWrap: true))
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 16.0 * zoom / 100),
                child: CanticleHeader(
                  psalm: morningData.evangelicCanticle!,
                  antiphons: morningData.evangelicAntiphon ?? {},
                ),
              ),
            ),
            SliverStickyHeader(
              header: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: PsalmToneWidget(svgData: morningData.canticleSvgData!),
              ),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16.0 * zoom / 100),
                  child: CanticleBody(
                    psalm: morningData.evangelicCanticle!,
                    antiphons: morningData.evangelicAntiphon ?? {},
                  ),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: Divider(height: 1)),
          SliverToBoxAdapter(
              child:
                  _IntercessionTab(morningData: morningData, shrinkWrap: true)),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          SliverToBoxAdapter(
              child: _OrationTab(morningData: morningData, shrinkWrap: true)),
        ],
      ),
    );
  }

  Widget _buildInvitatoryPsalmBody(
      Psalm psalm, List<String> antiphons, double zoom) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0 * zoom / 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PsalmFromMarkdown(content: psalm.content),
          if (antiphons.isNotEmpty) ...[
            SizedBox(height: 12.0 * zoom / 100),
            AntiphonWidget(
              antiphon1: antiphons[0],
              antiphon2: antiphons.length > 1 ? antiphons[1] : null,
              antiphon3: antiphons.length > 2 ? antiphons[2] : null,
            ),
          ],
        ],
      ),
    );
  }

  int _calculateTabCount() {
    final psalmTabs =
        widget.morningData.psalmody?.where((p) => p.psalm != null).length ?? 0;
    return 6 + psalmTabs + (_hasOfficeTab() ? 1 : 0);
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[];
    if (_hasOfficeTab()) {
      tabs.add(Tab(text: liturgyLabels['office'] ?? 'Office'));
    }
    tabs.add(Tab(text: liturgyLabels['introduction']));
    tabs.add(Tab(text: liturgyLabels['hymns']));
    if (widget.morningData.psalmody != null) {
      for (var psalmEntry in widget.morningData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final tabText = getPsalmDisplayTitle(
          psalmEntry.psalmData,
          psalmEntry.psalm!,
        );
        tabs.add(Tab(text: tabText));
      }
    }
    tabs.addAll([
      Tab(text: liturgyLabels['capitule']),
      const Tab(text: 'Benedictus'),
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
          celebrationKey: widget.celebrationKey,
          morningDefinition: widget.morningDefinition,
          morningList: widget.morningList,
          selectedCommon: widget.selectedCommon,
          onCelebrationChanged: widget.onCelebrationChanged,
          onCommonChanged: widget.onCommonChanged,
          onPrecedenceOverridden: widget.onPrecedenceOverridden,
          hasMultipleCelebrations: _hasMultipleCelebrations(),
          needsCommonSelection: _needsCommonSelection(),
        ),
      );
    }
    views.add(
      _IntroductionTab(
        morningDefinition: widget.morningDefinition,
        morningData: widget.morningData,
        calendar: widget.calendar,
        date: widget.date,
      ),
    );
    views.add(
      HymnsTabWidget(
        hymns: widget.morningData.hymn ?? [],
        emptyMessage: liturgyLabels['no-hymn']!,
      ),
    );
    if (widget.morningData.psalmody != null) {
      for (var psalmEntry in widget.morningData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final antiphons = psalmEntry.antiphon ?? [];
        views.add(
          PsalmTabWidget(
            psalm: psalmEntry.psalmData,
            antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
            antiphon2: antiphons.length > 1 ? antiphons[1] : null,
            svgData: psalmEntry.svgData,
          ),
        );
      }
    }
    views.addAll([
      _ReadingTab(morningData: widget.morningData),
      _CanticleTab(morningData: widget.morningData),
      _IntercessionTab(morningData: widget.morningData),
      _OrationTab(morningData: widget.morningData),
    ]);
    return views;
  }
}

// --- SUB-TABS CLASSES ---

class _OfficeTab extends StatelessWidget {
  const _OfficeTab({
    required this.celebrationKey,
    required this.morningDefinition,
    required this.morningList,
    required this.selectedCommon,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.onPrecedenceOverridden,
    required this.hasMultipleCelebrations,
    required this.needsCommonSelection,
    this.shrinkWrap = false,
  });

  final String celebrationKey;
  final CelebrationContext morningDefinition;
  final Map<String, CelebrationContext> morningList;
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
            celebrationMap: morningList,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
            onPrecedenceOverridden: onPrecedenceOverridden,
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (hasMultipleCelebrations && needsCommonSelection)
          const Divider(height: 1),
        if (needsCommonSelection) ...[
          if ((morningDefinition.commonList?.length ?? 0) > 1 ||
              (morningDefinition.precedence ?? 13) > 8)
            OfficeSectionTitle(liturgyLabels['select-common']!),
          CommonChipsSelector(
            commonList: morningDefinition.commonList ?? [],
            commonTitles: morningDefinition.commonTitles,
            selectedCommon: selectedCommon,
            precedence: morningDefinition.precedence ?? 13,
            onCommonChanged: onCommonChanged,
            forceCommon:
                morningDefinition.celebrationCode == 'roman/virgin-mary-memory',
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
      ],
    );
  }
}

class _IntroductionTab extends StatefulWidget {
  const _IntroductionTab({
    required this.morningDefinition,
    required this.morningData,
    required this.calendar,
    required this.date,
  });

  final CelebrationContext morningDefinition;
  final Morning morningData;
  final Calendar calendar;
  final DateTime date;

  @override
  State<_IntroductionTab> createState() => _IntroductionTabState();
}

class _IntroductionTabState extends State<_IntroductionTab> {
  // Selection is tracked by index, not key: invitatory psalm keys are not
  // guaranteed unique, and indexing data by value (indexOf) would resolve
  // duplicates to the wrong entry.
  int _selectedPsalmIndex = 0;

  @override
  void didUpdateWidget(_IntroductionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The State is reused across date changes; reset the selection when the
    // invitatory psalm set changes so it can't point past the new list.
    final oldKeys = (oldWidget.morningData.invitatory?.psalms ?? [])
        .map((e) => e.toString());
    final newKeys =
        (widget.morningData.invitatory?.psalms ?? []).map((e) => e.toString());
    if (!listEquals(oldKeys.toList(), newKeys.toList())) {
      _selectedPsalmIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitatory = widget.morningData.invitatory;
    if (invitatory == null) {
      return Center(child: Text(liturgyLabels['no-invitatory']!));
    }

    final List<String> psalmsList =
        (invitatory.psalms ?? []).map((e) => e.toString()).toList();
    final List<String> antiphons =
        (invitatory.antiphon ?? []).map((e) => e.toString()).toList();

    final additionalInfo = officeAdditionalInfo(
        widget.morningDefinition.liturgicalTime, widget.calendar, widget.date);
    final zoom = context.watch<CurrentZoom>().value;

    final psalmsData = invitatory.psalmsData;
    final psalm = (psalmsData != null &&
            _selectedPsalmIndex >= 0 &&
            _selectedPsalmIndex < psalmsData.length)
        ? psalmsData[_selectedPsalmIndex]
        : null;

    final psalmsSvgData = invitatory.psalmsSvgData;
    final svgData = (psalmsSvgData != null &&
            _selectedPsalmIndex < psalmsSvgData.length)
        ? psalmsSvgData[_selectedPsalmIndex]
        : null;
    final hasSvg = svgData != null && svgData.isNotEmpty;

    final antiphonWidget = antiphons.isNotEmpty
        ? AntiphonWidget(
            antiphon1: antiphons[0],
            antiphon2: antiphons.length > 1 ? antiphons[1] : null,
            antiphon3: antiphons.length > 2 ? antiphons[2] : null,
          )
        : null;

    final headerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        OfficeHeaderDisplay(
          officeDescription: widget.morningDefinition.officeDescription,
          liturgicalColor: widget.morningDefinition.liturgicalColor,
          typeLabel: widget.morningDefinition.celebrationDisplayLabel,
          celebrationDescription:
              widget.morningDefinition.celebrationDescription,
          additionalInfo: additionalInfo,
        ),
        LiturgyPartTitle(
          liturgyLabels['introduction'],
          hideVerseIdPlaceholder: false,
        ),
        LiturgyRow(
          builder: (context, zoom) => YamlTextFromString(
            liturgyLabels['invitatoryIntroduction'] ?? 'officeIntroduction',
          ),
        ),
        SizedBox(height: 12.0 * zoom / 100),
        LiturgyPartTitle(
          liturgyLabels['invitatory'] ?? 'Invitatory',
          hideVerseIdPlaceholder: false,
        ),
        SizedBox(height: 16.0 * zoom / 100),
        if (antiphonWidget != null) ...[
          antiphonWidget,
          SizedBox(height: 16.0 * zoom / 100),
        ],
        if (psalmsList.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildPsalmChips(psalmsList, invitatory),
          ),
          SizedBox(height: 20.0 * zoom / 100),
        ],
      ],
    );

    if (hasSvg && psalm != null) {
      final themeNotifier = context.watch<ThemeNotifier>();
      final themeKey = '${themeNotifier.darkTheme}_${themeNotifier.serifFont}';
      final screenWidth = MediaQuery.of(context).size.width;
      final extent = psalmToneSliverExtent(svgData, screenWidth);
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: headerContent),
          SliverPersistentHeader(
            pinned: true,
            delegate: PsalmToneSliverDelegate(
              svgData: svgData,
              extent: extent,
              themeKey: themeKey,
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PsalmFromMarkdown(content: psalm.content),
                if (antiphonWidget != null) ...[
                  SizedBox(height: 12.0 * zoom / 100),
                  antiphonWidget,
                ],
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        headerContent,
        if (psalmsList.isNotEmpty) ...[
          if (psalm != null) ...[
            if (svgData != null && svgData.isNotEmpty)
              PsalmToneWidget(svgData: svgData),
            PsalmFromMarkdown(content: psalm.content),
            if (antiphonWidget != null) ...[
              SizedBox(height: 12.0 * zoom / 100),
              antiphonWidget,
            ],
          ] else
            Text(liturgyLabels['no-psalm']!),
        ],
      ],
    );
  }

  Widget _buildPsalmChips(List<String> psalmsList, Invitatory invitatory) {
    final zoom = context.watch<CurrentZoom>().value;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: psalmsList.asMap().entries.map((entry) {
        final psalmIndex = entry.key;
        final psalmKey = entry.value;
        final psalm = (invitatory.psalmsData != null &&
                psalmIndex < invitatory.psalmsData!.length)
            ? invitatory.psalmsData![psalmIndex]
            : null;
        return ChoiceChip(
          label: Text(getPsalmDisplayTitle(psalm, psalmKey)),
          labelStyle: TextStyle(fontSize: 12.0 * zoom / 100),
          selected: _selectedPsalmIndex == psalmIndex,
          onSelected: (selected) {
            if (selected) setState(() => _selectedPsalmIndex = psalmIndex);
          },
        );
      }).toList(),
    );
  }

}

class _ReadingTab extends StatelessWidget {
  const _ReadingTab({required this.morningData, this.shrinkWrap = false});
  final Morning morningData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        ScriptureWidget(
          title: liturgyLabels['word_of_god'] ?? 'Word of God',
          reference: morningData.reading?.biblicalReference,
          content: morningData.reading?.content,
        ),
        SizedBox(height: 24.0 * zoom / 100),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Responsory',
            hideVerseIdPlaceholder: false),
        LiturgyRow(
          builder: (context, zoom) => YamlTextFromString(
            morningData.responsory ?? liturgyLabels['no-responsory']!,
          ),
        ),
      ],
    );
  }
}

class _CanticleTab extends StatelessWidget {
  const _CanticleTab({required this.morningData, this.shrinkWrap = false});
  final Morning morningData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final canticle = morningData.evangelicCanticle;
    if (canticle == null) {
      return Center(child: Text(liturgyLabels['no-canticle']!));
    }

    final svgData = morningData.canticleSvgData;
    final hasSvg = svgData != null && svgData.isNotEmpty;

    if (hasSvg && !shrinkWrap) {
      final themeNotifier = context.watch<ThemeNotifier>();
      final themeKey = '${themeNotifier.darkTheme}_${themeNotifier.serifFont}';
      final screenWidth = MediaQuery.of(context).size.width;
      final extent = psalmToneSliverExtent(svgData, screenWidth);
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 16.0 * zoom / 100),
              child: CanticleHeader(
                psalm: canticle,
                antiphons: morningData.evangelicAntiphon ?? {},
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: PsalmToneSliverDelegate(
              svgData: svgData,
              extent: extent,
              themeKey: themeKey,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.0 * zoom / 100),
              child: CanticleBody(
                psalm: canticle,
                antiphons: morningData.evangelicAntiphon ?? {},
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        if (hasSvg) PsalmToneWidget(svgData: svgData),
        CanticleWidget(
          antiphons: morningData.evangelicAntiphon ?? {},
          psalm: canticle,
        ),
      ],
    );
  }
}

class _IntercessionTab extends StatelessWidget {
  const _IntercessionTab({required this.morningData, this.shrinkWrap = false});
  final Morning morningData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        LiturgyPartTitle(liturgyLabels['intercession'] ?? 'Intercession',
            hideVerseIdPlaceholder: false),
        if (morningData.intercession?.content != null) ...[
          LiturgyRow(
            builder: (context, zoom) => YamlTextFromString(
              morningData.intercession!.content!,
              textAlign: TextAlign.justify,
            ),
          ),
          SizedBox(height: 24.0 * zoom / 100),
        ],
        ExpansionTile(
          title: LiturgyPartTitle(
              liturgyLabels['our_father'] ?? 'Lord\'s Prayer',
              hideVerseIdPlaceholder: false),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          collapsedTextColor: Theme.of(context).textTheme.headlineSmall?.color,
          textColor: Theme.of(context).textTheme.headlineSmall?.color,
          collapsedIconColor: Theme.of(context).iconTheme.color,
          iconColor: Theme.of(context).iconTheme.color,
          children: [
            LiturgyRow(
              builder: (context, zoom) =>
                  HymnContentDisplay(content: notrePere.content),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.morningData, this.shrinkWrap = false});
  final Morning morningData;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(vertical: 16.0 * zoom / 100),
      children: [
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Concluding Prayer',
            hideVerseIdPlaceholder: false),
        ...buildOrationWidgets(morningData.oration, zoom: zoom),
        SizedBox(height: 24.0 * zoom / 100),
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'Blessing',
            hideVerseIdPlaceholder: false),
        LiturgyRow(
          builder: (context, zoom) => YamlTextFromString(
            liturgyLabels['officeBenediction'] ?? 'officeBenediction',
          ),
        ),
      ],
    );
  }
}
