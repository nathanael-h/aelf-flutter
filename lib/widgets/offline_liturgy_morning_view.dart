import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/morning_class.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/tools/date_tools.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/services/morning_office_service.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Morning View
///
/// Architecture:
/// 1. MorningView (StatefulWidget) - Manages UI state only
/// 2. MorningOfficeService - Handles all data loading/resolution
/// 3. MorningOfficeDisplay (StatelessWidget) - Pure display widget
///
/// Flow:
/// morningList + date → Service → ResolvedMorningOffice → Display Widget
class MorningView extends StatefulWidget {
  const MorningView({
    super.key,
    required this.morningList,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, MorningDefinition> morningList;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  State<MorningView> createState() => _MorningViewState();
}

class _MorningViewState extends State<MorningView> {
  late final MorningOfficeService _service;

  // Simple state: either loading or resolved
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

  /// Single method to load everything - simple and clear
  Future<void> _loadOffice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Find first celebrable option
      final firstOption = _service.getFirstCelebrableOption(widget.morningList);

      if (firstOption == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No celebrable office available';
        });
        return;
      }

      // Step 2: Determine which common to use (if any)
      // Always auto-select first common if available
      final autoCommon = _service.determineAutoCommon(firstOption.value);

      // Step 3: Resolve complete office (one call does everything!)
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

  /// Handle user changing celebration
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

  /// Handle user changing common
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
    // Loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
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
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Success state - delegate to display widget
    if (_resolvedOffice != null) {
      return MorningOfficeDisplay(
        resolvedOffice: _resolvedOffice!,
        morningList: widget.morningList,
        dataLoader: widget.dataLoader,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
      );
    }

    // Fallback
    return const Center(child: Text('No data available'));
  }
}

/// Pure display widget - receives all data, no async logic
/// This makes it easy to test and reason about
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
  final Map<String, MorningDefinition> morningList;
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
            child: TabBarView(
              children: _buildTabViews(),
            ),
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

    // Add psalm tabs
    if (resolvedOffice.morningData.psalmody != null) {
      for (var psalmEntry in resolvedOffice.morningData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final psalmKey = psalmEntry.psalm!;
        final psalm = resolvedOffice.psalmsCache[psalmKey];
        final tabText = getPsalmDisplayTitle(psalm, psalmKey);
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
        dataLoader: dataLoader,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
      ),
      HymnsTabWidget(
        hymns: resolvedOffice.morningData.hymn ?? [],
        dataLoader: dataLoader,
        emptyMessage: 'No hymn available',
      ),
    ];

    // Add psalm tabs dynamically
    if (resolvedOffice.morningData.psalmody != null) {
      for (var psalmEntry in resolvedOffice.morningData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final psalmKey = psalmEntry.psalm!;
        final antiphons = psalmEntry.antiphon ?? [];

        views.add(PsalmTabWidget(
          psalmKey: psalmKey,
          psalmsCache: resolvedOffice.psalmsCache,
          dataLoader: dataLoader,
          antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
          antiphon2: antiphons.length > 1 ? antiphons[1] : null,
        ));
      }
    }

    views.addAll([
      _ReadingTabSimple(morningData: resolvedOffice.morningData),
      _CanticleTabSimple(
        morningData: resolvedOffice.morningData,
        dataLoader: dataLoader,
      ),
      _OrationTabSimple(
        morningData: resolvedOffice.morningData,
        dataLoader: dataLoader,
      ),
    ]);

    return views;
  }
}

