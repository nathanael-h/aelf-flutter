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
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';

class MorningView extends StatelessWidget {
  const MorningView({
    super.key,
    required this.morning,
  });

  final Morning morning;

  // Getters to clarify the logic
  int get _psalmCount => morning.psalmody?.length ?? 0;
  int get _tabCount => 5 + _psalmCount;

  @override
  Widget build(BuildContext context) {
    // Debug: afficher les données chargées
    print('=== MORNING VIEW DEBUG ===');
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
      const Tab(text: 'Introduction'),
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
      _IntroductionTab(morning: morning),
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

/// Introduction Tab with liturgical information
class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({required this.morning});

  final Morning morning;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['introduction'] ?? 'Introduction'),
        _buildFormattedText(fixedTexts['officeIntroduction']),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartRubric(
            'On peut commencer par une révision de la journée, ou par un acte pénitentiel dans la célébration commune'),
      ],
    );
  }

  Widget _buildFormattedText(String? content) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    // Wrap content in <p> if not already wrapped
    String htmlContent = content;
    if (!htmlContent.trim().startsWith('<p>')) {
      htmlContent = '<p>$htmlContent</p>';
    }

    final paragraphs = FormattedTextParser.parseHtml(htmlContent);

    return FormattedTextWidget(
      paragraphs: paragraphs,
      textStyle: const TextStyle(
        fontSize: 16.0,
        height: 1.3,
      ),
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
        _buildFormattedText(morning.responsory ?? 'Aucun répons disponible'),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }

  Widget _buildFormattedText(String? content) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    // Wrap content in <p> if not already wrapped
    String htmlContent = content;
    if (!htmlContent.trim().startsWith('<p>')) {
      htmlContent = '<p>$htmlContent</p>';
    }

    final paragraphs = FormattedTextParser.parseHtml(htmlContent);

    return FormattedTextWidget(
      paragraphs: paragraphs,
      textStyle: const TextStyle(
        fontSize: 16.0,
        height: 1.3,
      ),
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

    return CanticleWidget(
      canticleType: 'benedictus',
      antiphon1: antiphon,
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
        _buildFormattedText(
            morning.oration?.join("\n") ?? 'Aucune oraison disponible'),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'Bénédiction'),
        _buildFormattedText(fixedTexts['morningConclusion'] ??
            'Que le Seigneur nous bénisse, qu\'il nous garde de tout mal et nous conduise à la vie éternelle. Amen.'),
      ],
    );
  }

  Widget _buildFormattedText(String? content) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    // Wrap content in <p> if not already wrapped
    String htmlContent = content;
    if (!htmlContent.trim().startsWith('<p>')) {
      htmlContent = '<p>$htmlContent</p>';
    }

    final paragraphs = FormattedTextParser.parseHtml(htmlContent);

    return FormattedTextWidget(
      paragraphs: paragraphs,
      textStyle: const TextStyle(
        fontSize: 16.0,
        height: 1.3,
      ),
    );
  }
}
