import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/usual_texts.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_header_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_section_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:aelf_flutter/utils/settings.dart';

/// Main entry point for the Morning Prayer (Lauds) view.
class MorningView extends StatefulWidget {
  const MorningView({
    super.key,
    required this.morningList,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, CelebrationContext> morningList;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  State<MorningView> createState() => _MorningViewState();
}

class _MorningViewState extends State<MorningView> {
  bool _isLoading = true;
  String? _celebrationKey;
  CelebrationContext? _selectedDefinition;
  Morning? _morningData;
  String? _selectedCommon;
  String? _errorMessage;
  bool _imprecatoryVerses = false;

  @override
  void initState() {
    super.initState();
    _loadOffice();
  }

  @override
  void didUpdateWidget(MorningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.morningList != widget.morningList) {
      _loadOffice();
    }
  }

  /// Loads office data based on user settings and liturgical date.
  Future<void> _loadOffice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firstOption = widget.morningList.entries
          .where((entry) => entry.value.isCelebrable)
          .firstOrNull;

      if (firstOption == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = liturgyLabels['no-office']!;
        });
        return;
      }

      _celebrationKey = firstOption.key;
      _selectedDefinition = firstOption.value;
      _imprecatoryVerses = await getImprecatoryVerses();

      String? autoCommon;
      final commonList = _selectedDefinition!.commonList;
      if (commonList != null && commonList.isNotEmpty) {
        if (_selectedDefinition!.celebrationCode !=
            _selectedDefinition!.ferialCode) {
          autoCommon = commonList.first;
        }
      }
      _selectedCommon = autoCommon;

      final celebrationContext = _selectedDefinition!.copyWith(
        commonList: autoCommon != null ? [autoCommon] : [],
        showImprecatoryVerses: _imprecatoryVerses,
      );
      final morningData = await morningExport(celebrationContext);

      if (mounted) {
        setState(() {
          _morningData = morningData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels['error-office']!}: $e';
        });
      }
    }
  }

  Future<void> _onCelebrationChanged(String key) async {
    final definition = widget.morningList[key];
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
        commonList: autoCommon != null ? [autoCommon] : [],
        showImprecatoryVerses: _imprecatoryVerses,
      );
      final morningData = await morningExport(celebrationContext);

      if (mounted) {
        setState(() {
          _celebrationKey = key;
          _selectedDefinition = definition;
          _selectedCommon = autoCommon;
          _morningData = morningData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels['error']!}: $e';
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
      final morningData = await morningExport(celebrationContext);

      if (mounted) {
        setState(() {
          _selectedCommon = common;
          _morningData = morningData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels['error']!}: $e';
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
                onPressed: _loadOffice, child: Text(liturgyLabels['retry']!)),
          ],
        ),
      );
    }
    if (_celebrationKey != null &&
        _selectedDefinition != null &&
        _morningData != null) {
      return MorningOfficeDisplay(
        celebrationKey: _celebrationKey!,
        morningDefinition: _selectedDefinition!,
        morningData: _morningData!,
        selectedCommon: _selectedCommon,
        morningList: widget.morningList,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
      );
    }
    return Center(child: Text(liturgyLabels['no-data']!));
  }
}