/// Introduction tab - displays office selection, introduction, and invitatory
class _IntroductionTabSimple extends StatefulWidget {
  const _IntroductionTabSimple({
    required this.resolvedOffice,
    required this.morningList,
    required this.dataLoader,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final ResolvedMorningOffice resolvedOffice;
  final Map<String, MorningDefinition> morningList;
  final DataLoader dataLoader;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  @override
  State<_IntroductionTabSimple> createState() => _IntroductionTabSimpleState();
}

class _IntroductionTabSimpleState extends State<_IntroductionTabSimple> {
  String? selectedPsalmKey;
  Map<String, String> commonTitles = {}; // code -> title
  bool isLoadingTitles = true;

  @override
  void initState() {
    super.initState();
    final invitatory = widget.resolvedOffice.morningData.invitatory;
    if (invitatory?.psalms != null && invitatory!.psalms!.isNotEmpty) {
      selectedPsalmKey = invitatory.psalms!.first.toString();
    }
    _loadCommonTitles();
  }

  Future<void> _loadCommonTitles() async {
    final commonList = widget.resolvedOffice.celebration.commonList;
    if (commonList == null || commonList.isEmpty) {
      setState(() => isLoadingTitles = false);
      return;
    }

    final titles = <String, String>{};
    for (final commonCode in commonList) {
      try {
        final filePath = 'calendar_data/commons/$commonCode.json';
        final fileContent = await widget.dataLoader.loadJson(filePath);

        if (fileContent.isNotEmpty) {
          final jsonData = json.decode(fileContent);
          final commonTitle = jsonData['commonTitle'] as String?;
          titles[commonCode] = commonTitle ?? commonCode;
        } else {
          titles[commonCode] = commonCode;
        }
      } catch (e) {
        titles[commonCode] = commonCode; // Fallback to code if error
      }
    }

    if (mounted) {
      setState(() {
        commonTitles = titles;
        isLoadingTitles = false;
      });
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
        // Office name (title first)
        Text(
          widget.resolvedOffice.celebration.morningDescription,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),

        // Liturgical color bar
        if (widget.resolvedOffice.celebration.liturgicalColor != null)
          Container(
            width: double.infinity,
            height: 6,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: getLiturgicalColor(
                  widget.resolvedOffice.celebration.liturgicalColor),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),

        // Precedence level (in italic)
        Text(
          getCelebrationTypeLabel(widget.resolvedOffice.celebration.precedence),
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),

        // Description (if exists)
        if (widget.resolvedOffice.celebration.celebrationDescription != null &&
            widget.resolvedOffice.celebration.celebrationDescription!
                .isNotEmpty) ...[
          Text(
            widget.resolvedOffice.celebration.celebrationDescription!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Celebration selector (if multiple options)
        if (_hasMultipleCelebrations()) ...[
          const Text(
            'Sélectionner l\'office des Laudes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Color(0xFFEFE3CE),
            ),
            child: DropdownButton<String>(
              value: widget.resolvedOffice.celebrationKey,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.red),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              dropdownColor: Color(0xFFEFE3CE),
              items: widget.morningList.entries
                  .where((e) => e.value.isCelebrable)
                  .map((entry) {
                final liturgicalColor = entry.value.liturgicalColor;
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: getLiturgicalColor(liturgicalColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${entry.value.morningDescription} ${getCelebrationTypeLabel(entry.value.precedence)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) widget.onCelebrationChanged(value);
              },
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Common selector (if needed)
        if (_needsCommonSelection()) ...[
          const Text(
            'Sélectionner un commun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Color(0xFFEFE3CE),
            ),
            child: DropdownButton<String?>(
              value: widget.resolvedOffice.selectedCommon,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.red),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              dropdownColor: Color(0xFFEFE3CE),
              hint: const Text('Choisir un commun',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              items: [
                // "Pas de commun" option only for optional commons (precedence > 6)
                if (widget.resolvedOffice.celebration.precedence > 6)
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Pas de commun',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                // List of available commons
                ...?widget.resolvedOffice.celebration.commonList?.map(
                  (common) => DropdownMenuItem<String?>(
                    value: common,
                    child: Text(
                      commonTitles[common] ?? common,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ),
              ],
              onChanged: widget.onCommonChanged,
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Introduction
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiturgyPartTitle(liturgyLabels['introduction'] ?? 'introduction'),
              LiturgyPartFormattedText(
                  fixedTexts['officeIntroduction'] ?? 'officeIntroduction',
                  includeVerseIdPlaceholder: false),
              SizedBox(height: spaceBetweenElements),
              SizedBox(height: spaceBetweenElements),
            ],
          ),
        ),

        // Invitatory
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LiturgyPartTitle(liturgyLabels['invitatory'] ?? 'invitatory'),
        ),
        const SizedBox(height: 16),

        // Antiphons
        if (antiphons.isNotEmpty) ...[
          AntiphonWidget(
            antiphon1: antiphons[0],
            antiphon2: antiphons.length > 1 ? antiphons[1] : null,
            antiphon3: antiphons.length > 2 ? antiphons[2] : null,
          ),
          const SizedBox(height: 16),
        ],

        // Psalm selector
        if (psalmsList.isNotEmpty) ...[
          DropdownButton<String>(
            value: selectedPsalmKey,
            hint: const Text('Sélectionner un psaume'),
            isExpanded: true,
            items: psalmsList.map((String psalmKey) {
              final psalm = widget.resolvedOffice.psalmsCache[psalmKey];
              final displayText = getPsalmDisplayTitle(psalm, psalmKey);
              return DropdownMenuItem<String>(
                value: psalmKey,
                child: Text(displayText),
              );
            }).toList(),
            onChanged: (String? newKey) {
              setState(() {
                selectedPsalmKey = newKey;
              });
            },
          ),
          const SizedBox(height: 20),
        ],

        // Display selected psalm
        if (selectedPsalmKey != null) _buildPsalm(selectedPsalmKey!, antiphons),
      ],
    );
  }

  Widget _buildPsalm(String psalmKey, List<String> antiphons) {
    final psalm = widget.resolvedOffice.psalmsCache[psalmKey];
    if (psalm == null) {
      return const Text('Psalm not found');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PsalmFromHtml(htmlContent: psalm.getContent),
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

    // Don't show selector if no commons available
    if (commonList == null || commonList.isEmpty) {
      return false;
    }

    // Don't show selector during octaves (paschaloctave, christmasoctave)
    if (liturgicalTime == 'paschaloctave' || liturgicalTime == 'christmasoctave') {
      return false;
    }

    // For ferial celebrations (celebrationCode == ferialCode), don't show common selector
    // even if the celebration data structure has a commonList
    if (celebration.celebrationCode == celebration.ferialCode) {
      return false;
    }

    // Show selector if:
    // 1. There are 2 or more commons, OR
    // 2. There's exactly 1 common AND it's optional (precedence > 6)
    return commonList.length >= 2 || (commonList.length == 1 && precedence > 6);
  }
}

/// Reading tab - displays scripture reading and responsory
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

/// Canticle tab - displays evangelic canticle (Benedictus)
class _CanticleTabSimple extends StatelessWidget {
  const _CanticleTabSimple({
    required this.morningData,
    required this.dataLoader,
  });

  final Morning morningData;
  final DataLoader dataLoader;

  @override
  Widget build(BuildContext context) {
    final antiphon = morningData.evangelicAntiphon?.common;

    if (antiphon == null) {
      return const Center(child: Text('No antiphon available'));
    }

    return CanticleWidget(
      canticleType: 'benedictus',
      antiphon1: antiphon,
      dataLoader: dataLoader,
    );
  }
}

/// Oration tab - displays intercession, Our Father, oration, and blessing
class _OrationTabSimple extends StatefulWidget {
  const _OrationTabSimple({
    required this.morningData,
    required this.dataLoader,
  });

  final Morning morningData;
  final DataLoader dataLoader;

  @override
  State<_OrationTabSimple> createState() => _OrationTabSimpleState();
}

class _OrationTabSimpleState extends State<_OrationTabSimple> {
  String? notrePereContent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotrePere();
  }

  Future<void> _loadNotrePere() async {
    try {
      final hymns =
          await HymnsLibrary.getHymns(['notre-pere'], widget.dataLoader);
      if (mounted) {
        setState(() {
          notrePereContent = hymns['notre-pere']?.content;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading Notre Père: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intercession section
        LiturgyPartTitle(liturgyLabels['intercession'] ?? 'intercession'),
        if (widget.morningData.intercession?.content != null) ...[
          LiturgyPartFormattedText(
            widget.morningData.intercession!.content!,
            textAlign: TextAlign.justify,
            includeVerseIdPlaceholder: false,
          ),
          SizedBox(height: spaceBetweenElements),
          SizedBox(height: spaceBetweenElements),
        ] else ...[
          const Text('No intercession available'),
          SizedBox(height: spaceBetweenElements),
          SizedBox(height: spaceBetweenElements),
        ],

        // Notre Père section
        LiturgyPartTitle(liturgyLabels['our_father'] ?? 'our_father'),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (notrePereContent != null)
          LiturgyPartFormattedText(
            notrePereContent!,
            textAlign: TextAlign.justify,
            includeVerseIdPlaceholder: false,
          )
        else
          LiturgyPartFormattedText(
            fixedTexts['ourFather'] ??
                'Notre Père, qui es aux cieux,\nque ton nom soit sanctifié,\nque ton règne vienne,\nque ta volonté soit faite sur la terre comme au ciel.\nDonne-nous aujourd\'hui notre pain de ce jour.\nPardonne-nous nos offenses,\ncomme nous pardonnons aussi à ceux qui nous ont offensés.\nEt ne nous laisse pas entrer en tentation\nmais délivre-nous du Mal.\nAmen.',
            includeVerseIdPlaceholder: false,
          ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),

        // Oration section
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'oration'),
        LiturgyPartFormattedText(
          widget.morningData.oration?.join("\n") ?? 'No oration available',
          textAlign: TextAlign.justify,
          includeVerseIdPlaceholder: false,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),

        // Blessing section
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'blessing'),
        LiturgyPartFormattedText(
          fixedTexts['officeBenediction'] ?? 'officeBenediction',
          includeVerseIdPlaceholder: false,
        ),
      ],
    );
  }
}
