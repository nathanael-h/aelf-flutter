import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Readings View
///
/// Architecture:
/// 1. ReadingsView (StatefulWidget) - Manages UI state and data resolution
/// 2. ReadingsOfficeDisplay (StatelessWidget) - Pure display widget
class ReadingsView extends StatefulWidget {
  const ReadingsView({
    super.key,
    required this.readingsDefinitions,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, CelebrationContext> readingsDefinitions;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  State<ReadingsView> createState() => _ReadingsViewState();
}

class _ReadingsViewState extends State<ReadingsView> {
  bool _isLoading = true;
  String? _celebrationKey;
  CelebrationContext? _selectedDefinition;
  Readings? _readingsData;
  String? _selectedCommon;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  @override
  void didUpdateWidget(ReadingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.readingsDefinitions != widget.readingsDefinitions) {
      _loadReadings();
    }
  }

  /// Single method to load everything
  Future<void> _loadReadings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Find first celebrable option
      final firstOption = widget.readingsDefinitions.entries
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

      // Step 2: Determine auto common
      String? autoCommon;
      final commonList = _selectedDefinition!.commonList;
      if (commonList != null && commonList.isNotEmpty) {
        if (_selectedDefinition!.celebrationCode !=
            _selectedDefinition!.ferialCode) {
          autoCommon = commonList.first;
        }
      }
      _selectedCommon = autoCommon;

      // Step 3: Resolve readings
      final celebrationContext = _selectedDefinition!.copyWith(
        commonList: autoCommon != null ? [autoCommon] : null,
      );
      final readingsData = await readingsResolution(celebrationContext);

      if (mounted) {
        setState(() {
          _readingsData = readingsData;
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

  /// Handle user changing celebration
  Future<void> _onCelebrationChanged(String key) async {
    final definition = widget.readingsDefinitions[key];
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
        commonList: autoCommon != null ? [autoCommon] : null,
      );
      final readingsData = await readingsResolution(celebrationContext);

      if (mounted) {
        setState(() {
          _celebrationKey = key;
          _selectedDefinition = definition;
          _selectedCommon = autoCommon;
          _readingsData = readingsData;
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

  /// Handle user changing common
  Future<void> _onCommonChanged(String? common) async {
    if (_selectedDefinition == null) return;

    setState(() => _isLoading = true);

    try {
      final celebrationContext = _selectedDefinition!.copyWith(
        commonList: common != null ? [common] : null,
      );
      final readingsData = await readingsResolution(celebrationContext);

      if (mounted) {
        setState(() {
          _selectedCommon = common;
          _readingsData = readingsData;
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
            ElevatedButton(
              onPressed: _loadReadings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_celebrationKey != null &&
        _selectedDefinition != null &&
        _readingsData != null) {
      return ReadingsOfficeDisplay(
        celebrationKey: _celebrationKey!,
        readingsDefinition: _selectedDefinition!,
        readingsData: _readingsData!,
        selectedCommon: _selectedCommon,
        dataLoader: widget.dataLoader,
        readingsDefinitions: widget.readingsDefinitions,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
      );
    }

    return const Center(child: Text('No data available'));
  }
}

/// Pure display widget for Readings Office
class ReadingsOfficeDisplay extends StatelessWidget {
  const ReadingsOfficeDisplay({
    super.key,
    required this.celebrationKey,
    required this.readingsDefinition,
    required this.readingsData,
    required this.selectedCommon,
    required this.dataLoader,
    required this.readingsDefinitions,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final CelebrationContext readingsDefinition;
  final Readings readingsData;
  final String? selectedCommon;
  final DataLoader dataLoader;
  final Map<String, CelebrationContext> readingsDefinitions;
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
    return 2 // Intro + Hymne
        +
        (readingsData.psalmody?.length ?? 0) +
        1 // Biblical
        +
        1 // Patristic
        +
        (readingsData.tedeum == true ? 1 : 0) +
        1; // Oration
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

    if (readingsData.psalmody != null) {
      for (var psalmEntry in readingsData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final tabText =
            getPsalmDisplayTitle(psalmEntry.psalmData, psalmEntry.psalm!);
        tabs.add(Tab(text: tabText));
      }
    }

    tabs.addAll([
      const Tab(text: 'Lecture biblique'),
      const Tab(text: 'Lecture patristique'),
    ]);

    if (readingsData.tedeum == true) {
      tabs.add(const Tab(text: 'Te Deum'));
    }

    tabs.add(const Tab(text: 'Oraison'));

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[
      _IntroductionTab(
        celebrationKey: celebrationKey,
        readingsDefinition: readingsDefinition,
        readingsDefinitions: readingsDefinitions,
        selectedCommon: selectedCommon,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
      ),
      HymnsTabWidget(
        hymns: readingsData.hymn ?? [],
        emptyMessage: 'Aucune hymne disponible',
      ),
    ];

    if (readingsData.psalmody != null) {
      int psalmIndex = 0;
      for (var psalmEntry in readingsData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final antiphons = psalmEntry.antiphon ?? [];

        views.add(PsalmTabWidget(
          psalm: psalmEntry.psalmData,
          antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
          antiphon2: antiphons.length > 1 ? antiphons[1] : null,
          verseAfter: psalmIndex == 2 ? readingsData.verse : null,
        ));
        psalmIndex++;
      }
    }

    views.addAll([
      _BiblicalReadingTab(readingsData: readingsData),
      _PatristicReadingTab(readingsData: readingsData),
    ]);

    if (readingsData.tedeum == true) {
      views.add(_TeDeumTab(readingsData: readingsData));
    }

    views.add(_OrationTab(readingsData: readingsData));

    return views;
  }
}

/// Introduction tab
class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.celebrationKey,
    required this.readingsDefinition,
    required this.readingsDefinitions,
    required this.selectedCommon,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final CelebrationContext readingsDefinition;
  final Map<String, CelebrationContext> readingsDefinitions;
  final String? selectedCommon;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // Office title
        Text(
          readingsDefinition.officeDescription ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Liturgical color bar
        Container(
          width: double.infinity,
          height: 6,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color:
                getLiturgicalColor(readingsDefinition.liturgicalColor),
            borderRadius: BorderRadius.circular(3),
          ),
        ),

        // Precedence level
        Text(
          getCelebrationTypeLabel(readingsDefinition.precedence ?? 13),
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Description
        if (readingsDefinition.celebrationDescription != null &&
            readingsDefinition.celebrationDescription!.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              readingsDefinition.celebrationDescription!,
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
          _buildSectionTitle('Sélectionner l\'office des Lectures'),
          CelebrationChipsSelector(
            celebrationMap: readingsDefinitions,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        if (_needsCommonSelection()) ...[
          if ((readingsDefinition.commonList?.length ?? 0) > 1 ||
              (readingsDefinition.precedence ?? 13) > 8)
            _buildSectionTitle('Sélectionner un commun'),
          CommonChipsSelector(
            commonList: readingsDefinition.commonList ?? [],
            commonTitles: readingsDefinition.commonTitles,
            selectedCommon: selectedCommon,
            precedence: readingsDefinition.precedence ?? 13,
            onCommonChanged: onCommonChanged,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Introduction
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiturgyPartTitle(liturgyLabels['introduction'] ?? 'Introduction'),
              LiturgyPartFormattedText(
                fixedTexts['officeIntroduction'] ?? 'officeIntroduction',
                includeVerseIdPlaceholder: false,
              ),
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
    return readingsDefinitions.values
            .where((d) => d.isCelebrable)
            .length >
        1;
  }

  bool _needsCommonSelection() {
    final commonList = readingsDefinition.commonList;
    final liturgicalTime = readingsDefinition.liturgicalTime;

    if (commonList == null || commonList.isEmpty) return false;
    if (liturgicalTime == 'paschaloctave' ||
        liturgicalTime == 'christmasoctave') {
      return false;
    }
    if (readingsDefinition.celebrationCode == readingsDefinition.ferialCode) {
      return false;
    }

    return true;
  }
}

// Les autres widgets (_BiblicalReadingTab, _PatristicReadingTab, _TeDeumTab, _OrationTab)
// restent inchangés par rapport à votre code original (stateless et propres).
// Je ne les répète pas ici pour la brièveté, mais ils doivent être inclus dans le fichier final.
class _BiblicalReadingTab extends StatelessWidget {
  const _BiblicalReadingTab({required this.readingsData});
  final Readings readingsData;
  @override
  Widget build(BuildContext context) {
    // ... contenu existant ...
    // (Copier le contenu de votre fichier original)
    final biblicalReadings = readingsData.biblicalReading;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(
            liturgyLabels['biblical_reading'] ?? 'Lecture biblique'),
        const SizedBox(height: 16),
        if (biblicalReadings != null) ...[
          for (var i = 0; i < biblicalReadings.length; i++) ...[
            if (i > 0) SizedBox(height: spaceBetweenElements * 2),
            _buildBiblicalReading(biblicalReadings[i]),
          ]
        ] else
          const Text('Aucune lecture biblique'),
      ],
    );
  }

  Widget _buildBiblicalReading(BiblicalReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reading.title != null)
          Text(reading.title!,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (reading.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(reading.subtitle!,
              style:
                  const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
        ],
        if (reading.ref != null) ...[
          const SizedBox(height: 4),
          Text(reading.ref!,
              style:
                  const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
        ],
        if (reading.content != null) ...[
          SizedBox(height: spaceBetweenElements),
          LiturgyPartFormattedText(reading.content!,
              includeVerseIdPlaceholder: false, textAlign: TextAlign.justify),
        ],
        if (reading.responsory != null) ...[
          SizedBox(height: spaceBetweenElements * 2),
          LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
          LiturgyPartFormattedText(reading.responsory!,
              includeVerseIdPlaceholder: false),
        ],
      ],
    );
  }
}

// Idem pour _PatristicReadingTab, _TeDeumTab, _OrationTab
class _PatristicReadingTab extends StatelessWidget {
  const _PatristicReadingTab({required this.readingsData});
  final Readings readingsData;
  @override
  Widget build(BuildContext context) {
    final patristicReadings = readingsData.patristicReading;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(
            liturgyLabels['patristic_reading'] ?? 'Lecture patristique'),
        const SizedBox(height: 16),
        if (patristicReadings != null) ...[
          for (var i = 0; i < patristicReadings.length; i++) ...[
            if (i > 0) SizedBox(height: spaceBetweenElements * 2),
            _buildPatristicReading(patristicReadings[i]),
          ]
        ] else
          const Text('Aucune lecture patristique'),
      ],
    );
  }

  Widget _buildPatristicReading(PatristicReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reading.title != null)
          Text(reading.title!,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (reading.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(reading.subtitle!,
              style:
                  const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
        ],
        if (reading.content != null) ...[
          SizedBox(height: spaceBetweenElements),
          LiturgyPartFormattedText(reading.content!,
              includeVerseIdPlaceholder: false, textAlign: TextAlign.justify),
        ],
        if (reading.responsory != null) ...[
          SizedBox(height: spaceBetweenElements * 2),
          LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
          LiturgyPartFormattedText(reading.responsory!,
              includeVerseIdPlaceholder: false),
        ],
      ],
    );
  }
}

class _TeDeumTab extends StatelessWidget {
  const _TeDeumTab({required this.readingsData});
  final Readings readingsData;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['te_deum'] ?? 'Te Deum'),
        if (readingsData.tedeumContent != null) ...[
          SizedBox(height: spaceBetweenElements),
          LiturgyPartFormattedText(readingsData.tedeumContent!,
              includeVerseIdPlaceholder: false),
        ] else
          const Text('Te Deum non disponible'),
      ],
    );
  }
}

class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.readingsData});
  final Readings readingsData;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartFormattedText(
          readingsData.oration?.join("\n") ?? 'Aucune oraison disponible',
          textAlign: TextAlign.justify,
          includeVerseIdPlaceholder: false,
        ),
      ],
    );
  }
}
