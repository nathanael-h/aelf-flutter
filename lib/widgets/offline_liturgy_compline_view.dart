import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:offline_liturgy/offices/compline/compline.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/liturgy_part_info_widget.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';

class ComplineView extends StatefulWidget {
  const ComplineView({
    super.key,
    required this.complineDefinitionsList,
    required this.dataLoader,
    required this.calendar,
    required this.date,
  });

  final Map<String, ComplineDefinition> complineDefinitionsList;
  final DataLoader dataLoader;
  final Calendar calendar;
  final DateTime date;

  @override
  State<ComplineView> createState() => _ComplineViewState();
}

class _ComplineViewState extends State<ComplineView> {
  String? selectedComplineKey;
  late Compline currentCompline;
  Map<String, dynamic>? psalmsCache;

  @override
  void initState() {
    super.initState();
    selectedComplineKey = widget.complineDefinitionsList.keys.first;
    _updateCompline();
    _loadPsalms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(ComplineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.complineDefinitionsList != widget.complineDefinitionsList) {
      selectedComplineKey = widget.complineDefinitionsList.keys.first;
      _updateCompline();
      _loadPsalms();
    }
  }

  Future<void> _loadPsalms() async {
    final loadedPsalms = await loadPsalmsFromPsalmody(
      currentCompline.psalmody,
      widget.dataLoader,
    );
    if (mounted) {
      setState(() {
        psalmsCache = loadedPsalms;
      });
    }
  }

  void _updateCompline() {
    Map<String, ComplineDefinition> singleComplineMap = {
      selectedComplineKey!: widget.complineDefinitionsList[selectedComplineKey]!
    };
    Map<String, Compline> compiledComplines =
        complineTextCompilation(singleComplineMap);
    currentCompline = compiledComplines.values.first;
  }

  void _onComplineChanged(String? newKey) {
    if (newKey != null && newKey != selectedComplineKey) {
      setState(() {
        selectedComplineKey = newKey;
        _updateCompline();
        _loadPsalms();
      });
    }
  }

  int get _psalmCount => currentCompline.psalmody?.length ?? 0;
  int get _tabCount => 6 + _psalmCount;

  @override
  Widget build(BuildContext context) {
    if (psalmsCache == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: _tabCount,
      child: Column(
        children: [
          _buildTabBar(context),
          Expanded(child: _buildTabBarView()),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Theme.of(context).primaryColor,
      child: Center(
        child: TabBar(
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: _buildTabs(),
        ),
      ),
    );
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[
      const Tab(text: 'Introduction'),
      const Tab(text: 'Hymnes'),
    ];

    if (currentCompline.psalmody != null) {
      for (var psalmEntry in currentCompline.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final psalmKey = psalmEntry.psalm!;
        final psalm = psalmsCache![psalmKey];
        final tabText = getPsalmDisplayTitle(psalm, psalmKey);
        tabs.add(Tab(text: tabText));
      }
    }

    tabs.addAll([
      Tab(text: liturgyLabels['reading']),
      Tab(text: liturgyLabels['simeon_canticle']),
      Tab(text: liturgyLabels['oration']),
      Tab(text: liturgyLabels['marial_hymns']),
    ]);

    return tabs;
  }

  Widget _buildTabBarView() {
    final views = <Widget>[
      _IntroductionTab(
        compline: currentCompline,
        complineDefinitionsList: widget.complineDefinitionsList,
        selectedKey: selectedComplineKey!,
        onComplineChanged: _onComplineChanged,
        calendar: widget.calendar,
        date: widget.date,
      ),
      HymnsTabWidget(
        hymns: currentCompline.hymns ?? [],
        dataLoader: widget.dataLoader,
        emptyMessage: 'Aucune hymne disponible',
      ),
    ];

    if (currentCompline.psalmody != null) {
      for (var psalmEntry in currentCompline.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final psalmKey = psalmEntry.psalm!;
        final antiphons = psalmEntry.antiphon ?? [];

        views.add(PsalmTabWidget(
          psalmKey: psalmKey,
          psalmsCache: psalmsCache!,
          dataLoader: widget.dataLoader,
          antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
          antiphon2: antiphons.length > 1 ? antiphons[1] : null,
        ));
      }
    }

    views.addAll([
      _ReadingTab(compline: currentCompline),
      _CanticleTab(
        compline: currentCompline,
        dataLoader: widget.dataLoader,
      ),
      _OrationTab(compline: currentCompline),
      HymnsTabWidget(
        hymns: currentCompline.marialHymnRef ?? [],
        dataLoader: widget.dataLoader,
        emptyMessage: 'Aucune hymne mariale disponible',
      ),
    ]);

    return TabBarView(children: views);
  }
}

// ==================== SEPARATED WIDGETS ====================

class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.compline,
    required this.complineDefinitionsList,
    required this.selectedKey,
    required this.onComplineChanged,
    required this.calendar,
    required this.date,
  });

  final Compline compline;
  final Map<String, ComplineDefinition> complineDefinitionsList;
  final String selectedKey;
  final ValueChanged<String?> onComplineChanged;
  final Calendar calendar;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final showDropdown = complineDefinitionsList.length > 1;
    final complineDefinition = complineDefinitionsList[selectedKey]!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        if (showDropdown) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisir les Complies :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedKey,
                      isExpanded: true,
                      items: complineDefinitionsList.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value.complineDescription),
                        );
                      }).toList(),
                      onChanged: onComplineChanged,
                    ),
                  ),
                ),
                SizedBox(height: spaceBetweenElements),
              ],
            ),
          ),
        ],
        LiturgyPartInfoWidget(
          complineDefinition: complineDefinition,
          calendar: calendar,
          date: date,
        ),
        if (compline.commentary != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Note :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(compline.commentary!),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiturgyPartTitle(liturgyLabels['introduction']),
              LiturgyPartFormattedText(
                fixedTexts['officeIntroduction'],
                includeVerseIdPlaceholder: false,
              ),
              SizedBox(height: spaceBetweenElements),
              LiturgyPartRubric(fixedTexts['complineIntroduction']),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadingTab extends StatelessWidget {
  const _ReadingTab({required this.compline});

  final Compline compline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScriptureWidget(
          title: liturgyLabels['word_of_god']!,
          reference: compline.reading?.biblicalReference,
          content: compline.reading?.content,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['responsory']),
        LiturgyPartFormattedText(compline.responsory ?? '(texte introuvable)',
            includeVerseIdPlaceholder: false),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}

class _CanticleTab extends StatelessWidget {
  const _CanticleTab({
    required this.compline,
    required this.dataLoader,
  });

  final Compline compline;
  final DataLoader dataLoader;

  @override
  Widget build(BuildContext context) {
    final antiphon = compline.evangelicAntiphon?.common ?? '';

    return CanticleWidget(
      canticleType: 'nunc_dimittis',
      antiphon1: antiphon,
      dataLoader: dataLoader,
    );
  }
}

class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.compline});

  final Compline compline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['oration']),
        LiturgyPartFormattedText(
          compline.oration?.join("\n") ?? '',
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['blessing']),
        LiturgyPartFormattedText(fixedTexts['complineConclusion']),
      ],
    );
  }
}
