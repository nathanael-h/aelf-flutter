import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/fixed_texts_library.dart';
import 'package:offline_liturgy/assets/libraries/liturgy_labels.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/offices/compline.dart';
import 'offline_liturgy_hymn_selector.dart';
import 'liturgy_info_widget.dart';
import '../app_screens/layout_config.dart';
import 'package:aelf_flutter/utils/text_management.dart';
import '../widgets/offline_liturgy_evangelic_canticle_display.dart';
import '../widgets/offline_liturgy_scripture_display.dart';
import '../widgets/offline_liturgy_psalms_display.dart';
import './liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content.dart';

class ComplineView extends StatefulWidget {
  const ComplineView({
    super.key,
    required this.complineDefinitionsList,
  });

  final Map<String, ComplineDefinition> complineDefinitionsList;

  @override
  State<ComplineView> createState() => _ComplineViewState();
}

class _ComplineViewState extends State<ComplineView> {
  String? selectedComplineKey; // Changed from int to String to use the key
  late Compline currentCompline;

  @override
  void initState() {
    super.initState();
    // Initialize with the first available key
    selectedComplineKey = widget.complineDefinitionsList.keys.first;
    _updateCompline();
  }

  @override
  void didUpdateWidget(ComplineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when the list of Complines changes (e.g., when date changes)
    if (oldWidget.complineDefinitionsList != widget.complineDefinitionsList) {
      selectedComplineKey = widget.complineDefinitionsList.keys.first;
      _updateCompline();
    }
  }

  void _updateCompline() {
    // Compile the text of the selected Compline
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
      });
    }
  }

  // Getters to clarify the logic
  bool get _hasTwoPsalms => currentCompline.complinePsalm2?.isNotEmpty ?? false;
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
      width: MediaQuery.of(context).size.width,
      color: Theme.of(context).primaryColor,
      child: Center(
        child: TabBar(
          isScrollable: true,
          indicatorColor: Theme.of(context).tabBarTheme.labelColor,
          labelColor: Theme.of(context).tabBarTheme.labelColor,
          unselectedLabelColor:
              Theme.of(context).tabBarTheme.unselectedLabelColor,
          tabs: _buildTabs(),
        ),
      ),
    );
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[
      const Tab(text: 'Introduction'),
      const Tab(text: 'Hymnes'),
      Tab(text: psalms[currentCompline.complinePsalm1]!.getTitle),
    ];

    if (_hasTwoPsalms) {
      tabs.add(Tab(text: psalms[currentCompline.complinePsalm2]!.getTitle));
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
      _IntroductionTab(
        compline: currentCompline,
        complineDefinitionsList: widget.complineDefinitionsList,
        selectedKey: selectedComplineKey!,
        onComplineChanged: _onComplineChanged,
      ),
      _HymnsTab(hymns: currentCompline.complineHymns!.cast<String>()),
      _PsalmTab(
        psalmKey: currentCompline.complinePsalm1,
        antiphon1: currentCompline.complinePsalm1Antiphon,
        antiphon2: currentCompline.complinePsalm1Antiphon2,
      ),
    ];

    if (_hasTwoPsalms) {
      views.add(_PsalmTab(
        psalmKey: currentCompline.complinePsalm2,
        antiphon1: currentCompline.complinePsalm2Antiphon,
        antiphon2: currentCompline.complinePsalm2Antiphon2,
      ));
    }

    views.addAll([
      _ReadingTab(compline: currentCompline),
      _CanticleTab(antiphon: currentCompline.complineEvangelicAntiphon!),
      _OrationTab(compline: currentCompline),
      _MarialHymnTab(hymns: currentCompline.marialHymnRef!.cast<String>()),
    ]);

    return TabBarView(children: views);
  }
}

// ==================== SEPARATED WIDGETS ====================

/// Introduction Tab with Compline selector and liturgical information
class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.compline,
    required this.complineDefinitionsList,
    required this.selectedKey,
    required this.onComplineChanged,
  });

  final Compline compline;
  final Map<String, ComplineDefinition> complineDefinitionsList;
  final String selectedKey;
  final ValueChanged<String?> onComplineChanged;

  String _getComplineName(String key, ComplineDefinition definition) {
    final name = celebrationNameLabels[key] ?? key;

    switch (definition.celebrationType) {
      case 'SolemnityEve':
        return 'Veille de $name';
      case 'SundayEve':
        return 'Veille du dimanche';
      case 'Solemnity':
        return name; // Just the name for solemnities
      case 'Sunday':
        return name; // Just the name for Sundays
      case 'normal':
        // For normal days, check if the key is a weekday name
        if ([
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday'
        ].contains(key.toLowerCase())) {
          return 'Complies du $name';
        }
        return name;
      default:
        return name; // Default: use the key name
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDropdown = complineDefinitionsList.length > 1;
    final complineDefinition = complineDefinitionsList[selectedKey]!;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        // Dropdown to select Compline if multiple options available
        if (showDropdown) ...[
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
                    child: Text(_getComplineName(entry.key, entry.value)),
                  );
                }).toList(),
                onChanged: onComplineChanged,
              ),
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],
        // Liturgical information about the celebrated Compline
        LiturgyInfoWidget(
          complineDefinition: complineDefinition,
          celebrationName: selectedKey,
        ),

        // Commentary if present
        if (compline.complineCommentary != null) ...[
          Card(
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
                  Text(compline.complineCommentary!),
                ],
              ),
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        const LiturgyPartTitle('Introduction'),
        LiturgyPartContent(fixedTexts['officeIntroduction']),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartRubric(
            'On peut commencer par une révision de la journée, ou par un acte pénitentiel dans la célébration commune.'),
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