/// Handles the TabBar navigation and layout of the Morning Office.
class MorningOfficeDisplay extends StatelessWidget {
  const MorningOfficeDisplay({
    super.key,
    required this.celebrationKey,
    required this.morningDefinition,
    required this.morningData,
    required this.selectedCommon,
    required this.morningList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final CelebrationContext morningDefinition;
  final Morning morningData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> morningList;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

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
    return 5 + (morningData.psalmody?.length ?? 0);
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
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
    );
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[
      Tab(text: liturgyLabels['introduction']),
      Tab(text: liturgyLabels['hymns']),
    ];
    if (morningData.psalmody != null) {
      for (var psalmEntry in morningData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final tabText =
            getPsalmDisplayTitle(psalmEntry.psalmData, psalmEntry.psalm!);
        tabs.add(Tab(text: tabText));
      }
    }
    tabs.addAll([
      Tab(text: liturgyLabels['capitule']),
      const Tab(text: 'Benedictus'),
      Tab(text: liturgyLabels['conclusion']),
    ]);
    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[
      _IntroductionTab(
        celebrationKey: celebrationKey,
        morningDefinition: morningDefinition,
        morningData: morningData,
        selectedCommon: selectedCommon,
        morningList: morningList,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
      ),
      HymnsTabWidget(
        hymns: morningData.hymn ?? [],
        emptyMessage: liturgyLabels['no-hymn']!,
      ),
    ];
    if (morningData.psalmody != null) {
      for (var psalmEntry in morningData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final antiphons = psalmEntry.antiphon ?? [];
        views.add(PsalmTabWidget(
          psalm: psalmEntry.psalmData,
          antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
          antiphon2: antiphons.length > 1 ? antiphons[1] : null,
        ));
      }
    }
    views.addAll([
      _ReadingTab(morningData: morningData),
      _CanticleTab(morningData: morningData),
      _OrationTab(morningData: morningData),
    ]);
    return views;
  }
}

// --- SUB-TABS CLASSES ---

class _IntroductionTab extends StatefulWidget {
  const _IntroductionTab({
    required this.celebrationKey,
    required this.morningDefinition,
    required this.morningData,
    required this.selectedCommon,
    required this.morningList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final CelebrationContext morningDefinition;
  final Morning morningData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> morningList;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  @override
  State<_IntroductionTab> createState() => _IntroductionTabState();
}

class _IntroductionTabState extends State<_IntroductionTab> {
  String? selectedPsalmKey;

  @override
  void initState() {
    super.initState();
    final invitatory = widget.morningData.invitatory;
    if (invitatory?.psalms != null && invitatory!.psalms!.isNotEmpty) {
      selectedPsalmKey = invitatory.psalms!.first.toString();
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

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        OfficeHeaderDisplay(
          officeDescription: widget.morningDefinition.officeDescription,
          liturgicalColor: widget.morningDefinition.liturgicalColor,
          precedence: widget.morningDefinition.precedence,
          celebrationDescription:
              widget.morningDefinition.celebrationDescription,
        ),
        if (_hasMultipleCelebrations()) ...[
          OfficeSectionTitle(liturgyLabels['select-office']!),
          CelebrationChipsSelector(
            celebrationMap: widget.morningList,
            selectedKey: widget.celebrationKey,
            onCelebrationChanged: widget.onCelebrationChanged,
          ),
          const SizedBox(height: 12.0),
        ],
        if (_needsCommonSelection()) ...[
          OfficeSectionTitle(liturgyLabels['select-common']!),
          CommonChipsSelector(
            commonList: widget.morningDefinition.commonList ?? [],
            commonTitles: widget.morningDefinition.commonTitles,
            selectedCommon: widget.selectedCommon,
            precedence: widget.morningDefinition.precedence ?? 13,
            onCommonChanged: widget.onCommonChanged,
          ),
          const SizedBox(height: 12.0),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiturgyPartTitle(liturgyLabels['introduction'] ?? 'Introduction'),
              YamlTextFromString(
                  fixedTexts['officeIntroduction'] ?? 'officeIntroduction'),
              const SizedBox(height: 12.0),
              LiturgyPartTitle(liturgyLabels['invitatory'] ?? 'Invitatory'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (antiphons.isNotEmpty) ...[
          AntiphonWidget(
            antiphon1: antiphons[0],
            antiphon2: antiphons.length > 1 ? antiphons[1] : null,
            antiphon3: antiphons.length > 2 ? antiphons[2] : null,
          ),
          const SizedBox(height: 16),
        ],
        if (psalmsList.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildPsalmChips(psalmsList, invitatory),
          ),
          const SizedBox(height: 20),
        ],
        if (selectedPsalmKey != null) _buildPsalm(selectedPsalmKey!, antiphons),
      ],
    );
  }

  Widget _buildPsalmChips(List<String> psalmsList, Invitatory invitatory) {
    final zoom = context.watch<CurrentZoom>().value;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: psalmsList.map((String psalmKey) {
        final psalmIndex = psalmsList.indexOf(psalmKey);
        final psalm = (invitatory.psalmsData != null &&
                psalmIndex < invitatory.psalmsData!.length)
            ? invitatory.psalmsData![psalmIndex]
            : null;
        return ChoiceChip(
          label: Text(getPsalmDisplayTitle(psalm, psalmKey)),
          labelStyle: TextStyle(fontSize: 12.0 * zoom / 100),
          selected: selectedPsalmKey == psalmKey,
          onSelected: (selected) {
            if (selected) setState(() => selectedPsalmKey = psalmKey);
          },
        );
      }).toList(),
    );
  }

  Widget _buildPsalm(String psalmKey, List<String> antiphons) {
    final invitatory = widget.morningData.invitatory;
    final psalmsList =
        (invitatory?.psalms ?? []).map((e) => e.toString()).toList();
    final psalmIndex = psalmsList.indexOf(psalmKey);
    final psalm = (invitatory?.psalmsData != null &&
            psalmIndex >= 0 &&
            psalmIndex < invitatory!.psalmsData!.length)
        ? invitatory.psalmsData![psalmIndex]
        : null;

    if (psalm == null) return Text(liturgyLabels['no-psalm']!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PsalmFromMarkdown(content: psalm.content),
        if (antiphons.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          AntiphonWidget(
            antiphon1: antiphons[0],
            antiphon2: antiphons.length > 1 ? antiphons[1] : null,
            antiphon3: antiphons.length > 2 ? antiphons[2] : null,
          ),
        ],
      ],
    );
  }

