import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

class SexteView extends StatefulWidget {
  const SexteView({
    super.key,
    required this.middleOfDayList,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, CelebrationContext> middleOfDayList;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  State<SexteView> createState() => _SexteViewState();
}

class _SexteViewState extends State<SexteView> {
  bool _isLoading = true;
  String? _celebrationKey;
  CelebrationContext? _selectedDefinition;
  MiddleOfDay? _officeData;
  String? _selectedCommon;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOffice();
  }

  @override
  void didUpdateWidget(SexteView oldWidget) {
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
      final officeData = await middleOfDayExport(celebrationContext);

      if (mounted) {
        setState(() {
          _officeData = officeData;
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
        commonList: autoCommon != null ? [autoCommon] : [],
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
      final officeData = await middleOfDayExport(celebrationContext);

      if (mounted) {
        setState(() {
          _selectedCommon = common;
          _officeData = officeData;
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
        _officeData != null) {
      return _SexteOfficeDisplay(
        celebrationKey: _celebrationKey!,
        definition: _selectedDefinition!,
        officeData: _officeData!,
        selectedCommon: _selectedCommon,
        middleOfDayList: widget.middleOfDayList,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
      );
    }
    return const Center(child: Text('No data available'));
  }
}

class _SexteOfficeDisplay extends StatelessWidget {
  const _SexteOfficeDisplay({
    required this.celebrationKey,
    required this.definition,
    required this.officeData,
    required this.selectedCommon,
    required this.middleOfDayList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final CelebrationContext definition;
  final MiddleOfDay officeData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> middleOfDayList;
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
    // Introduction + Hymne + Psaumes + Lecture + Oraison
    return 4 + (officeData.psalmody?.length ?? 0);
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
      const Tab(text: 'Hymne'),
    ];
    if (officeData.psalmody != null) {
      for (var psalmEntry in officeData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final tabText =
            getPsalmDisplayTitle(psalmEntry.psalmData, psalmEntry.psalm!);
        tabs.add(Tab(text: tabText));
      }
    }
    tabs.addAll([
      const Tab(text: 'Lecture'),
      const Tab(text: 'Oraison'),
    ]);
    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[
      _IntroductionTab(
        celebrationKey: celebrationKey,
        definition: definition,
        selectedCommon: selectedCommon,
        middleOfDayList: middleOfDayList,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
      ),
      HymnsTabWidget(
        hymns: officeData.hymnSexte ?? [],
        emptyMessage: 'Pas d\'hymne disponible',
      ),
    ];
    if (officeData.psalmody != null) {
      for (var psalmEntry in officeData.psalmody!) {
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
      _ReadingTab(hourOffice: officeData.sexte),
      _OrationTab(officeData: officeData),
    ]);
    return views;
  }
}

class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.celebrationKey,
    required this.definition,
    required this.selectedCommon,
    required this.middleOfDayList,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final CelebrationContext definition;
  final String? selectedCommon;
  final Map<String, CelebrationContext> middleOfDayList;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // --- Header Section ---
        Text(
          definition.officeDescription ?? '',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (definition.liturgicalColor != null)
          Container(
            width: double.infinity,
            height: 6,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: getLiturgicalColor(definition.liturgicalColor),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        Text(
          getCelebrationTypeLabel(definition.precedence ?? 13),
          style: const TextStyle(
              fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        if (definition.celebrationDescription != null &&
            definition.celebrationDescription!.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              definition.celebrationDescription!,
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
            celebrationMap: middleOfDayList,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        if (_needsCommonSelection()) ...[
          if ((definition.commonList?.length ?? 0) > 1 ||
              (definition.precedence ?? 13) > 8)
            _buildSectionTitle('Sélectionner un commun'),
          CommonChipsSelector(
            commonList: definition.commonList ?? [],
            commonTitles: definition.commonTitles,
            selectedCommon: selectedCommon,
            precedence: definition.precedence ?? 13,
            onCommonChanged: onCommonChanged,
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
}

class _ReadingTab extends StatelessWidget {
  const _ReadingTab({required this.hourOffice});
  final HourOffice? hourOffice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hourOffice?.antiphon != null) ...[
          AntiphonWidget(antiphon1: hourOffice!.antiphon!),
          SizedBox(height: spaceBetweenElements),
        ],
        ScriptureWidget(
          title: liturgyLabels['word_of_god'] ?? 'Parole de Dieu',
          reference: hourOffice?.reading?.biblicalReference,
          content: hourOffice?.reading?.content,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
        LiturgyPartFormattedText(
            hourOffice?.responsory ?? 'No responsory available',
            includeVerseIdPlaceholder: false),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}

class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.officeData});
  final MiddleOfDay officeData;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        LiturgyPartFormattedText(
          officeData.oration?.join("\n") ?? 'No oration available',
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
