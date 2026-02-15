import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/usual_texts.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Vespers View
///
/// Architecture:
/// 1. VespersView (StatefulWidget) - Manages UI state and data loading
/// 2. VespersOfficeDisplay (StatelessWidget) - Pure display widget
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
  bool _isLoading = true;
  String? _celebrationKey;
  CelebrationContext? _selectedDefinition;
  Vespers? _vespersData;
  String? _selectedCommon;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadOffice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firstOption = widget.vespersList.entries
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
        date: widget.date,
      );
      final vespersData = await vespersResolution(celebrationContext);

      if (mounted) {
        setState(() {
          _vespersData = vespersData;
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
    final definition = widget.vespersList[key];
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
        date: widget.date,
      );
      final vespersData = await vespersResolution(celebrationContext);

      if (mounted) {
        setState(() {
          _celebrationKey = key;
          _selectedDefinition = definition;
          _selectedCommon = autoCommon;
          _vespersData = vespersData;
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
        date: widget.date,
      );
      final vespersData = await vespersResolution(celebrationContext);

      if (mounted) {
        setState(() {
          _selectedCommon = common;
          _vespersData = vespersData;
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
        _vespersData != null) {
      return VespersOfficeDisplay(
        celebrationKey: _celebrationKey!,
        vespersDefinition: _selectedDefinition!,
        vespersData: _vespersData!,
        selectedCommon: _selectedCommon,
        vespersList: widget.vespersList,
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
    required this.celebrationKey,
    required this.vespersDefinition,
    required this.vespersData,
    required this.selectedCommon,
    required this.vespersList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final CelebrationContext vespersDefinition;
  final Vespers vespersData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> vespersList;
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
    return 6 + (vespersData.psalmody?.length ?? 0);
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

    if (vespersData.psalmody != null) {
      for (var psalmEntry in vespersData.psalmody!) {
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
      _IntroductionTab(
        celebrationKey: celebrationKey,
        vespersDefinition: vespersDefinition,
        vespersData: vespersData,
        selectedCommon: selectedCommon,
        vespersList: vespersList,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
      ),
      HymnsTabWidget(
        hymns: vespersData.hymn ?? [],
        emptyMessage: 'No hymn available',
      ),
    ];

    if (vespersData.psalmody != null) {
      for (var psalmEntry in vespersData.psalmody!) {
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
      _ReadingTab(vespersData: vespersData),
      _CanticleTab(vespersData: vespersData),
      _IntercessionTab(vespersData: vespersData),
      _ConclusionTab(vespersData: vespersData),
    ]);

    return views;
  }
}

/// Introduction tab - displays office selection and introduction
class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.celebrationKey,
    required this.vespersDefinition,
    required this.vespersData,
    required this.selectedCommon,
    required this.vespersList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final CelebrationContext vespersDefinition;
  final Vespers vespersData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> vespersList;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // Office title display
        Text(
          vespersDefinition.officeDescription ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Liturgical color bar
        if (vespersDefinition.liturgicalColor != null &&
            vespersDefinition.liturgicalColor!.isNotEmpty)
          Container(
            width: double.infinity,
            height: 6,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: getLiturgicalColor(vespersDefinition.liturgicalColor),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

        // Precedence level
        Text(
          getCelebrationTypeLabel(vespersDefinition.precedence ?? 13),
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Description
        if (vespersDefinition.celebrationDescription != null &&
            vespersDefinition.celebrationDescription!.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              vespersDefinition.celebrationDescription!,
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
            celebrationMap: vespersList,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        if (_needsCommonSelection()) ...[
          if ((vespersDefinition.commonList?.length ?? 0) > 1 ||
              (vespersDefinition.precedence ?? 13) > 8)
            _buildSectionTitle('Sélectionner un commun'),
          CommonChipsSelector(
            commonList: vespersDefinition.commonList ?? [],
            commonTitles: vespersDefinition.commonTitles,
            selectedCommon: selectedCommon,
            precedence: vespersDefinition.precedence ?? 13,
            onCommonChanged: onCommonChanged,
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
    return vespersList.values.where((d) => d.isCelebrable).length > 1;
  }

  bool _needsCommonSelection() {
    final commonList = vespersDefinition.commonList;
    final liturgicalTime = vespersDefinition.liturgicalTime;

    if (commonList == null || commonList.isEmpty) return false;
    if (liturgicalTime == 'paschaloctave' ||
        liturgicalTime == 'christmasoctave') {
      return false;
    }
    if (vespersDefinition.celebrationCode == vespersDefinition.ferialCode) {
      return false;
    }

    return true;
  }
}

class _ReadingTab extends StatelessWidget {
  const _ReadingTab({required this.vespersData});
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

class _CanticleTab extends StatelessWidget {
  const _CanticleTab({required this.vespersData});
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

class _IntercessionTab extends StatelessWidget {
  const _IntercessionTab({required this.vespersData});
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

class _ConclusionTab extends StatelessWidget {
  const _ConclusionTab({required this.vespersData});
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