  bool _hasMultipleCelebrations() =>
      widget.morningList.values.where((d) => d.isCelebrable).length > 1;

  bool _needsCommonSelection() {
    final d = widget.morningDefinition;
    if (d.commonList == null || d.commonList!.isEmpty) return false;
    if (['paschaloctave', 'christmasoctave'].contains(d.liturgicalTime))
      return false;
    return d.celebrationCode != d.ferialCode;
  }
}

class _ReadingTab extends StatelessWidget {
  const _ReadingTab({required this.morningData});
  final Morning morningData;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScriptureWidget(
          title: liturgyLabels['word_of_god'] ?? 'Word of God',
          reference: morningData.reading?.biblicalReference,
          content: morningData.reading?.content,
        ),
        const SizedBox(height: 24.0),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Responsory'),
        YamlTextFromString(
            morningData.responsory ?? liturgyLabels['no-responsory']!),
      ],
    );
  }
}

class _CanticleTab extends StatelessWidget {
  const _CanticleTab({required this.morningData});
  final Morning morningData;

  @override
  Widget build(BuildContext context) {
    final canticle = morningData.evangelicCanticle;
    if (canticle == null) {
      return Center(child: Text(liturgyLabels['no-canticle']!));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        CanticleWidget(
          antiphons: morningData.evangelicAntiphon ?? {},
          psalm: canticle,
        ),
      ],
    );
  }
}

class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.morningData});
  final Morning morningData;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['intercession'] ?? 'Intercession'),
        if (morningData.intercession?.content != null) ...[
          YamlTextFromString(morningData.intercession!.content!,
              textAlign: TextAlign.justify),
          const SizedBox(height: 24.0),
        ],
        LiturgyPartTitle(liturgyLabels['our_father'] ?? 'Lord\'s Prayer'),
        HymnContentDisplay(content: notrePere.content),
        const SizedBox(height: 24.0),
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Concluding Prayer'),
        YamlTextFromString(
            morningData.oration?.join("\n") ?? liturgyLabels['no-oration']!,
            textAlign: TextAlign.justify),
        const SizedBox(height: 24.0),
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'Blessing'),
        YamlTextFromString(
            fixedTexts['officeBenediction'] ?? 'officeBenediction'),
      ],
    );
  }
}
