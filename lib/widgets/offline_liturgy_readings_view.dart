import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_header_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_section_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';

import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/utils/settings.dart';

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
  });

  final Map<String, CelebrationContext> readingsDefinitions;
  final DateTime date;

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
  bool _imprecatoryVerses = false;

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
          _errorMessage = liturgyLabels['no-office']!;
        });
        return;
      }

      // Try to use globally remembered celebration
      final globalState = context.read<SelectedCelebrationState>();
      final globalKey = globalState.celebrationKey;
      final globalEntry = (globalKey != null)
          ? widget.readingsDefinitions.entries
              .where((e) => e.key == globalKey && e.value.isCelebrable)
              .firstOrNull
          : null;

      final selectedEntry = globalEntry ?? firstOption;
      _celebrationKey = selectedEntry.key;
      _selectedDefinition = selectedEntry.value;
      _imprecatoryVerses = await getImprecatoryVerses();

      // Determine common
      String? autoCommon;
      final commonList = _selectedDefinition!.commonList;
      if (commonList != null && commonList.isNotEmpty) {
        if (_selectedDefinition!.celebrationCode != _selectedDefinition!.ferialCode) {
          if (globalState.commonSet) {
            final globalCommon = globalState.common;
            if (globalCommon == null) {
              autoCommon = null;
            } else if (commonList.contains(globalCommon)) {
              autoCommon = globalCommon;
            } else {
              autoCommon = commonList.first;
            }
          } else {
            autoCommon = commonList.first;
          }
        }
      }
      _selectedCommon = autoCommon;

      // Step 3: Resolve readings
      final celebrationContext = _selectedDefinition!.copyWith(
        commonList: autoCommon != null ? [autoCommon] : [],
        showImprecatoryVerses: _imprecatoryVerses,
      );
      final readingsData = await readingsExport(celebrationContext);

      if (mounted) {
        setState(() {
          _readingsData = readingsData;
          _isLoading = false;
        });
        globalState.setCelebration(_celebrationKey);
        globalState.setCommon(autoCommon);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels["error-office"]!}: $e';
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
        commonList: autoCommon != null ? [autoCommon] : [],
        showImprecatoryVerses: _imprecatoryVerses,
      );
      final readingsData = await readingsExport(celebrationContext);

      if (mounted) {
        setState(() {
          _celebrationKey = key;
          _selectedDefinition = definition;
          _selectedCommon = autoCommon;
          _readingsData = readingsData;
          _isLoading = false;
        });
        context.read<SelectedCelebrationState>().setCelebration(key);
        context.read<SelectedCelebrationState>().setCommon(autoCommon);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels["error"]!}: $e';
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
        commonList: common != null ? [common] : [],
        showImprecatoryVerses: _imprecatoryVerses,
      );
      final readingsData = await readingsExport(celebrationContext);

      if (mounted) {
        setState(() {
          _selectedCommon = common;
          _readingsData = readingsData;
          _isLoading = false;
        });
        context.read<SelectedCelebrationState>().setCommon(common);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels["error"]!}: $e';
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
              child: Text(liturgyLabels['retry']!),
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
        readingsDefinitions: widget.readingsDefinitions,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
      );
    }

    return Center(child: Text(liturgyLabels['no-data']!));
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
    required this.readingsDefinitions,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
  });

  final String celebrationKey;
  final CelebrationContext readingsDefinition;
  final Readings readingsData;
  final String? selectedCommon;
  final Map<String, CelebrationContext> readingsDefinitions;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;

  bool _hasMultipleCelebrations() =>
      readingsDefinitions.values.where((d) => d.isCelebrable).length > 1;

  bool _needsCommonSelection() {
    final d = readingsDefinition;
    if (d.commonList == null || d.commonList!.isEmpty) return false;
    if (['paschaloctave', 'christmasoctave'].contains(d.liturgicalTime)) {
      return false;
    }
    return d.celebrationCode != d.ferialCode;
  }

  bool _hasOfficeTab() => _hasMultipleCelebrations() || _needsCommonSelection();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _calculateTabCount(),
      child: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: PinchZoomSelectionArea(
              child: TabBarView(
                children: _buildTabViews(),
              ),
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
        1 // Oration
        +
        (_hasOfficeTab() ? 1 : 0);
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: TabBar(
        isScrollable: true,
        indicatorColor: Theme.of(context).tabBarTheme.labelColor ??
            Theme.of(context).colorScheme.secondary,
        labelColor: Theme.of(context).tabBarTheme.labelColor ??
            Theme.of(context).colorScheme.secondary,
        unselectedLabelColor:
            Theme.of(context).tabBarTheme.unselectedLabelColor ??
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
        tabs: _buildTabs(),
      ),
    );
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[];

    if (_hasOfficeTab()) {
      tabs.add(Tab(text: liturgyLabels['office'] ?? 'Office'));
    }

    tabs.add(Tab(text: liturgyLabels['introduction']));
    tabs.add(Tab(text: liturgyLabels['hymns']));

    if (readingsData.psalmody != null) {
      for (var psalmEntry in readingsData.psalmody!) {
        if (psalmEntry.psalm == null) continue;
        final tabText =
            getPsalmDisplayTitle(psalmEntry.psalmData, psalmEntry.psalm!);
        tabs.add(Tab(text: tabText));
      }
    }

    tabs.addAll([
      Tab(text: liturgyLabels['biblical reading']),
      Tab(text: liturgyLabels['patristic reading']),
    ]);

    if (readingsData.tedeum == true) {
      tabs.add(const Tab(text: 'Te Deum'));
    }

    tabs.add(Tab(text: liturgyLabels['oration']));

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[];

    if (_hasOfficeTab()) {
      views.add(_OfficeTab(
        celebrationKey: celebrationKey,
        readingsDefinition: readingsDefinition,
        readingsDefinitions: readingsDefinitions,
        selectedCommon: selectedCommon,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
        hasMultipleCelebrations: _hasMultipleCelebrations(),
        needsCommonSelection: _needsCommonSelection(),
      ));
    }

    views.add(_IntroductionTab(
      readingsDefinition: readingsDefinition,
    ));

    views.add(HymnsTabWidget(
      hymns: readingsData.hymn ?? [],
      emptyMessage: liturgyLabels['no-hymn']!,
    ));

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

