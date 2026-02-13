import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/usual_texts.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:offline_liturgy/offices/compline/compline_resolution.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/liturgy_part_info_widget.dart';
import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';

/// Compline View
///
/// Architecture:
/// 1. ComplineView (StatefulWidget) - Manages UI state and data resolution
/// 2. ComplineOfficeDisplay (StatelessWidget) - Pure display widget
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
    selectedComplineKey = widget.complineDefinitionsList.keys.first;
    _loadCompline();
  }

  @override
  void didUpdateWidget(ComplineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.complineDefinitionsList != widget.complineDefinitionsList) {
      selectedComplineKey = widget.complineDefinitionsList.keys.first;
      _loadCompline();
    }
  }

  Future<void> _loadCompline() async {
    setState(() => _isLoading = true);

    try {
      Map<String, ComplineDefinition> singleComplineMap = {
        selectedComplineKey!:
            widget.complineDefinitionsList[selectedComplineKey]!
      };

      final compiledComplines =
          await complineTextCompilation(singleComplineMap, widget.dataLoader);

      if (mounted) {
        setState(() {
          currentCompline = compiledComplines.values.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onComplineChanged(String? newKey) {
    if (newKey != null && newKey != selectedComplineKey) {
      selectedComplineKey = newKey;
      _loadCompline();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentCompline == null) {
      return const Center(child: Text("Erreur de chargement des Complies"));
    }

    return ComplineOfficeDisplay(
      compline: currentCompline!,
      complineDefinitionsList: widget.complineDefinitionsList,
      selectedKey: selectedComplineKey!,
      onComplineChanged: _onComplineChanged,
      calendar: widget.calendar,
      date: widget.date,
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

  int _calculateTabCount() {
    return 6 + (compline.psalmody?.length ?? 0);
  }

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
        if (psalmEntry.psalm == null) continue;
        final tabText =
            getPsalmDisplayTitle(psalmEntry.psalmData, psalmEntry.psalm!);
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

// ==================== SUB-WIDGETS ====================

// Remplacez la classe _IntroductionTab par celle-ci

class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    super.key, // Ajout de super.key recommandé
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
    final complineDefinition = complineDefinitionsList[selectedKey]!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // --- SÉLECTEUR D'OFFICE ---
        if (complineDefinitionsList.length > 1) ...[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: const Text(
              'Choisir les Complies :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: complineDefinitionsList.entries.map((entry) {
                final chipMaxWidth = MediaQuery.of(context).size.width - 80;
                return ChoiceChip(
                  label: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: chipMaxWidth),
                    child: Text(
                      entry.value.complineDescription,
                      softWrap: true,
                      maxLines: 3,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  selected: selectedKey == entry.key,
                  onSelected: (selected) {
                    if (selected) onComplineChanged(entry.key);
                  },
                  selectedColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // --- INFO LITURGIQUE (Date, couleur...) ---
        // CORRECTION : Ajout du Padding 16 pour aligner avec le reste
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LiturgyPartInfoWidget(
            complineDefinition: complineDefinition,
            calendar: calendar,
            date: date,
          ),
        ),

        // --- COMMENTAIRE ---
        if (compline.commentary != null) ...[
          SizedBox(height: spaceBetweenElements),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets
                  .zero, // La Card a déjà ses propres marges visuelles, ou on gère via le padding parent
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Note :',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(compline.commentary!),
                  ],
                ),
              ),
            ),
          ),
        ],

        // --- INTRODUCTION ---
        SizedBox(height: spaceBetweenElements),
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
              SizedBox(height: spaceBetweenElements), // Marge de fin
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
        SizedBox(height: spaceBetweenElements * 2),
        LiturgyPartTitle(liturgyLabels['responsory']),
        LiturgyPartFormattedText(compline.responsory ?? '(texte introuvable)',
            includeVerseIdPlaceholder: false),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}

class _CanticleTab extends StatelessWidget {
  const _CanticleTab({required this.compline});
  final Compline compline;
  @override
  Widget build(BuildContext context) {
    final antiphon = compline.evangelicAntiphon?.common ?? '';
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      children: [
        CanticleWidget(antiphon1: antiphon, psalm: nuncDimittis),
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
        LiturgyPartFormattedText(
          compline.oration?.join("\n") ?? '',
          textAlign: TextAlign.justify,
          includeVerseIdPlaceholder: false, // AJOUT IMPORTANT
        ),
        SizedBox(height: spaceBetweenElements * 2),
        LiturgyPartTitle(liturgyLabels['blessing']),
        LiturgyPartFormattedText(
          fixedTexts['complineConclusion'],
          includeVerseIdPlaceholder: false, // AJOUT IMPORTANT
        ),
      ],
    );
  }
}
