import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/classes/morning_class.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/offices/morning/morning.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_hymn_selector.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_psalms_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/utils/text_formatting_helper.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_antiphon_display.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';

class MorningView extends StatefulWidget {
  const MorningView({
    super.key,
    required this.morningList,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, MorningDefinition> morningList;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  State<MorningView> createState() => _MorningViewState();
}

class _MorningViewState extends State<MorningView> {
  // State management
  String? selectedCelebrationKey;
  MorningDefinition? selectedCelebration;
  String? selectedCommon;
  Morning? resolvedMorning;

  Map<String, dynamic>? psalmsCache;
  bool isLoading = false;
  bool isResolvingMorning = false;

  @override
  void initState() {
    super.initState();
    _initializeMorning();
  }

  @override
  void didUpdateWidget(MorningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state if date or morningList changes
    if (oldWidget.date != widget.date ||
        oldWidget.morningList != widget.morningList) {
      _resetState();
      _initializeMorning();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _resetState() {
    setState(() {
      selectedCelebrationKey = null;
      selectedCelebration = null;
      selectedCommon = null;
      resolvedMorning = null;
      psalmsCache = null;
      isLoading = false;
      isResolvingMorning = false;
    });
  }

  void _initializeMorning() {
    // Check if there's at least one celebrable option
    final celebrableEntries = widget.morningList.entries
        .where((entry) => entry.value.isCelebrable)
        .toList();

    if (celebrableEntries.isNotEmpty) {
      // Auto-select the first celebrable option
      _selectCelebration(
          celebrableEntries.first.key, celebrableEntries.first.value);
    }
  }

  Future<void> _selectCelebration(
      String key, MorningDefinition celebration) async {
    setState(() {
      selectedCelebrationKey = key;
      selectedCelebration = celebration;
    });

    // Determine if we need to ask for common selection
    final int commonNeededNumber = celebration.commonList?.length ?? 0;

    switch (commonNeededNumber) {
      case 0:
        await _selectCommonAndResolve(null);
        return;
      case 1:
        await _selectCommonAndResolve(celebration.commonList!.first);
        return;
      default:
        await _selectCommonAndResolve(celebration.commonList!.first);
    }
    // Otherwise, wait for user to select common
  }

  Future<void> _selectCommonAndResolve(String? common) async {
    setState(() {
      selectedCommon = common;
      isResolvingMorning = true;
    });

    try {
      final morning = await morningResolution(
        selectedCelebration!.celebrationCode,
        selectedCelebration!.ferialCode,
        common,
        widget.date,
        selectedCelebration!.breviaryWeek,
        widget.dataLoader,
      );

      if (mounted) {
        setState(() {
          resolvedMorning = morning;
          isResolvingMorning = false;
        });
        await _loadPsalms();
      }
    } catch (e) {
      print('Error resolving morning: $e');
      if (mounted) {
        setState(() {
          isResolvingMorning = false;
        });
      }
    }
  }

  Future<void> _loadPsalms() async {
    if (resolvedMorning == null) return;

    setState(() {
      isLoading = true;
    });

    final allPsalmCodes = <String>[];

    if (resolvedMorning!.psalmody != null) {
      for (var entry in resolvedMorning!.psalmody!) {
        allPsalmCodes.add(entry.psalm);
      }
    }

    if (resolvedMorning!.invitatory?.psalms != null) {
      for (var psalmCode in resolvedMorning!.invitatory!.psalms!) {
        allPsalmCodes.add(psalmCode.toString());
      }
    }

    if (allPsalmCodes.isNotEmpty) {
      final loadedPsalms =
          await PsalmsLibrary.getPsalms(allPsalmCodes, widget.dataLoader);
      if (mounted) {
        setState(() {
          psalmsCache = loadedPsalms;
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  int get _psalmCount => resolvedMorning?.psalmody?.length ?? 0;
  int get _tabCount => 5 + _psalmCount;

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isResolvingMorning || isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Office display (with embedded selection if needed)
    if (resolvedMorning != null) {
      return _buildOfficeDisplay();
    }

    // Fallback: no celebration selected and not loading
    return const Center(child: Text('No celebration available'));
  }

  Widget _buildOfficeDisplay() {
    if (resolvedMorning == null) {
      return const Center(child: Text('Error: No morning office resolved'));
    }

    if (resolvedMorning!.psalmody == null &&
        resolvedMorning!.reading == null &&
        resolvedMorning!.oration == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Office data not available',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Check that the JSON file exists',
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
      Tab(text: liturgyLabels['introduction'] ?? 'introduction'),
      Tab(text: liturgyLabels['hymns'] ?? 'hymns'),
    ];

    if (resolvedMorning?.psalmody != null && psalmsCache != null) {
      for (var psalmEntry in resolvedMorning!.psalmody!) {
        final psalmKey = psalmEntry.psalm;
        final psalm = psalmsCache![psalmKey];
        tabs.add(Tab(text: psalm?.getTitle ?? psalmKey));
      }
    }

    tabs.addAll([
      Tab(text: liturgyLabels['reading'] ?? 'reading'),
      Tab(text: liturgyLabels['zachary_canticle'] ?? 'zachary_canticle'),
      Tab(text: liturgyLabels['conclusion'] ?? 'conclusion'),
    ]);

    return tabs;
  }

  Widget _buildTabBarView() {
    if (resolvedMorning == null) {
      return const Center(child: Text('No morning office available'));
    }

    final views = <Widget>[
      _InvitatoryTab(
        morning: resolvedMorning!,
        psalmsCache: psalmsCache,
        officeName: selectedCelebration?.morningDescription,
        liturgicalColor: selectedCelebration?.liturgicalColor,
        morningList: widget.morningList,
        selectedCelebrationKey: selectedCelebrationKey,
        selectedCelebration: selectedCelebration,
        selectedCommon: selectedCommon,
        onCelebrationSelected: _selectCelebration,
        onCommonSelected: _selectCommonAndResolve,
      ),
      _HymnsTab(
        hymns: resolvedMorning!.hymn ?? [],
        dataLoader: widget.dataLoader,
      ),
    ];

    if (resolvedMorning!.psalmody != null) {
      for (var psalmEntry in resolvedMorning!.psalmody!) {
        final psalmKey = psalmEntry.psalm;
        final antiphons = psalmEntry.antiphon ?? [];

        views.add(_PsalmTab(
          psalmKey: psalmKey,
          psalmsCache: psalmsCache,
          dataLoader: widget.dataLoader,
          antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
          antiphon2: antiphons.length > 1 ? antiphons[1] : null,
        ));
      }
    }

    views.addAll([
      _ReadingTab(morning: resolvedMorning!),
      _CanticleTab(
        morning: resolvedMorning!,
        dataLoader: widget.dataLoader,
      ),
      _OrationTab(
        morning: resolvedMorning!,
        dataLoader: widget.dataLoader,
      ),
    ]);

    return TabBarView(children: views);
  }
}

// ==================== SEPARATED WIDGETS ====================

class _InvitatoryTab extends StatefulWidget {
  const _InvitatoryTab({
    required this.morning,
    required this.psalmsCache,
    this.officeName,
    this.liturgicalColor,
    required this.morningList,
    this.selectedCelebrationKey,
    this.selectedCelebration,
    this.selectedCommon,
    required this.onCelebrationSelected,
    required this.onCommonSelected,
  });

  final Morning morning;
  final Map<String, dynamic>? psalmsCache;
  final String? officeName;
  final String? liturgicalColor;
  final Map<String, MorningDefinition> morningList;
  final String? selectedCelebrationKey;
  final MorningDefinition? selectedCelebration;
  final String? selectedCommon;
  final Function(String key, MorningDefinition celebration)
      onCelebrationSelected;
  final Function(String? common) onCommonSelected;

  @override
  State<_InvitatoryTab> createState() => _InvitatoryTabState();
}

class _InvitatoryTabState extends State<_InvitatoryTab> {
  String? selectedPsalmKey;

  @override
  void initState() {
    super.initState();
    if (widget.morning.invitatory?.psalms != null &&
        widget.morning.invitatory!.psalms!.isNotEmpty) {
      selectedPsalmKey = widget.morning.invitatory!.psalms!.first.toString();
    }
  }

  bool _hasMutipleCelebrableOptions() {
    final celebrableCount = widget.morningList.values
        .where((definition) => definition.isCelebrable)
        .length;
    return celebrableCount > 1;
  }

  Color _getLiturgicalColor(String? colorName) {
    if (colorName == null) return Colors.grey;

    switch (colorName.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red.shade700;
      case 'green':
        return Colors.green.shade700;
      case 'violet':
        return Colors.purple.shade700;
      case 'rose':
      case 'pink':
        return Colors.pink.shade300;
      case 'gold':
      case 'yellow':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitatory = widget.morning.invitatory;

    if (invitatory == null) {
      return const Center(child: Text('No invitatory available'));
    }

    final List<String> psalmsList =
        (invitatory.psalms ?? []).map((e) => e.toString()).toList();
    final List<String> antiphons =
        (invitatory.antiphon ?? []).map((e) => e.toString()).toList();

    if (psalmsList.isEmpty) {
      return const Center(child: Text('No psalm available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Liturgical color bar
        if (widget.liturgicalColor != null)
          Container(
            width: double.infinity,
            height: 6,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _getLiturgicalColor(widget.liturgicalColor),
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
        // Office name
        if (widget.officeName != null) ...[
          Text(
            widget.officeName!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Celebration selection dropdown (only if multiple celebrable options)
        if (_hasMutipleCelebrableOptions()) ...[
          const Text(
            'Sélectionner l\'office des Laudes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.blue.shade50,
            ),
            child: DropdownButton<String>(
              value: widget.selectedCelebrationKey,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              dropdownColor: Colors.white,
              selectedItemBuilder: (BuildContext context) {
                return widget.morningList.entries.map((entry) {
                  final liturgicalColor = entry.value.liturgicalColor;
                  return Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _getLiturgicalColor(liturgicalColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.morningDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: widget.morningList.entries.map((entry) {
                final isCelebrable = entry.value.isCelebrable;
                final liturgicalColor = entry.value.liturgicalColor;
                return DropdownMenuItem<String>(
                  value: entry.key,
                  enabled: isCelebrable,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _getLiturgicalColor(liturgicalColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.morningDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: isCelebrable ? Colors.black87 : Colors.grey,
                            fontWeight: isCelebrable
                                ? FontWeight.normal
                                : FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  final selectedEntry = widget.morningList.entries
                      .firstWhere((entry) => entry.key == newValue);
                  widget.onCelebrationSelected(newValue, selectedEntry.value);
                }
              },
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Common selection dropdown (if needed)
        if (widget.selectedCelebration != null &&
            (widget.selectedCelebration!.commonList?.isNotEmpty ?? false)) ...[
          const Text(
            'Sélectionner un commun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.blue.shade50,
            ),
            child: DropdownButton<String?>(
              value: widget.selectedCommon,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              dropdownColor: Colors.white,
              hint: const Text('Choisir un commun',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              items: [
                // "Pas de commun" option (if grade > 6)
                if (widget.selectedCelebration!.precedence > 6)
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Pas de commun',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                // List of commons
                ...widget.selectedCelebration!.commonList!.map((common) {
                  return DropdownMenuItem<String?>(
                    value: common,
                    child: Text(
                      common,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  );
                }),
              ],
              onChanged: (String? newValue) {
                widget.onCommonSelected(newValue);
              },
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        LiturgyPartTitle(liturgyLabels['introduction'] ?? 'introduction'),
        buildFormattedText(
            fixedTexts['officeIntroduction'] ?? 'officeIntroduction'),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['invitatory'] ?? 'invitatory'),
        const SizedBox(height: 16),
        if (antiphons.isNotEmpty) ...[
          AntiphonWidget(
            antiphon1: antiphons[0],
            antiphon2: antiphons.length > 1 ? antiphons[1] : null,
            antiphon3: antiphons.length > 2 ? antiphons[2] : null,
          ),
          const SizedBox(height: 16),
        ],
        DropdownButton<String>(
          value: selectedPsalmKey,
          hint: const Text('Sélectionner un psaume'),
          isExpanded: true,
          items: psalmsList.map((String psalmKey) {
            final psalm = widget.psalmsCache?[psalmKey];
            return DropdownMenuItem<String>(
              value: psalmKey,
              child: Text(
                psalm?.getTitle ?? 'Psalm not found: $psalmKey',
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
        if (selectedPsalmKey != null && widget.psalmsCache != null)
          _buildPsalm(selectedPsalmKey!),
      ],
    );
  }

  Widget _buildPsalm(String psalmKey) {
    final psalm = widget.psalmsCache![psalmKey];
    if (psalm == null) {
      return const Text('Psalm not found');
    }

    final invitatory = widget.morning.invitatory;
    final List<String> antiphons =
        (invitatory?.antiphon ?? []).map((e) => e.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PsalmFromHtml(htmlContent: psalm.getContent),
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

class _HymnsTab extends StatelessWidget {
  const _HymnsTab({
    required this.hymns,
    required this.dataLoader,
  });

  final List<String> hymns;
  final DataLoader dataLoader;

  @override
  Widget build(BuildContext context) {
    if (hymns.isEmpty) {
      return const Center(child: Text('No hymn available'));
    }
    return HymnSelectorWithTitle(
      title: liturgyLabels['hymns'] ?? 'Hymnes',
      hymns: hymns,
      dataLoader: dataLoader,
    );
  }
}

class _PsalmTab extends StatelessWidget {
  const _PsalmTab({
    required this.psalmKey,
    required this.psalmsCache,
    required this.dataLoader,
    this.antiphon1,
    this.antiphon2,
  });

  final String? psalmKey;
  final Map<String, dynamic>? psalmsCache;
  final DataLoader dataLoader;
  final String? antiphon1;
  final String? antiphon2;

  @override
  Widget build(BuildContext context) {
    return PsalmDisplayWidget(
      psalmKey: psalmKey,
      psalms: psalmsCache ?? {},
      dataLoader: dataLoader,
      antiphon1: antiphon1,
      antiphon2: antiphon2,
    );
  }
}

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
        buildFormattedText(morning.responsory ?? 'No responsory available'),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}

class _CanticleTab extends StatelessWidget {
  const _CanticleTab({
    required this.morning,
    required this.dataLoader,
  });

  final Morning morning;
  final DataLoader dataLoader;

  @override
  Widget build(BuildContext context) {
    final antiphon = morning.evangelicAntiphon?.common;

    if (antiphon == null) {
      return const Center(child: Text('No antiphon available'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CanticleWidget(
        canticleType: 'benedictus',
        antiphon1: antiphon,
        dataLoader: dataLoader,
      ),
    );
  }
}

class _OrationTab extends StatefulWidget {
  const _OrationTab({
    required this.morning,
    required this.dataLoader,
  });

  final Morning morning;
  final DataLoader dataLoader;

  @override
  State<_OrationTab> createState() => _OrationTabState();
}

class _OrationTabState extends State<_OrationTab> {
  String? notrePereContent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotrePere();
  }

  Future<void> _loadNotrePere() async {
    try {
      final hymns =
          await HymnsLibrary.getHymns(['notre-pere'], widget.dataLoader);
      if (mounted) {
        setState(() {
          notrePereContent = hymns['notre-pere']?.content;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading Notre Père: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intercession section
        LiturgyPartTitle(liturgyLabels['intercession'] ?? 'intercession'),
        if (widget.morning.intercession?.content != null) ...[
          buildFormattedText(
            widget.morning.intercession!.content!,
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: spaceBetweenElements),
          SizedBox(height: spaceBetweenElements),
        ] else ...[
          const Text('No intercession available'),
          SizedBox(height: spaceBetweenElements),
          SizedBox(height: spaceBetweenElements),
        ],

        // Notre Père section
        LiturgyPartTitle(liturgyLabels['our_father'] ?? 'our_father'),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (notrePereContent != null)
          buildFormattedText(
            notrePereContent!,
            textAlign: TextAlign.justify,
          )
        else
          buildFormattedText(
            fixedTexts['ourFather'] ??
                'Notre Père, qui es aux cieux,\nque ton nom soit sanctifié,\nque ton règne vienne,\nque ta volonté soit faite sur la terre comme au ciel.\nDonne-nous aujourd\'hui notre pain de ce jour.\nPardonne-nous nos offenses,\ncomme nous pardonnons aussi à ceux qui nous ont offensés.\nEt ne nous laisse pas entrer en tentation\nmais délivre-nous du Mal.\nAmen.',
          ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),

        // Oration section
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'oration'),
        buildFormattedText(
          widget.morning.oration?.join("\n") ?? 'No oration available',
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),

        // Blessing section
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'blessing'),
        buildFormattedText(
          fixedTexts['officeBenediction'] ?? 'officeBenediction',
        ),
      ],
    );
  }
}
