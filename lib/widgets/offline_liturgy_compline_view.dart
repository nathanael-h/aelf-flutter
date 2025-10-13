import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/fixed_texts_library.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'offline_liturgy_hymn_selector.dart';
import '../app_screens/layout_config.dart';
import 'package:aelf_flutter/utils/text_management.dart';
import '../widgets/offline_liturgy_evangelic_canticle_display.dart';
import '../widgets/offline_liturgy_scripture_display.dart';
import '../widgets/offline_liturgy_psalms_display.dart';
import './liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content.dart';

class ComplineView extends StatelessWidget {
  const ComplineView({
    super.key,
    required this.compline,
  });

  final Compline compline;

  // Getters to clarify the logic
  bool get _hasTwoPsalms => compline.complinePsalm2?.isNotEmpty ?? false;
  int get _tabCount => _hasTwoPsalms ? 8 : 7;

  @override
  Widget build(BuildContext context) {
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
      color: Theme.of(context).primaryColor,
      child: TabBar(
        isScrollable: true,
        indicatorColor: Theme.of(context).tabBarTheme.labelColor,
        labelColor: Theme.of(context).tabBarTheme.labelColor,
        unselectedLabelColor:
            Theme.of(context).tabBarTheme.unselectedLabelColor,
        tabs: _buildTabs(),
      ),
    );
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[
      const Tab(text: 'Introduction'),
      const Tab(text: 'Hymnes'),
      Tab(text: psalms[compline.complinePsalm1]!.getTitle),
    ];

    if (_hasTwoPsalms) {
      tabs.add(Tab(text: psalms[compline.complinePsalm2]!.getTitle));
    }

    tabs.addAll(const [
      Tab(text: 'Lecture'),
      Tab(text: 'Cantique de Syméon'),
      Tab(text: 'Oraison'),
      Tab(text: 'Hymne mariale'),
    ]);

    return tabs;
  }

  Widget _buildTabBarView() {
    final views = <Widget>[
      _IntroductionTab(compline: compline),
      _HymnsTab(hymns: compline.complineHymns!.cast<String>()),
      _PsalmTab(
        psalmKey: compline.complinePsalm1,
        antiphon1: compline.complinePsalm1Antiphon,
        antiphon2: compline.complinePsalm1Antiphon2,
      ),
    ];

    if (_hasTwoPsalms) {
      views.add(_PsalmTab(
        psalmKey: compline.complinePsalm2,
        antiphon1: compline.complinePsalm2Antiphon,
        antiphon2: compline.complinePsalm2Antiphon2,
      ));
    }

    views.addAll([
      _ReadingTab(compline: compline),
      _CanticleTab(antiphon: compline.complineEvangelicAntiphon!),
      _OrationTab(compline: compline),
      _MarialHymnTab(hymns: compline.marialHymnRef!.cast<String>()),
    ]);

    return TabBarView(children: views);
  }
}

// ==================== SEPARATED WIDGETS ====================

/// Introduction Tab
class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({required this.compline});

  final Compline compline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        const LiturgyPartTitle('Introduction'),
        if (compline.complineCommentary != null)
          Text('Commentary: ${compline.complineCommentary}'),
        if (compline.celebrationType != null)
          Text('Celebration Type: ${compline.celebrationType ?? "-"}'),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartContent(fixedTexts['officeIntroduction']),
        SizedBox(height: spaceBetweenElements),
        Text(
          'On peut commencer par une révision de la journée, ou par un acte pénitentiel dans la célébration commune.',
          style: rubricStyle,
        ),
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
    return HymnSelectorWithTitle(
      title: 'Hymnes',
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
    return PsalmWidget(
      psalmKey: psalmKey,
      psalms: psalms,
      antiphon1: antiphon1,
      antiphon2: antiphon2,
    );
  }
}

/// Reading Tab
class _ReadingTab extends StatelessWidget {
  const _ReadingTab({required this.compline});

  final Compline compline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScriptureWidget(
          title: 'Parole de Dieu',
          reference: compline.complineReadingRef,
          content: compline.complineReading,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        const LiturgyPartTitle('Répons'),
        Html(data: correctAelfHTML(compline.complineResponsory!)),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}

/// Canticle of Simeon Tab
class _CanticleTab extends StatelessWidget {
  const _CanticleTab({required this.antiphon});

  final String antiphon;

  @override
  Widget build(BuildContext context) {
    return CanticleWidget(
      canticleType: 'nunc_dimittis',
      antiphon1: antiphon,
    );
  }
}

/// Oration Tab
class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.compline});

  final Compline compline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const LiturgyPartTitle('Oraison'),
        Text(
          '${compline.complineOration?.join("\n")}',
          style: psalmContentStyle,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        const LiturgyPartTitle('Bénédiction'),
        Html(data: correctAelfHTML(fixedTexts['complineConclusion']!)),
      ],
    );
  }
}

/// Marian Hymn Tab
class _MarialHymnTab extends StatelessWidget {
  const _MarialHymnTab({required this.hymns});

  final List<String> hymns;

  @override
  Widget build(BuildContext context) {
    return HymnSelectorWithTitle(
      title: 'Hymnes mariales',
      hymns: hymns,
    );
  }
}
