import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/usual_texts.dart';
import 'package:offline_liturgy/tools/date_tools.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/services/morning_office_service.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
// import 'package:yaml/yaml.dart'; // Plus nécessaire ici

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
  late final MorningOfficeService _service;
  bool _isLoading = true;
  ResolvedMorningOffice? _resolvedOffice;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = MorningOfficeService(dataLoader: widget.dataLoader);
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
      final firstOption = _service.getFirstCelebrableOption(widget.morningList);

      if (firstOption == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No celebrable office available';
        });
        return;
      }

      final autoCommon = _service.determineAutoCommon(firstOption.value);

      final resolved = await _service.resolveCompleteMorningOffice(
        celebrationKey: firstOption.key,
        celebration: firstOption.value,
        common: autoCommon,
        date: widget.date,
      );

      if (mounted) {
        setState(() {
          _resolvedOffice = resolved;
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
    final celebration = widget.morningList[key];
    if (celebration == null) return;

    setState(() => _isLoading = true);

    try {
      final autoCommon = _service.determineAutoCommon(celebration);

      final resolved = await _service.resolveCompleteMorningOffice(
        celebrationKey: key,
        celebration: celebration,
        common: autoCommon,
        date: widget.date,
      );

      if (mounted) {
        setState(() {
          _resolvedOffice = resolved;
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
    if (_resolvedOffice == null) return;
    setState(() => _isLoading = true);
    try {
      final resolved = await _service.resolveCompleteMorningOffice(
        celebrationKey: _resolvedOffice!.celebrationKey,
        celebration: _resolvedOffice!.celebration,
        common: common,
        date: widget.date,
      );
      if (mounted) {
        setState(() {
          _resolvedOffice = resolved;
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
    if (_resolvedOffice != null) {
      return MorningOfficeDisplay(
        resolvedOffice: _resolvedOffice!,
        morningList: widget.morningList,
        dataLoader: widget.dataLoader,
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
    required this.resolvedOffice,
    required this.morningList,
    required this.dataLoader,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final ResolvedMorningOffice resolvedOffice;
  final Map<String, CelebrationContext> morningList;
  final DataLoader dataLoader;
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
    return 5 + (resolvedOffice.morningData.psalmody?.length ?? 0);
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
    if (resolvedOffice.morningData.psalmody != null) {
      for (var psalmEntry in resolvedOffice.morningData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final tabText =
            getPsalmDisplayTitle(psalmEntry.psalmData, psalmEntry.psalm!);
        tabs.add(Tab(text: tabText));
      }
    }
    tabs.addAll([
      const Tab(text: 'Lecture'),
      const Tab(text: 'Cantique'),
      const Tab(text: 'Conclusion'),
    ]);
    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[
      _IntroductionTabSimple(
        resolvedOffice: resolvedOffice,
        morningList: morningList,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
      ),
      HymnsTabWidget(
        hymns: resolvedOffice.morningData.hymn ?? [],
        emptyMessage: 'No hymn available',
      ),
    ];
    if (resolvedOffice.morningData.psalmody != null) {
      for (var psalmEntry in resolvedOffice.morningData.psalmody!) {
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
      _ReadingTabSimple(morningData: resolvedOffice.morningData),
      _CanticleTabSimple(morningData: resolvedOffice.morningData),
      _OrationTabSimple(morningData: resolvedOffice.morningData),
    ]);
    return views;
  }
}

class _IntroductionTabSimple extends StatefulWidget {
  const _IntroductionTabSimple({
    required this.resolvedOffice,
    required this.morningList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final ResolvedMorningOffice resolvedOffice;
  final Map<String, CelebrationContext> morningList;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  @override
  State<_IntroductionTabSimple> createState() => _IntroductionTabSimpleState();
}

class _IntroductionTabSimpleState extends State<_IntroductionTabSimple> {
  String? selectedPsalmKey;

  @override
  void initState() {
    super.initState();
    final invitatory = widget.resolvedOffice.morningData.invitatory;
    if (invitatory?.psalms != null && invitatory!.psalms!.isNotEmpty) {
      selectedPsalmKey = invitatory.psalms!.first.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitatory = widget.resolvedOffice.morningData.invitatory;

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
          widget.resolvedOffice.celebration.officeDescription ?? '',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (widget.resolvedOffice.celebration.liturgicalColor != null)
          Container(
            width: double.infinity,
            height: 6,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: getLiturgicalColor(
                  widget.resolvedOffice.celebration.liturgicalColor),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        Text(
          getCelebrationTypeLabel(
              widget.resolvedOffice.celebration.precedence ?? 13),
          style: const TextStyle(
              fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        if (widget.resolvedOffice.celebration.celebrationDescription != null &&
            widget.resolvedOffice.celebration.celebrationDescription!
                .isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.resolvedOffice.celebration.celebrationDescription!,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.justify,
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // --- Selection Chips ---

        if (_hasMultipleCelebrations()) ...[
          _buildSectionTitle('Sélectionner l\'office'),
          _buildCelebrationChips(),
          SizedBox(height: spaceBetweenElements),
        ],

        if (_needsCommonSelection()) ...[
          _buildSectionTitle('Sélectionner un commun'),
          _buildCommonChips(),
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

  Widget _buildCelebrationChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: widget.morningList.entries
            .where((e) => e.value.isCelebrable)
            .map((entry) {
          final isSelected = entry.key == widget.resolvedOffice.celebrationKey;
          final color = getLiturgicalColor(entry.value.liturgicalColor);

          return ChoiceChip(
            label: Text(
              '${entry.value.officeDescription ?? ''} ${getCelebrationTypeLabel(entry.value.precedence ?? 13)}',
              softWrap: true,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            selected: isSelected,
            onSelected: (bool selected) {
              if (selected) widget.onCelebrationChanged(entry.key);
            },
            avatar: CircleAvatar(
              backgroundColor: color,
              radius: 6,
            ),
            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCommonChips() {
    final commons = widget.resolvedOffice.celebration.commonList ?? [];
    final bool showNoCommon =
        (widget.resolvedOffice.celebration.precedence ?? 13) > 6;
    final Map<String, String> titles = widget.resolvedOffice.commonTitles;

    // Utilisation de Wrap au lieu de SingleChildScrollView
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0, // Espace horizontal
        runSpacing: 8.0, // Espace vertical
        alignment: WrapAlignment.start,
        children: [
          if (showNoCommon)
            ChoiceChip(
              label: const Text('Pas de commun'),
              selected: widget.resolvedOffice.selectedCommon == null,
              onSelected: (selected) {
                if (selected) widget.onCommonChanged(null);
              },
            ),
          ...commons.map((commonKey) {
            return ChoiceChip(
              label: Text(
                titles[commonKey] ?? commonKey,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              selected: widget.resolvedOffice.selectedCommon == commonKey,
              onSelected: (selected) {
                if (selected) widget.onCommonChanged(commonKey);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPsalmChips(List<String> psalmsList, Invitatory invitatory) {
    // Utilisation de Wrap pour les psaumes invitatoires
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment:
          WrapAlignment.center, // Centré car souvent peu de choix (1 ou 2)
      children: psalmsList.map((String psalmKey) {
        final psalmIndex = psalmsList.indexOf(psalmKey);
        final psalm = (invitatory.psalmsData != null &&
                psalmIndex < invitatory.psalmsData!.length)
            ? invitatory.psalmsData![psalmIndex]
            : null;
        final displayText = getPsalmDisplayTitle(psalm, psalmKey);

        return ChoiceChip(
          label: Text(
            displayText,
            softWrap: true,
            maxLines: 2,
            textAlign: TextAlign.center,
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
    final invitatory = widget.resolvedOffice.morningData.invitatory;
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
    final celebration = widget.resolvedOffice.celebration;
    final commonList = celebration.commonList;
    final precedence = celebration.precedence;
    final liturgicalTime = celebration.liturgicalTime;

    if (commonList == null || commonList.isEmpty) return false;
    if (liturgicalTime == 'paschaloctave' ||
        liturgicalTime == 'christmasoctave') {
      return false;
    }
    if (celebration.celebrationCode == celebration.ferialCode) return false;

    return commonList.length >= 2 ||
        (commonList.length == 1 && (precedence ?? 13) > 6);
  }
}

// Les autres widgets (_ReadingTabSimple, etc.) restent inchangés
class _ReadingTabSimple extends StatelessWidget {
  const _ReadingTabSimple({required this.morningData});
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

class _CanticleTabSimple extends StatelessWidget {
  const _CanticleTabSimple({
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
      // MODIFICATION : Padding horizontal à 0
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

class _OrationTabSimple extends StatelessWidget {
  const _OrationTabSimple({required this.morningData});
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
