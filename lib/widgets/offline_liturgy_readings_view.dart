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
  ReadingsDefinition? _selectedDefinition;
  Readings? _readingsData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReadings();
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

      // Resolve readings office
      final readingsData = await readingsResolution(
        _selectedDefinition!.celebrationCode,
        _selectedDefinition!.ferialCode,
        autoCommon,
        widget.date,
        _selectedDefinition!.breviaryWeek,
        widget.dataLoader,
        precedence: _selectedDefinition!.precedence,
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

    if (_selectedDefinition != null && _readingsData != null) {
      return ReadingsView(
        readingsDefinition: _selectedDefinition!,
        readingsData: _readingsData!,
        date: widget.date,
        dataLoader: widget.dataLoader,
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
    required this.readingsDefinition,
    required this.readingsData,
    required this.date,
    required this.dataLoader,
  });

  final ReadingsDefinition readingsDefinition;
  final Readings readingsData;
  final DateTime date;
  final DataLoader dataLoader;

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
      readingsDefinition: widget.readingsDefinition,
      readingsData: widget.readingsData,
      psalmsCache: _psalmsCache,
      dataLoader: widget.dataLoader,
    );
  }
}

/// Pure display widget for Readings Office
class ReadingsOfficeDisplay extends StatelessWidget {
  const ReadingsOfficeDisplay({
    super.key,
    required this.readingsDefinition,
    required this.readingsData,
    required this.psalmsCache,
    required this.dataLoader,
  });

  final ReadingsDefinition readingsDefinition;
  final Readings readingsData;
  final Map<String, dynamic> psalmsCache;
  final DataLoader dataLoader;

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
        readingsDefinition: readingsDefinition,
        readingsData: readingsData,
      ),
      HymnsTabWidget(
        hymns: readingsData.hymn ?? [],
        dataLoader: dataLoader,
        emptyMessage: 'Aucune hymne disponible',
      ),
    ];

    // Add psalm tabs dynamically
    if (readingsData.psalmody != null) {
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
        ));
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
class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.readingsDefinition,
    required this.readingsData,
  });

  final ReadingsDefinition readingsDefinition;
  final Readings readingsData;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Office title
        Text(
          readingsDefinition.readingsDescription,
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
            color: getLiturgicalColor(readingsDefinition.liturgicalColor),
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
          getCelebrationTypeLabel(readingsDefinition.precedence),
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Description (if exists)
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

        SizedBox(height: spaceBetweenElements),

        // Introduction text
        LiturgyPartTitle(liturgyLabels['introduction'] ?? 'Introduction'),
        LiturgyPartFormattedText(
          fixedTexts['officeIntroduction'] ?? 'officeIntroduction',
          includeVerseIdPlaceholder: false,
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        const SizedBox(height: 16),
        const Text('Lecture des oraisons non implémentée pour le moment'),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'Bénédiction'),
        LiturgyPartFormattedText(
          fixedTexts['officeBenediction'] ?? 'officeBenediction',
          includeVerseIdPlaceholder: false,
        ),
      ],
    );
  }
}
