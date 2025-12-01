import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/classes/morning_class.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_hymn_selector.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_psalms_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/utils/text_formatting_helper.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_antiphon_display.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';

class MorningView extends StatelessWidget {
  const MorningView({
    super.key,
    required this.morning,
  });

  final Morning morning;

  // Getters to clarify the logic
  int get _psalmCount => morning.psalmody?.length ?? 0;
  int get _tabCount => 5 + _psalmCount; // Invitatory replaces Introduction

  @override
  Widget build(BuildContext context) {
    // Debug: afficher les données chargées
    print('=== MORNING VIEW DEBUG ===');
    print('Has hymn list: ${morning.hymn != null}');
    print('Has psalmody: ${morning.psalmody != null}');
    print('Psalmody count: ${morning.psalmody?.length ?? 0}');
    print('Has reading: ${morning.reading != null}');
    print('Has hymn: ${morning.hymn != null}');
    print('Has oration: ${morning.oration != null}');
    print('Has evangelicAntiphon: ${morning.evangelicAntiphon != null}');

    // Vérifier si le Morning est vide
    if (morning.psalmody == null &&
        morning.reading == null &&
        morning.oration == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Données de l\'office non disponibles',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Vérifiez que le fichier JSON existe',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
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
      Tab(text: liturgyLabels['invitatory'] ?? 'Invitatoire'),
      Tab(text: liturgyLabels['hymns'] ?? 'Hymnes'),
    ];

    // Add tabs for each psalm
    if (morning.psalmody != null) {
      for (var psalmEntry in morning.psalmody!) {
        final psalmKey = psalmEntry.psalm;
        if (psalms.containsKey(psalmKey)) {
          tabs.add(Tab(text: psalms[psalmKey]!.getTitle));
        }
      }
    }

    tabs.addAll([
      Tab(text: liturgyLabels['reading'] ?? 'Lecture'),
      Tab(text: liturgyLabels['zachary_canticle'] ?? 'Cantique de Zacharie'),
      Tab(text: liturgyLabels['oration'] ?? 'Oraison'),
    ]);

    return tabs;
  }

  Widget _buildTabBarView() {
    final views = <Widget>[
      _InvitatoryTab(morning: morning),
      _HymnsTab(hymns: morning.hymn ?? []),
    ];

    // Add views for each psalm
    if (morning.psalmody != null) {
      for (var psalmEntry in morning.psalmody!) {
        final psalmKey = psalmEntry.psalm;
        final antiphons = psalmEntry.antiphon ?? [];

        views.add(_PsalmTab(
          psalmKey: psalmKey,
          antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
          antiphon2: antiphons.length > 1 ? antiphons[1] : null,
        ));
      }
    }

    views.addAll([
      _ReadingTab(morning: morning),
      _CanticleTab(morning: morning),
      _OrationTab(morning: morning),
    ]);

    return TabBarView(children: views);
  }
}

// ==================== SEPARATED WIDGETS ====================

/// Invitatory Tab with psalm selector and antiphons
class _InvitatoryTab extends StatefulWidget {
  const _InvitatoryTab({required this.morning});

  final Morning morning;

  @override
  State<_InvitatoryTab> createState() => _InvitatoryTabState();
}

class _InvitatoryTabState extends State<_InvitatoryTab> {
  String? selectedPsalmKey;