/// Office tab - displays celebration/common selectors and celebration description
class _OfficeTab extends StatelessWidget {
  const _OfficeTab({
    required this.celebrationKey,
    required this.readingsDefinition,
    required this.readingsDefinitions,
    required this.selectedCommon,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    required this.hasMultipleCelebrations,
    required this.needsCommonSelection,
  });

  final String celebrationKey;
  final CelebrationContext readingsDefinition;
  final Map<String, CelebrationContext> readingsDefinitions;
  final String? selectedCommon;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;
  final bool hasMultipleCelebrations;
  final bool needsCommonSelection;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (hasMultipleCelebrations) ...[
          OfficeSectionTitle(liturgyLabels['select-office']!),
          CelebrationChipsSelector(
            celebrationMap: readingsDefinitions,
            selectedKey: celebrationKey,
            onCelebrationChanged: onCelebrationChanged,
          ),
          const SizedBox(height: 12.0),
        ],
        if (needsCommonSelection) ...[
          if ((readingsDefinition.commonList?.length ?? 0) > 1 ||
              (readingsDefinition.precedence ?? 13) > 8)
            OfficeSectionTitle(liturgyLabels['select-common']!),
          CommonChipsSelector(
            commonList: readingsDefinition.commonList ?? [],
            commonTitles: readingsDefinition.commonTitles,
            selectedCommon: selectedCommon,
            precedence: readingsDefinition.precedence ?? 13,
            onCommonChanged: onCommonChanged,
          ),
          const SizedBox(height: 12.0),
        ],
      ],
    );
  }
}

/// Introduction tab
class _IntroductionTab extends StatelessWidget {
  const _IntroductionTab({
    required this.readingsDefinition,
  });

