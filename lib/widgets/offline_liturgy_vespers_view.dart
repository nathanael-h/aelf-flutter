import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/usual_texts.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/services/vespers_office_service.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:yaml/yaml.dart';

/// Vespers View
///
/// Architecture:
/// 1. VespersView (StatefulWidget) - Manages UI state only
/// 2. VespersOfficeService - Handles all data loading/resolution
/// 3. VespersOfficeDisplay (StatelessWidget) - Pure display widget
class VespersView extends StatefulWidget {
  const VespersView({
    super.key,
    required this.vespersList,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, CelebrationContext> vespersList;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  State<VespersView> createState() => _VespersViewState();
}

class _VespersViewState extends State<VespersView> {
  late final VespersOfficeService _service;

  // Simple state: either loading or resolved
  bool _isLoading = true;
  ResolvedVespersOffice? _resolvedOffice;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = VespersOfficeService(dataLoader: widget.dataLoader);
    _loadOffice();
  }

  @override
  void didUpdateWidget(VespersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.vespersList != widget.vespersList) {
      _loadOffice();
    }
  }

  /// Single method to load everything
  Future<void> _loadOffice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Find first celebrable option
      final firstOption = _service.getFirstCelebrableOption(widget.vespersList);

      if (firstOption == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No celebrable office available';
        });
        return;
      }

      // Step 2: Determine which common to use (if any)
      final autoCommon = _service.determineAutoCommon(firstOption.value);

      // Step 3: Resolve complete office
      final resolved = await _service.resolveCompleteVespersOffice(
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
    final celebration = widget.vespersList[key];
    if (celebration == null) return;

    setState(() => _isLoading = true);

    try {
      final autoCommon = _service.determineAutoCommon(celebration);

      final resolved = await _service.resolveCompleteVespersOffice(
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
      final resolved = await _service.resolveCompleteVespersOffice(
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
            ElevatedButton(
              onPressed: _loadOffice,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_resolvedOffice != null) {
      return VespersOfficeDisplay(
        resolvedOffice: _resolvedOffice!,
        vespersList: widget.vespersList,
        dataLoader: widget.dataLoader,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
      );
    }

    return const Center(child: Text('No data available'));
  }
}

/// Pure display widget - receives all data, no async logic
class VespersOfficeDisplay extends StatelessWidget {
  const VespersOfficeDisplay({
    super.key,
    required this.resolvedOffice,
    required this.vespersList,
    required this.dataLoader,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final ResolvedVespersOffice resolvedOffice;
  final Map<String, CelebrationContext> vespersList;
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
    // Introduction, Hymnes, Psalms..., Lecture, Magnificat, Intercession, Conclusion
    return 6 + (resolvedOffice.vespersData.psalmody?.length ?? 0);
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

    if (resolvedOffice.vespersData.psalmody != null) {
      for (var psalmEntry in resolvedOffice.vespersData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final tabText =
            getPsalmDisplayTitle(psalmEntry.psalmData, psalmEntry.psalm!);
        tabs.add(Tab(text: tabText));
      }
    }

    tabs.addAll([
      const Tab(text: 'Lecture'),
      const Tab(text: 'Magnificat'),
      const Tab(text: 'Intercession'),
      const Tab(text: 'Conclusion'),
    ]);

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[
      _IntroductionTabSimple(
        resolvedOffice: resolvedOffice,
        vespersList: vespersList,
        dataLoader: dataLoader,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
      ),
      HymnsTabWidget(
        hymns: resolvedOffice.vespersData.hymn ?? [],
        emptyMessage: 'No hymn available',
      ),
    ];

    if (resolvedOffice.vespersData.psalmody != null) {
      for (var psalmEntry in resolvedOffice.vespersData.psalmody!) {
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
      _ReadingTabSimple(vespersData: resolvedOffice.vespersData),
      _CanticleTabSimple(vespersData: resolvedOffice.vespersData),
      _IntercessionTabSimple(vespersData: resolvedOffice.vespersData),
      _ConclusionTabSimple(vespersData: resolvedOffice.vespersData),
    ]);

    return views;
  }
}

/// Introduction tab - displays office selection and introduction
class _IntroductionTabSimple extends StatefulWidget {
  const _IntroductionTabSimple({
    required this.resolvedOffice,
    required this.vespersList,
    required this.dataLoader,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final ResolvedVespersOffice resolvedOffice;
  final Map<String, CelebrationContext> vespersList;
  final DataLoader dataLoader;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  @override
  State<_IntroductionTabSimple> createState() => _IntroductionTabSimpleState();
}

class _IntroductionTabSimpleState extends State<_IntroductionTabSimple> {
  Map<String, String> commonTitles = {}; // code -> title
  bool isLoadingTitles = true;

  @override
  void initState() {
    super.initState();
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
        final filePath = 'calendar_data/commons/$commonCode.yaml';
        final fileContent = await widget.dataLoader.loadYaml(filePath);

        if (fileContent.isNotEmpty) {
          final yamlData = loadYaml(fileContent);
          final data = _convertYamlToDart(yamlData);
          final commonTitle = data['commonTitle'] as String?;
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

  dynamic _convertYamlToDart(dynamic value) {
    if (value is YamlMap) {
      return value
          .map((key, val) => MapEntry(key.toString(), _convertYamlToDart(val)));
    } else if (value is YamlList) {
      return value.map((item) => _convertYamlToDart(item)).toList();
    } else {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // Office title display
        Text(
          widget.resolvedOffice.celebration.officeDescription ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Liturgical color bar
        if (widget.resolvedOffice.celebration.liturgicalColor != null &&
            widget.resolvedOffice.celebration.liturgicalColor!.isNotEmpty)
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

        // Precedence level
        Text(
          getCelebrationTypeLabel(
              widget.resolvedOffice.celebration.precedence ?? 13),
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Description
        if (widget.resolvedOffice.celebration.celebrationDescription != null &&
            widget.resolvedOffice.celebration.celebrationDescription!
                .isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.resolvedOffice.celebration.celebrationDescription!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // --- Selection Chips ---

        if (_hasMultipleCelebrations()) ...[
          _buildSectionTitle('Sélectionner l\'office'),
          CelebrationChipsSelector(
            celebrationMap: widget.vespersList,
            selectedKey: widget.resolvedOffice.celebrationKey,
            onCelebrationChanged: widget.onCelebrationChanged,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        if (_needsCommonSelection()) ...[
          _buildSectionTitle('Sélectionner un commun'),
          CommonChipsSelector(
            commonList: widget.resolvedOffice.celebration.commonList ?? [],
            commonTitles: commonTitles,
            selectedCommon: widget.resolvedOffice.selectedCommon,
            precedence: widget.resolvedOffice.celebration.precedence ?? 13,
            onCommonChanged: widget.onCommonChanged,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Introduction text
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

  bool _hasMultipleCelebrations() {
    return widget.vespersList.values.where((d) => d.isCelebrable).length > 1;
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

class _ReadingTabSimple extends StatelessWidget {
  const _ReadingTabSimple({required this.vespersData});
  final Vespers vespersData;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScriptureWidget(
          title: liturgyLabels['word_of_god'] ?? 'Parole de Dieu',
          reference: vespersData.reading?.biblicalReference,
          content: vespersData.reading?.content,
        ),
        SizedBox(height: spaceBetweenElements * 2),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
        LiturgyPartFormattedText(
            vespersData.responsory ?? 'No responsory available',
            includeVerseIdPlaceholder: false),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}

class _CanticleTabSimple extends StatelessWidget {
  const _CanticleTabSimple({required this.vespersData});
  final Vespers vespersData;
  @override
  Widget build(BuildContext context) {
    final antiphon = vespersData.evangelicAntiphon?.common;
    if (antiphon == null) {
      return const Center(child: Text('No antiphon available'));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      children: [
        CanticleWidget(antiphon1: antiphon, psalm: magnificat),
      ],
    );
  }
}

class _IntercessionTabSimple extends StatelessWidget {
  const _IntercessionTabSimple({required this.vespersData});
  final Vespers vespersData;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['intercession'] ?? 'Intercession'),
        if (vespersData.intercession?.content != null)
          LiturgyPartFormattedText(
            vespersData.intercession!.content!,
            textAlign: TextAlign.justify,
            includeVerseIdPlaceholder: false,
          )
        else
          const Text('Pas d\'intercession disponible'),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}

class _ConclusionTabSimple extends StatelessWidget {
  const _ConclusionTabSimple({required this.vespersData});
  final Vespers vespersData;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['our_father'] ?? 'Notre Père'),
        HymnContentDisplay(content: notrePere.content),
        SizedBox(height: spaceBetweenElements * 2),
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        LiturgyPartFormattedText(
          vespersData.oration?.join("\n") ?? 'Pas d\'oraison disponible',
          textAlign: TextAlign.justify,
          includeVerseIdPlaceholder: false,
        ),
        SizedBox(height: spaceBetweenElements * 2),
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'Bénédiction'),
        LiturgyPartFormattedText(
          fixedTexts['officeBenediction'] ?? 'officeBenediction',
          includeVerseIdPlaceholder: false,
        ),
      ],
    );
  }
}