  @override
  void initState() {
    super.initState();
    // Select the first psalm if available
    if (widget.morning.invitatory?.psalms != null &&
        widget.morning.invitatory!.psalms!.isNotEmpty) {
      selectedPsalmKey = widget.morning.invitatory!.psalms!.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitatory = widget.morning.invitatory;

    // Check if invitatory exists
    if (invitatory == null) {
      return const Center(child: Text('Aucun invitatoire disponible'));
    }

    final List<String> psalmsList = (invitatory.psalms ?? []).cast<String>();
    final List<String> antiphons = (invitatory.antiphon ?? []).cast<String>();

    if (psalmsList.isEmpty) {
      return const Center(child: Text('Aucun psaume disponible'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // === INTRODUCTION CONTENT (moved from Introduction tab) ===
        LiturgyPartTitle(liturgyLabels['introduction'] ?? 'Introduction'),
        buildFormattedText(fixedTexts['officeIntroduction']),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),

        // === INVITATORY CONTENT ===
        // Title
        LiturgyPartTitle(liturgyLabels['invitatory'] ?? 'Invitatoire'),
        const SizedBox(height: 16),

        // Antiphons BEFORE the psalm selector
        if (antiphons.isNotEmpty) ...[
          AntiphonWidget(
            antiphon1: antiphons[0],
            antiphon2: antiphons.length > 1 ? antiphons[1] : null,
            antiphon3: antiphons.length > 2 ? antiphons[2] : null,
          ),
          const SizedBox(height: 16),
        ],

        // Psalm Selector
        DropdownButton<String>(
          value: selectedPsalmKey,
          hint: const Text('Sélectionner un psaume'),
          isExpanded: true,
          items: psalmsList.map((String psalmKey) {
            final psalm = psalms[psalmKey];
            return DropdownMenuItem<String>(
              value: psalmKey,
              child: Text(
                psalm?.getTitle ?? 'Psaume introuvable: $psalmKey',
              ),
            );
          }).toList(),
          onChanged: (String? newKey) {
            setState(() {
              selectedPsalmKey = newKey;
            });
          },
        ),
        const SizedBox(height: 20),

        // Display selected psalm
        if (selectedPsalmKey != null && psalms.containsKey(selectedPsalmKey))
          _buildPsalm(selectedPsalmKey!),
      ],
    );
  }

  Widget _buildPsalm(String psalmKey) {
    final psalm = psalms[psalmKey];
    if (psalm == null) {
      return const Text('Psaume introuvable');
    }

    final invitatory = widget.morning.invitatory;
    final List<String> antiphons = (invitatory?.antiphon ?? []).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Psalm content with verse numbers
        PsalmFromHtml(htmlContent: psalm.getContent),

        // Antiphons AFTER the psalm
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
}

/// Hymns Tab
class _HymnsTab extends StatelessWidget {
  const _HymnsTab({required this.hymns});

  final List<String> hymns;

  @override
  Widget build(BuildContext context) {
    if (hymns.isEmpty) {
      return const Center(child: Text('Aucune hymne disponible'));
    }
    return HymnSelectorWithTitle(
      title: liturgyLabels['hymns'] ?? 'Hymnes',
      hymns: hymns,
    );
  }
}

/// Psalm Tab
class _PsalmTab extends StatelessWidget {
  const _PsalmTab({
    required this.psalmKey,
    this.antiphon1,
    this.antiphon2,
  });

  final String? psalmKey;
  final String? antiphon1;
  final String? antiphon2;

  @override
  Widget build(BuildContext context) {
    return PsalmDisplayWidget(
      psalmKey: psalmKey,
      psalms: psalms,
      antiphon1: antiphon1,
      antiphon2: antiphon2,
    );
  }
}

/// Reading Tab
class _ReadingTab extends StatelessWidget {
  const _ReadingTab({required this.morning});

  final Morning morning;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScriptureWidget(
          title: liturgyLabels['word_of_god'] ?? 'Parole de Dieu',
          reference: morning.reading?.biblicalReference,
          content: morning.reading?.content,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
        buildFormattedText(morning.responsory ?? 'Aucun répons disponible'),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}

/// Canticle of Zachary Tab
class _CanticleTab extends StatelessWidget {
  const _CanticleTab({required this.morning});

  final Morning morning;

  @override
  Widget build(BuildContext context) {
    // evangelicAntiphon is now an EvangelicAntiphon object
    // We use the common antiphon, or could implement year detection for yearA/B/C
    final antiphon = morning.evangelicAntiphon?.common;

    if (antiphon == null) {
      return const Center(child: Text('Aucune antienne disponible'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CanticleWidget(
        canticleType: 'benedictus',
        antiphon1: antiphon,
      ),
    );
  }
}

/// Oration Tab
class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.morning});

  final Morning morning;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        buildFormattedText(
            morning.oration?.join("\n") ?? 'Aucune oraison disponible',
            textAlign: TextAlign.justify),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'Bénédiction'),
        buildFormattedText(fixedTexts['morningConclusion'] ??
            'Que le Seigneur nous bénisse, qu\'il nous garde de tout mal et nous conduise à la vie éternelle. Amen.'),
      ],
    );
  }
}
