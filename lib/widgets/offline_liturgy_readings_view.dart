import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/readings_class.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/tools/date_tools.dart';
import 'package:offline_liturgy/offices/readings/readings.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:yaml/yaml.dart';

/// Simple Readings View - loads and resolves office from definitions map
class ReadingsSimpleView extends StatefulWidget {
  const ReadingsSimpleView({
    super.key,
    required this.readingsDefinitions,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, ReadingsDefinition> readingsDefinitions;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  State<ReadingsSimpleView> createState() => _ReadingsSimpleViewState();
}

class _ReadingsSimpleViewState extends State<ReadingsSimpleView> {
  bool _isLoading = true;
  String? _celebrationKey;
  ReadingsDefinition? _selectedDefinition;
  Readings? _readingsData;
  String? _selectedCommon;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  @override
  void didUpdateWidget(ReadingsSimpleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.readingsDefinitions != widget.readingsDefinitions) {
      _loadReadings();
    }
  }

  Future<void> _loadReadings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get first celebrable option
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

      // Determine auto common (first common if available)
      String? autoCommon;
      final commonList = _selectedDefinition!.commonList;
      if (commonList != null && commonList.isNotEmpty) {
        // Don't auto-select for ferial celebrations
        if (_selectedDefinition!.celebrationCode != _selectedDefinition!.ferialCode) {
          autoCommon = commonList.first;
        }
      }
      _selectedCommon = autoCommon;

      // Resolve readings office
      final readingsData = await readingsResolution(
        _selectedDefinition!.celebrationCode,
        _selectedDefinition!.ferialCode,
        autoCommon,
        widget.date,
        _selectedDefinition!.breviaryWeek,
        widget.dataLoader,
        precedence: _selectedDefinition!.precedence,
        teDeum: _selectedDefinition!.teDeum,
      );

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
      // Determine auto common
      String? autoCommon;
      final commonList = definition.commonList;
      if (commonList != null && commonList.isNotEmpty) {
        if (definition.celebrationCode != definition.ferialCode) {
          autoCommon = commonList.first;
        }
      }

      final readingsData = await readingsResolution(
        definition.celebrationCode,
        definition.ferialCode,
        autoCommon,
        widget.date,
        definition.breviaryWeek,
        widget.dataLoader,
        precedence: definition.precedence,
        teDeum: definition.teDeum,
      );

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
      final readingsData = await readingsResolution(
        _selectedDefinition!.celebrationCode,
        _selectedDefinition!.ferialCode,
        common,
        widget.date,
        _selectedDefinition!.breviaryWeek,
        widget.dataLoader,
        precedence: _selectedDefinition!.precedence,
        teDeum: _selectedDefinition!.teDeum,
      );

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

    if (_celebrationKey != null && _selectedDefinition != null && _readingsData != null) {
      return ReadingsView(
        celebrationKey: _celebrationKey!,
        readingsDefinition: _selectedDefinition!,
        readingsData: _readingsData!,
        selectedCommon: _selectedCommon,
        date: widget.date,
        dataLoader: widget.dataLoader,
        readingsDefinitions: widget.readingsDefinitions,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
      );
    }

    return const Center(child: Text('No data available'));
  }
}