  final CelebrationContext readingsDefinition;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // Office header
        OfficeHeaderDisplay(
          officeDescription: readingsDefinition.officeDescription,
          liturgicalColor: readingsDefinition.liturgicalColor,
          precedence: readingsDefinition.precedence,
          celebrationDescription: readingsDefinition.celebrationDescription,
        ),

        // Introduction
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiturgyPartTitle(liturgyLabels['introduction']),
              YamlTextFromString(
                fixedTexts['officeIntroduction']!,
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ],
    );
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
    final biblicalReadings = readingsData.biblicalReading;
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LiturgyPartTitle(liturgyLabels['biblical_reading']),
            const SizedBox(height: 16),
            if (biblicalReadings != null) ...[
              for (var i = 0; i < biblicalReadings.length; i++) ...[
                if (i > 0) const SizedBox(height: 24.0),
                _buildBiblicalReading(biblicalReadings[i], zoom: zoom),
              ]
            ] else
              Text(liturgyLabels['no-biblical-reading']!),
          ],
        );
      },
    );
  }

  Widget _buildBiblicalReading(BiblicalReading reading,
      {required double zoom}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reading.title != null)
          Text(reading.title!,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16 * zoom / 100)),
        if (reading.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(reading.subtitle!,
              style: TextStyle(
                  fontStyle: FontStyle.italic, fontSize: 14 * zoom / 100)),
        ],
        if (reading.ref != null) ...[
          const SizedBox(height: 4),
          Text(reading.ref!,
              style: TextStyle(
                  fontStyle: FontStyle.italic, fontSize: 14 * zoom / 100)),
        ],
        if (reading.content != null) ...[
          const SizedBox(height: 12.0),
          YamlTextFromString(reading.content!, textAlign: TextAlign.justify),
        ],
        if (reading.responsory != null) ...[
          const SizedBox(height: 24.0),
          LiturgyPartTitle(liturgyLabels['responsory']),
          YamlTextFromString(
            reading.responsory!,
          ),
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
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LiturgyPartTitle(liturgyLabels['patristic_reading']),
            const SizedBox(height: 16),
            if (patristicReadings != null) ...[
              for (var i = 0; i < patristicReadings.length; i++) ...[
                if (i > 0) const SizedBox(height: 24.0),
                _buildPatristicReading(patristicReadings[i], zoom: zoom),
              ]
            ] else
              Text(liturgyLabels['no-patristic-reading']!),
          ],
        );
      },
    );
  }

  Widget _buildPatristicReading(PatristicReading reading,
      {required double zoom}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reading.title != null)
          Text(reading.title!,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16 * zoom / 100)),
        if (reading.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(reading.subtitle!,
              style: TextStyle(
                  fontStyle: FontStyle.italic, fontSize: 14 * zoom / 100)),
        ],
        if (reading.content != null) ...[
          const SizedBox(height: 12.0),
          YamlTextFromString(reading.content!, textAlign: TextAlign.justify),
        ],
        if (reading.responsory != null) ...[
          const SizedBox(height: 24.0),
          LiturgyPartTitle(liturgyLabels['responsory']),
          YamlTextFromString(
            reading.responsory!,
          ),
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
        LiturgyPartTitle(liturgyLabels['te_deum']),
        if (readingsData.tedeumContent != null) ...[
          const SizedBox(height: 12.0),
          YamlTextFromString(
            readingsData.tedeumContent!,
          ),
        ] else
          Text(liturgyLabels['no-te-deum']!),
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
        LiturgyPartTitle(liturgyLabels['oration']),
        const SizedBox(height: 12.0),
        YamlTextFromString(
          readingsData.oration?.join("\n") ?? liturgyLabels['no-oration']!,
          textAlign: TextAlign.justify,
        ),
        LiturgyPartTitle(liturgyLabels['blessing']),
        YamlTextFromString(
          fixedTexts['shortBlessing'] ?? 'shortBlessing',
        ),
      ],
    );
  }
}
