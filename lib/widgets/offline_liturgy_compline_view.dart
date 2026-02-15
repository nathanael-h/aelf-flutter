import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/usual_texts.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:offline_liturgy/offices/compline/compline_export.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/liturgy_part_info_widget.dart';
import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';

/// Compline View
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
  Compline? currentCompline;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  @override
  void didUpdateWidget(ComplineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the list of definitions changes (e.g. date changed), we re-initialize
    if (oldWidget.complineDefinitionsList != widget.complineDefinitionsList) {
      _initializeSelection();
    }
  }

  void _initializeSelection() {
    if (widget.complineDefinitionsList.isNotEmpty) {
      // Always pick the first one (most prioritized by our engine)
      selectedComplineKey = widget.complineDefinitionsList.keys.first;
      _loadCompline();
    }
  }

  Future<void> _loadCompline() async {
    // 1. On vérifie qu'une clé est bien sélectionnée
    if (selectedComplineKey == null) return;

    setState(() => _isLoading = true);

    try {
      // 2. On récupère la définition dans la Map passée au Widget
      // Note: on utilise widget.complineDefinitionsList car on est dans le State
      final definition = widget.complineDefinitionsList[selectedComplineKey]!;

      // 3. On appelle la fonction d'export que nous avons créée
      // Elle prend la définition et le dataLoader
      final Compline compiledCompline = await complineExport(
        definition,
        widget.dataLoader,
      );

      if (mounted) {
        setState(() {
          currentCompline = compiledCompline;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading compline: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onComplineChanged(String? newKey) {
    if (newKey != null && newKey != selectedComplineKey) {
      setState(() {
        selectedComplineKey = newKey;
      });
      _loadCompline();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && currentCompline == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentCompline == null) {
      return const Center(child: Text("Erreur de chargement des Complies"));
    }

    return Stack(
      children: [
        ComplineOfficeDisplay(
          compline: currentCompline!,
          complineDefinitionsList: widget.complineDefinitionsList,
          selectedKey: selectedComplineKey!,
          onComplineChanged: _onComplineChanged,
          calendar: widget.calendar,
          date: widget.date,
        ),
        if (_isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

/// Pure display widget for Compline
class ComplineOfficeDisplay extends StatelessWidget {
  const ComplineOfficeDisplay({
    super.key,
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
    return DefaultTabController(
      length: _calculateTabCount(),
      child: Column(
        children: [
          _buildTabBar(context),
          Expanded(child: _buildTabBarView()),
        ],
      ),
    );
  }

  int _calculateTabCount() => 6 + (compline.psalmody?.length ?? 0);

  Widget _buildTabBar(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
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

    if (compline.psalmody != null) {
      for (var psalmEntry in compline.psalmody!) {
        final tabText =
            getPsalmDisplayTitle(psalmEntry.psalmData, psalmEntry.psalm ?? '');
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
        compline: compline,
        complineDefinitionsList: complineDefinitionsList,
        selectedKey: selectedKey,
        onComplineChanged: onComplineChanged,
        calendar: calendar,
        date: date,
      ),
      HymnsTabWidget(
        hymns: compline.hymns ?? [],
        emptyMessage: 'Aucune hymne disponible',
      ),
    ];

    if (compline.psalmody != null) {
      for (var psalmEntry in compline.psalmody!) {
        final antiphons = psalmEntry.antiphon ?? [];
        views.add(PsalmTabWidget(
          psalm: psalmEntry.psalmData,
          antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
          antiphon2: antiphons.length > 1 ? antiphons[1] : null,
        ));
      }
    }

    views.addAll([
      _ReadingTab(compline: compline),
      _CanticleTab(compline: compline),
      _OrationTab(compline: compline),
      HymnsTabWidget(
        hymns: compline.marialHymnRef ?? [],
        emptyMessage: 'Aucune hymne mariale disponible',
      ),
    ]);

    return TabBarView(children: views);
  }
}

// --- SUB-WIDGETS ---

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
    final definition = complineDefinitionsList[selectedKey]!;

    return ListView(
      children: [
        // --- OFFICE SELECTOR (Visible only if choice exists) ---
        if (complineDefinitionsList.length > 1) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Choisir les Complies :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 0.0,
              children: complineDefinitionsList.entries.map((entry) {
                final isSelected = selectedKey == entry.key;
                return ChoiceChip(
                  avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
                  label: Text(entry.value.complineDescription),
                  selected: isSelected,
                  onSelected: (selected) =>
                      onComplineChanged(selected ? entry.key : null),
                  selectedColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LiturgyPartInfoWidget(
            complineDefinition: definition,
            calendar: calendar,
            date: date,
          ),
        ),

        if (compline.commentary != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Text(compline.commentary!,
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiturgyPartTitle(liturgyLabels['introduction']),
              LiturgyPartFormattedText(fixedTexts['officeIntroduction'],
                  includeVerseIdPlaceholder: false),
              const SizedBox(height: 16),
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
        const SizedBox(height: 32),
        LiturgyPartTitle(liturgyLabels['responsory']),
        LiturgyPartFormattedText(compline.responsory ?? '',
            includeVerseIdPlaceholder: false),
      ],
    );
  }
}

class _CanticleTab extends StatelessWidget {
  const _CanticleTab({required this.compline});
  final Compline compline;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        CanticleWidget(
            antiphons: {'antiphon': compline.evangelicAntiphon?.common ?? ''},
            psalm: nuncDimittis),
      ],
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
        LiturgyPartFormattedText(compline.oration?.join("\n") ?? '',
            textAlign: TextAlign.justify, includeVerseIdPlaceholder: false),
        const SizedBox(height: 32),
        LiturgyPartTitle(liturgyLabels['blessing']),
        LiturgyPartFormattedText(fixedTexts['complineConclusion'],
            includeVerseIdPlaceholder: false),
      ],
    );
  }
}
