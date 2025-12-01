import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/offices/compline.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_hymn_selector.dart';
import 'package:aelf_flutter/widgets/liturgy_info_widget.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_psalms_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';

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
  int get _psalmCount => currentCompline.psalmody?.length ?? 0;
  int get _tabCount => 6 + _psalmCount;

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
    ];

    // Add tabs for each psalm
    if (currentCompline.psalmody != null) {
      for (var psalmEntry in currentCompline.psalmody!) {
        // psalmEntry is now a PsalmEntry object
        final psalmKey = psalmEntry.psalm;
        tabs.add(Tab(text: psalms[psalmKey]!.getTitle));
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
      ),
      _HymnsTab(hymns: currentCompline.hymns ?? []),
    ];

    // Add views for each psalm
    if (currentCompline.psalmody != null) {
      for (var psalmEntry in currentCompline.psalmody!) {
        // psalmEntry is now a PsalmEntry object
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
      _ReadingTab(compline: currentCompline),
      _CanticleTab(compline: currentCompline),
      _OrationTab(compline: currentCompline),
      _MarialHymnTab(hymns: currentCompline.marialHymnRef ?? []),
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
                    child: Text(entry.value.complineDescription),
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
        ),

        // Commentary if present
        if (compline.commentary != null) ...[
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
                  Text(compline.commentary!),
                ],
              ),
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        LiturgyPartTitle(liturgyLabels['introduction']),
        _buildFormattedText(fixedTexts['officeIntroduction']),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartRubric(fixedTexts['complineIntroduction']),
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
    return HymnSelectorWithTitle(
      title: liturgyLabels['hymns']!,
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
  const _ReadingTab({required this.compline});

  final Compline compline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScriptureWidget(
          title: liturgyLabels['word_of_god']!,
          // reading is now a Reading object
          reference: compline.reading?.biblicalReference,
          content: compline.reading?.content,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['responsory']),
        _buildFormattedText(compline.responsory ?? '(texte introuvable)'),
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

/// Canticle of Simeon Tab
class _CanticleTab extends StatelessWidget {
  const _CanticleTab({required this.compline});

  final Compline compline;

  @override
  Widget build(BuildContext context) {
    // evangelicAntiphon is now an EvangelicAntiphon object
    // We use the common antiphon, or could implement year detection for yearA/B/C
    final antiphon = compline.evangelicAntiphon?.common ?? '';

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
        LiturgyPartTitle(liturgyLabels['oration']),
        _buildFormattedText(compline.oration?.join("\n") ?? ''),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['blessing']),
        _buildFormattedText(fixedTexts['complineConclusion']),
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

/// Marian Hymn Tab
class _MarialHymnTab extends StatelessWidget {
  const _MarialHymnTab({required this.hymns});

  final List<String> hymns;

  @override
  Widget build(BuildContext context) {
    return HymnSelectorWithTitle(
      title: liturgyLabels['marial_hymns']!,
      hymns: hymns,
    );
  }
}