/// Readings View (Office des Lectures)
///
/// Displays the Office of Readings with tabs for:
/// - Introduction
/// - Hymn
/// - 3 Psalm tabs
/// - Biblical Reading (with responsory)
/// - Patristic Reading (with responsory)
/// - Te Deum (if tedeum is true)
/// - Oration
class ReadingsView extends StatefulWidget {
  const ReadingsView({
    super.key,
    required this.celebrationKey,
    required this.readingsDefinition,
    required this.readingsData,
    required this.selectedCommon,
    required this.date,
    required this.dataLoader,
    required this.readingsDefinitions,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final ReadingsDefinition readingsDefinition;
  final Readings readingsData;
  final String? selectedCommon;
  final DateTime date;
  final DataLoader dataLoader;
  final Map<String, ReadingsDefinition> readingsDefinitions;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  @override
  State<ReadingsView> createState() => _ReadingsViewState();
}

class _ReadingsViewState extends State<ReadingsView> {
  bool _isLoading = true;
  Map<String, dynamic> _psalmsCache = {};

  @override
  void initState() {
    super.initState();
    _loadPsalms();
  }

  Future<void> _loadPsalms() async {
    setState(() => _isLoading = true);

    try {
      final allPsalmCodes = <String>[];

      if (widget.readingsData.psalmody != null) {
        for (var entry in widget.readingsData.psalmody!) {
          if (entry.psalm != null) {
            allPsalmCodes.add(entry.psalm!);
          }
        }
      }

      final psalmsCache = allPsalmCodes.isNotEmpty
          ? await PsalmsLibrary.getPsalms(allPsalmCodes, widget.dataLoader)
          : <String, dynamic>{};

      if (mounted) {
        setState(() {
          _psalmsCache = psalmsCache;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ReadingsOfficeDisplay(
      celebrationKey: widget.celebrationKey,
      readingsDefinition: widget.readingsDefinition,
      readingsData: widget.readingsData,
      selectedCommon: widget.selectedCommon,
      psalmsCache: _psalmsCache,
      dataLoader: widget.dataLoader,
      readingsDefinitions: widget.readingsDefinitions,
      onCelebrationChanged: widget.onCelebrationChanged,
      onCommonChanged: widget.onCommonChanged,
    );
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
    required this.psalmsCache,
    required this.dataLoader,
    required this.readingsDefinitions,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final ReadingsDefinition readingsDefinition;
  final Readings readingsData;
  final String? selectedCommon;
  final Map<String, dynamic> psalmsCache;
  final DataLoader dataLoader;
  final Map<String, ReadingsDefinition> readingsDefinitions;
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
    int count = 2; // Introduction + Hymn
    count += (readingsData.psalmody?.length ?? 0); // Psalms
    count += 1; // Biblical Reading
    count += 1; // Patristic Reading
    if (readingsData.tedeum == true) count += 1; // Te Deum
    count += 1; // Oration
    return count;
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

    // Add psalm tabs
    if (readingsData.psalmody != null) {
      for (var psalmEntry in readingsData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final psalmKey = psalmEntry.psalm!;
        final psalm = psalmsCache[psalmKey];
        final tabText = getPsalmDisplayTitle(psalm, psalmKey);
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
        readingsData: readingsData,
        selectedCommon: selectedCommon,
        readingsDefinitions: readingsDefinitions,
        dataLoader: dataLoader,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
      ),
      HymnsTabWidget(
        hymns: readingsData.hymn ?? [],
        dataLoader: dataLoader,
        emptyMessage: 'Aucune hymne disponible',
      ),
    ];

    // Add psalm tabs dynamically
    if (readingsData.psalmody != null) {
      int psalmIndex = 0;
      for (var psalmEntry in readingsData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final psalmKey = psalmEntry.psalm!;
        final antiphons = psalmEntry.antiphon ?? [];

        views.add(PsalmTabWidget(
          psalmKey: psalmKey,
          psalmsCache: psalmsCache,
          dataLoader: dataLoader,
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
      views.add(_TeDeumTab(dataLoader: dataLoader));
    }

    views.add(_OrationTab(readingsData: readingsData));

    return views;
  }
}

/// Introduction tab
class _IntroductionTab extends StatefulWidget {
  const _IntroductionTab({
    required this.celebrationKey,
    required this.readingsDefinition,
    required this.readingsData,
    required this.selectedCommon,
    required this.readingsDefinitions,
    required this.dataLoader,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final ReadingsDefinition readingsDefinition;
  final Readings readingsData;
  final String? selectedCommon;
  final Map<String, ReadingsDefinition> readingsDefinitions;
  final DataLoader dataLoader;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  @override
  State<_IntroductionTab> createState() => _IntroductionTabState();
}

class _IntroductionTabState extends State<_IntroductionTab> {
  Map<String, String> commonTitles = {}; // code -> title
  bool isLoadingTitles = true;

  @override
  void initState() {
    super.initState();
    _loadCommonTitles();
  }

  Future<void> _loadCommonTitles() async {
    final commonList = widget.readingsDefinition.commonList;
    if (commonList == null || commonList.isEmpty) {
      setState(() => isLoadingTitles = false);
      return;
    }

    final titles = <String, String>{};
    for (final commonCode in commonList) {
      try {
        final filePath = 'calendar_data/commons/$commonCode.yaml';
        final fileContent = await widget.dataLoader.loadYaml(filePath);

        if (fileContent.isNotEmpty) {
          final yamlData = loadYaml(fileContent);
          final data = _convertYamlToDart(yamlData);
          final commonTitle = data['commonTitle'] as String?;
          titles[commonCode] = commonTitle ?? commonCode;
        } else {
          titles[commonCode] = commonCode;
        }
      } catch (e) {
        titles[commonCode] = commonCode; // Fallback to code if error
      }
    }

    if (mounted) {
      setState(() {
        commonTitles = titles;
        isLoadingTitles = false;
      });
    }
  }

  /// Recursively converts YamlMap/YamlList to Map<String, dynamic>/List<dynamic>
  dynamic _convertYamlToDart(dynamic value) {
    if (value is YamlMap) {
      return value
          .map((key, val) => MapEntry(key.toString(), _convertYamlToDart(val)));
    } else if (value is YamlList) {
      return value.map((item) => _convertYamlToDart(item)).toList();
    } else {
      return value;
    }
  }

  bool _hasMultipleCelebrations() {
    return widget.readingsDefinitions.values.where((d) => d.isCelebrable).length > 1;
  }

  bool _needsCommonSelection() {
    final definition = widget.readingsDefinition;
    final commonList = definition.commonList;
    final liturgicalTime = definition.liturgicalTime;

    // Don't show selector if no commons available
    if (commonList == null || commonList.isEmpty) {
      return false;
    }

    // Don't show selector during octaves (paschaloctave, christmasoctave)
    if (liturgicalTime == 'paschaloctave' ||
        liturgicalTime == 'christmasoctave') {
      return false;
    }

    // For ferial celebrations (celebrationCode == ferialCode), don't show common selector
    if (definition.celebrationCode == definition.ferialCode) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // Office title
        Text(
          widget.readingsDefinition.readingsDescription,
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
            color: getLiturgicalColor(widget.readingsDefinition.liturgicalColor),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),

        // Precedence level
        Text(
          getCelebrationTypeLabel(widget.readingsDefinition.precedence),
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Description (if exists)
        if (widget.readingsDefinition.celebrationDescription != null &&
            widget.readingsDefinition.celebrationDescription!.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.readingsDefinition.celebrationDescription!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Celebration selector (if multiple options)
        if (_hasMultipleCelebrations()) ...[
          const Text(
            'Sélectionner l\'office des Lectures',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Color(0xFFEFE3CE),
            ),
            child: DropdownButton<String>(
              value: widget.celebrationKey,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.red),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              dropdownColor: Color(0xFFEFE3CE),
              items: widget.readingsDefinitions.entries
                  .where((e) => e.value.isCelebrable)
                  .map((entry) {
                final liturgicalColor = entry.value.liturgicalColor;
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: getLiturgicalColor(liturgicalColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${entry.value.readingsDescription} ${getCelebrationTypeLabel(entry.value.precedence)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) widget.onCelebrationChanged(value);
              },
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Common selector (if needed)
        if (_needsCommonSelection()) ...[
          const Text(
            'Sélectionner un commun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Color(0xFFEFE3CE),
            ),
            child: DropdownButton<String?>(
              value: widget.selectedCommon,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.red),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              dropdownColor: Color(0xFFEFE3CE),
              hint: const Text('Choisir un commun',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              items: [
                // "Pas de commun" option only for optional commons (precedence > 6)
                if (widget.readingsDefinition.precedence > 6)
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Pas de commun',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                // List of available commons
                ...?widget.readingsDefinition.commonList?.map(
                  (common) => DropdownMenuItem<String?>(
                    value: common,
                    child: Text(
                      commonTitles[common] ?? common,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ),
              ],
              onChanged: widget.onCommonChanged,
            ),
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
}

/// Biblical Reading tab
class _BiblicalReadingTab extends StatelessWidget {
  const _BiblicalReadingTab({required this.readingsData});

  final Readings readingsData;

  @override
  Widget build(BuildContext context) {
    final biblicalReadings = readingsData.biblicalReading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['biblical_reading'] ?? 'Lecture biblique'),
        const SizedBox(height: 16),

        if (biblicalReadings != null && biblicalReadings.isNotEmpty) ...[
          // Display all biblical readings
          for (var i = 0; i < biblicalReadings.length; i++) ...[
            if (i > 0) SizedBox(height: spaceBetweenElements * 2),
            _buildBiblicalReading(biblicalReadings[i]),
          ],
        ] else
          const Text('Aucune lecture biblique disponible'),
      ],
    );
  }

  Widget _buildBiblicalReading(BiblicalReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (reading.title != null) ...[
          Text(
            reading.title!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Reference
        if (reading.ref != null) ...[
          Text(
            reading.ref!,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Content
        if (reading.content != null) ...[
          LiturgyPartFormattedText(
            reading.content!,
            textAlign: TextAlign.justify,
            includeVerseIdPlaceholder: false,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Responsory
        if (reading.responsory != null) ...[
          SizedBox(height: spaceBetweenElements),
          LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
          LiturgyPartFormattedText(
            reading.responsory!,
            includeVerseIdPlaceholder: false,
          ),
        ],
      ],
    );
  }
}

/// Patristic Reading tab
class _PatristicReadingTab extends StatelessWidget {
  const _PatristicReadingTab({required this.readingsData});

  final Readings readingsData;

  @override
  Widget build(BuildContext context) {
    final patristicReadings = readingsData.patristicalReading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['patristic_reading'] ?? 'Lecture patristique'),
        const SizedBox(height: 16),

        if (patristicReadings != null && patristicReadings.isNotEmpty) ...[
          // Display all patristic readings
          for (var i = 0; i < patristicReadings.length; i++) ...[
            if (i > 0) SizedBox(height: spaceBetweenElements * 2),
            _buildPatristicReading(patristicReadings[i]),
          ],
        ] else
          const Text('Aucune lecture patristique disponible'),
      ],
    );
  }

  Widget _buildPatristicReading(PatristicReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (reading.title != null) ...[
          Text(
            reading.title!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Subtitle
        if (reading.subtitle != null) ...[
          Text(
            reading.subtitle!,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Content
        if (reading.content != null) ...[
          LiturgyPartFormattedText(
            reading.content!,
            textAlign: TextAlign.justify,
            includeVerseIdPlaceholder: false,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Responsory
        if (reading.responsory != null) ...[
          SizedBox(height: spaceBetweenElements),
          LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
          LiturgyPartFormattedText(
            reading.responsory!,
            includeVerseIdPlaceholder: false,
          ),
        ],
      ],
    );
  }
}

/// Te Deum tab
class _TeDeumTab extends StatefulWidget {
  const _TeDeumTab({required this.dataLoader});

  final DataLoader dataLoader;

  @override
  State<_TeDeumTab> createState() => _TeDeumTabState();
}

class _TeDeumTabState extends State<_TeDeumTab> {
  String? teDeumContent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeDeum();
  }

  Future<void> _loadTeDeum() async {
    try {
      final hymns = await HymnsLibrary.getHymns(['te-deum'], widget.dataLoader);
      if (mounted) {
        setState(() {
          teDeumContent = hymns['te-deum']?.content;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading Te Deum: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['te_deum'] ?? 'Te Deum'),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (teDeumContent != null)
          HymnContentDisplay(content: teDeumContent!)
        else
          const Text('Te Deum non disponible'),
      ],
    );
  }
}

/// Oration tab
class _OrationTab extends StatelessWidget {
  const _OrationTab({required this.readingsData});

  final Readings readingsData;

  @override
  Widget build(BuildContext context) {
    final orations = readingsData.oration;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        const SizedBox(height: 16),

        if (orations != null && orations.isNotEmpty) ...[
          for (var i = 0; i < orations.length; i++) ...[
            if (i > 0) SizedBox(height: spaceBetweenElements),
            LiturgyPartFormattedText(
              orations[i],
              includeVerseIdPlaceholder: false,
            ),
          ],
        ] else
          const Text('Aucune oraison disponible'),

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
