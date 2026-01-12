import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Type of reading to display
enum ReadingType {
  scripture, // Simple scripture reading (Morning, Compline)
  biblical, // Biblical reading (Readings office)
  patristic, // Patristic reading (Readings office)
  teDeum, // Te Deum (Readings office)
  oration, // Oration (Readings office)
}

/// Tab for displaying readings of various types
class ReadingTab extends StatelessWidget {
  const ReadingTab({
    super.key,
    required this.resolved,
    required this.readingType,
  });

  final ResolvedOffice resolved;
  final ReadingType readingType;

  @override
  Widget build(BuildContext context) {
    switch (readingType) {
      case ReadingType.scripture:
        return _buildScriptureReading();
      case ReadingType.biblical:
        return _buildBiblicalReading();
      case ReadingType.patristic:
        return _buildPatristicReading();
      case ReadingType.teDeum:
        return _TeDeumTab(resolved: resolved);
      case ReadingType.oration:
        return _buildOrationReading();
    }
  }

  Widget _buildScriptureReading() {
    dynamic reading;
    String? responsory;

    try {
      reading = (resolved.officeData as dynamic).reading;
      responsory = (resolved.officeData as dynamic).responsory as String?;
    } catch (e) {
      reading = null;
      responsory = null;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScriptureWidget(
          title: liturgyLabels['word_of_god'] ?? 'Parole de Dieu',
          reference: reading?.biblicalReference,
          content: reading?.content,
        ),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        LiturgyPartTitle(liturgyLabels['responsory'] ?? 'Répons'),
        LiturgyPartFormattedText(
          responsory ?? 'No responsory available',
          includeVerseIdPlaceholder: false,
        ),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }

  Widget _buildBiblicalReading() {
    List<dynamic>? readings;

    try {
      readings = (resolved.officeData as dynamic).biblicalReading as List<dynamic>?;
    } catch (e) {
      readings = null;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['biblical_reading'] ?? 'Lecture biblique'),
        const SizedBox(height: 16),
        if (readings != null && readings.isNotEmpty) ...[
          for (var i = 0; i < readings.length; i++) ...[
            if (i > 0) SizedBox(height: spaceBetweenElements * 2),
            _buildBiblicalReadingEntry(readings[i]),
          ],
        ] else
          const Text('Aucune lecture biblique disponible'),
      ],
    );
  }

  Widget _buildBiblicalReadingEntry(dynamic reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (reading.content != null) ...[
          LiturgyPartFormattedText(
            reading.content!,
            textAlign: TextAlign.justify,
            includeVerseIdPlaceholder: false,
          ),
          SizedBox(height: spaceBetweenElements),
        ],
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

  Widget _buildPatristicReading() {
    List<dynamic>? readings;

    try {
      readings = (resolved.officeData as dynamic).patristicalReading as List<dynamic>?;
    } catch (e) {
      readings = null;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartTitle(liturgyLabels['patristic_reading'] ?? 'Lecture patristique'),
        const SizedBox(height: 16),
        if (readings != null && readings.isNotEmpty) ...[
          for (var i = 0; i < readings.length; i++) ...[
            if (i > 0) SizedBox(height: spaceBetweenElements * 2),
            _buildPatristicReadingEntry(readings[i]),
          ],
        ] else
          const Text('Aucune lecture patristique disponible'),
      ],
    );
  }

  Widget _buildPatristicReadingEntry(dynamic reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (reading.content != null) ...[
          LiturgyPartFormattedText(
            reading.content!,
            textAlign: TextAlign.justify,
            includeVerseIdPlaceholder: false,
          ),
          SizedBox(height: spaceBetweenElements),
        ],
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

  Widget _buildOrationReading() {
    List<String>? orations;

    try {
      orations = ((resolved.officeData as dynamic).oration as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
    } catch (e) {
      orations = null;
    }

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

/// Te Deum tab (for Readings office)
class _TeDeumTab extends StatefulWidget {
  const _TeDeumTab({required this.resolved});

  final ResolvedOffice resolved;

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
      // Extract DataLoader from resolved office
      // This is a temporary solution - ideally DataLoader should be passed
      final hymns = await HymnsLibrary.getHymns(
        ['te-deum'],
        (widget.resolved.officeData as dynamic).dataLoader,
      );
      if (mounted) {
        setState(() {
          teDeumContent = hymns['te-deum']?.content;
          isLoading = false;
        });
      }
    } catch (e) {
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
