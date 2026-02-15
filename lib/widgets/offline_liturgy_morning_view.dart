import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/usual_texts.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

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
          _errorMessage = 'No celebrable office available';
        });
        return;
      }

      _celebrationKey = firstOption.key;
      _selectedDefinition = firstOption.value;

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
          _errorMessage = 'Error loading office: $e';
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
          _errorMessage = 'Error: $e';
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
          _errorMessage = 'Error: $e';
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
            ElevatedButton(onPressed: _loadOffice, child: const Text('Retry')),
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
    return const Center(child: Text('No data available'));
  }
}

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
            child: TabBarView(children: _buildTabViews()),
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
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: _buildTabs(),
      ),
    );
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[
      const Tab(text: 'Introduction'),
      const Tab(text: 'Hymnes'),
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
      const Tab(text: 'Lecture'),
      const Tab(text: 'Bénédictus'),
      const Tab(text: 'Conclusion'),
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
        emptyMessage: 'No hymn available',
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
      return const Center(child: Text('No invitatory available'));
    }

    final List<String> psalmsList =
        (invitatory.psalms ?? []).map((e) => e.toString()).toList();
    final List<String> antiphons =
        (invitatory.antiphon ?? []).map((e) => e.toString()).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // --- Header Section ---
        Text(
          widget.morningDefinition.officeDescription ?? '',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (widget.morningDefinition.liturgicalColor != null)
          Container(
            width: double.infinity,
            height: 6,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: getLiturgicalColor(
                  widget.morningDefinition.liturgicalColor),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        Text(
          getCelebrationTypeLabel(
              widget.morningDefinition.precedence ?? 13),
          style: const TextStyle(
              fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        if (widget.morningDefinition.celebrationDescription != null &&
            widget.morningDefinition.celebrationDescription!
                .isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.morningDefinition.celebrationDescription!,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.justify,
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // --- Selection Chips ---

        if (_hasMultipleCelebrations()) ...[
          _buildSectionTitle('Sélectionner l\'office'),
          CelebrationChipsSelector(
            celebrationMap: widget.morningList,
            selectedKey: widget.celebrationKey,
            onCelebrationChanged: widget.onCelebrationChanged,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        if (_needsCommonSelection()) ...[
          if ((widget.morningDefinition.commonList?.length ?? 0) > 1 ||
              (widget.morningDefinition.precedence ?? 13) > 8)
            _buildSectionTitle('Sélectionner un commun'),
          CommonChipsSelector(
            commonList: widget.morningDefinition.commonList ?? [],
            commonTitles: widget.morningDefinition.commonTitles,
            selectedCommon: widget.selectedCommon,
            precedence: widget.morningDefinition.precedence ?? 13,
            onCommonChanged: widget.onCommonChanged,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // --- Introduction Text ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiturgyPartTitle(liturgyLabels['introduction'] ?? 'Introduction'),
              LiturgyPartFormattedText(
                  fixedTexts['officeIntroduction'] ?? 'officeIntroduction',
                  includeVerseIdPlaceholder: false),
              SizedBox(height: spaceBetweenElements),
              SizedBox(height: spaceBetweenElements),
            ],
          ),
        ),

        // --- Invitatory ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LiturgyPartTitle(liturgyLabels['invitatory'] ?? 'Invitatoire'),
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

        // --- Psalm Selector (Chips) ---
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPsalmChips(List<String> psalmsList, Invitatory invitatory) {
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
        final displayText = getPsalmDisplayTitle(psalm, psalmKey);

        final chipMaxWidth = MediaQuery.of(context).size.width - 80;
        return ChoiceChip(
          label: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: chipMaxWidth),
            child: Text(
              displayText,
              softWrap: true,
              maxLines: 3,
              textAlign: TextAlign.center,
            ),
          ),
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

    if (psalm == null) return const Text('Psalm not found');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PsalmFromMarkdown(content: psalm.getContent),
        if (antiphons.isNotEmpty) ...[
          SizedBox(height: spaceBetweenElements),
          AntiphonWidget(
            antiphon1: antiphons[0],
            antiphon2: antiphons.length > 1 ? antiphons[1] : null,
            antiphon3: antiphons.length > 2 ? antiphons[2] : null,
          ),
        ],
      ],
    );
  }

  bool _hasMultipleCelebrations() {
    return widget.morningList.values.where((d) => d.isCelebrable).length > 1;
  }

  bool _needsCommonSelection() {
    final definition = widget.morningDefinition;
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
          title: liturgyLabels['word_of_god'] ?? 'Parole de Dieu',
          reference: morningData.reading?.biblicalReference,
          content: morningData.reading?.content,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
        LiturgyPartFormattedText(
            morningData.responsory ?? 'No responsory available',
            includeVerseIdPlaceholder: false),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}

class _CanticleTab extends StatelessWidget {
  const _CanticleTab({
    required this.morningData,
  });

  final Morning morningData;

  @override
  Widget build(BuildContext context) {
    final antiphon = morningData.evangelicAntiphon?.common;

    if (antiphon == null) {
      return const Center(child: Text('No antiphon available'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      children: [
        CanticleWidget(
          antiphon1: antiphon,
          psalm: benedictus,
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
        LiturgyPartTitle(liturgyLabels['intercession'] ?? 'intercession'),
        if (morningData.intercession?.content != null) ...[
          LiturgyPartFormattedText(
            morningData.intercession!.content!,
            textAlign: TextAlign.justify,
            includeVerseIdPlaceholder: false,
          ),
          SizedBox(height: spaceBetweenElements * 2),
        ],
        LiturgyPartTitle(liturgyLabels['our_father'] ?? 'our_father'),
        HymnContentDisplay(content: notrePere.content),
        SizedBox(height: spaceBetweenElements * 2),
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'oration'),
        LiturgyPartFormattedText(
          morningData.oration?.join("\n") ?? 'No oration available',
          textAlign: TextAlign.justify,
          includeVerseIdPlaceholder: false,
        ),
        SizedBox(height: spaceBetweenElements * 2),
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'blessing'),
        LiturgyPartFormattedText(
          fixedTexts['officeBenediction'] ?? 'officeBenediction',
          includeVerseIdPlaceholder: false,
        ),
      ],
    );
  }
}
