import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/classes/morning_class.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
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
    required this.morning,
    required this.dataLoader,
  });

  final Morning morning;
  final DataLoader dataLoader;

  @override
  State<MorningView> createState() => _MorningViewState();
}

class _MorningViewState extends State<MorningView> {
  Map<String, dynamic>? psalmsCache;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPsalms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPsalms() async {
    final allPsalmCodes = <String>[];

    if (widget.morning.psalmody != null) {
      for (var entry in widget.morning.psalmody!) {
        allPsalmCodes.add(entry.psalm);
      }
    }

    if (widget.morning.invitatory?.psalms != null) {
      for (var psalmCode in widget.morning.invitatory!.psalms!) {
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

  int get _psalmCount => widget.morning.psalmody?.length ?? 0;
  int get _tabCount => 5 + _psalmCount;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.morning.psalmody == null &&
        widget.morning.reading == null &&
        widget.morning.oration == null) {
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

    if (widget.morning.psalmody != null && psalmsCache != null) {
      for (var psalmEntry in widget.morning.psalmody!) {
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
    final views = <Widget>[
      _InvitatoryTab(
        morning: widget.morning,
        psalmsCache: psalmsCache,
      ),
      _HymnsTab(
        hymns: widget.morning.hymn ?? [],
        dataLoader: widget.dataLoader,
      ),
    ];

    if (widget.morning.psalmody != null) {
      for (var psalmEntry in widget.morning.psalmody!) {
        final psalmKey = psalmEntry.psalm;
        final antiphons = psalmEntry.antiphon ?? [];

        views.add(_PsalmTab(
          psalmKey: psalmKey,
          psalmsCache: psalmsCache,
          antiphon1: antiphons.isNotEmpty ? antiphons[0] : null,
          antiphon2: antiphons.length > 1 ? antiphons[1] : null,
        ));
      }
    }

    views.addAll([
      _ReadingTab(morning: widget.morning),
      _CanticleTab(
        morning: widget.morning,
        dataLoader: widget.dataLoader,
      ),
      _OrationTab(
        morning: widget.morning,
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
  });

  final Morning morning;
  final Map<String, dynamic>? psalmsCache;

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
    this.antiphon1,
    this.antiphon2,
  });

  final String? psalmKey;
  final Map<String, dynamic>? psalmsCache;
  final String? antiphon1;
  final String? antiphon2;

  @override
  Widget build(BuildContext context) {
    return PsalmDisplayWidget(
      psalmKey: psalmKey,
      psalms: psalmsCache ?? {},
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
