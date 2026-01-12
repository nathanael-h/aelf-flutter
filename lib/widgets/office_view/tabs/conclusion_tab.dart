import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_content_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Tab for conclusion/oration section
/// For Morning: Intercession + Notre Père + Oration + Blessing
/// For Compline: Oration + Blessing
class ConclusionTab extends StatefulWidget {
  const ConclusionTab({
    super.key,
    required this.resolved,
    required this.dataLoader,
    required this.officeType,
  });

  final ResolvedOffice resolved;
  final DataLoader dataLoader;
  final OfficeType officeType;

  @override
  State<ConclusionTab> createState() => _ConclusionTabState();
}

class _ConclusionTabState extends State<ConclusionTab> {
  String? notrePereContent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.officeType == OfficeType.morning) {
      _loadNotrePere();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadNotrePere() async {
    try {
      final hymns = await HymnsLibrary.getHymns(
        ['notre-pere'],
        widget.dataLoader,
      );
      if (mounted) {
        setState(() {
          notrePereContent = hymns['notre-pere']?.content;
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
        // Intercession (Morning only)
        if (widget.officeType == OfficeType.morning) ...[
          LiturgyPartTitle(liturgyLabels['intercession'] ?? 'Intercession'),
          _buildIntercession(),
          SizedBox(height: spaceBetweenElements),
          SizedBox(height: spaceBetweenElements),
          // Notre Père
          LiturgyPartTitle(liturgyLabels['our_father'] ?? 'Notre Père'),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (notrePereContent != null)
            HymnContentDisplay(content: notrePereContent!)
          else
            const Text('Notre Père non disponible'),
          SizedBox(height: spaceBetweenElements),
          SizedBox(height: spaceBetweenElements),
        ],
        // Oration
        LiturgyPartTitle(liturgyLabels['oration'] ?? 'Oraison'),
        _buildOration(),
        SizedBox(height: spaceBetweenElements),
        SizedBox(height: spaceBetweenElements),
        // Blessing
        LiturgyPartTitle(liturgyLabels['blessing'] ?? 'Bénédiction'),
        LiturgyPartFormattedText(
          widget.officeType == OfficeType.compline
              ? (fixedTexts['complineConclusion'] ?? 'complineConclusion')
              : (fixedTexts['officeBenediction'] ?? 'officeBenediction'),
          includeVerseIdPlaceholder: false,
        ),
      ],
    );
  }

  Widget _buildIntercession() {
    try {
      final intercession = (widget.resolved.officeData as dynamic).intercession;
      final content = (intercession as dynamic).content as String?;

      if (content != null && content.isNotEmpty) {
        return LiturgyPartFormattedText(
          content,
          textAlign: TextAlign.justify,
          includeVerseIdPlaceholder: false,
        );
      }
    } catch (e) {
      // Error accessing intercession
    }

    return const Text('No intercession available');
  }

  Widget _buildOration() {
    try {
      final oration = (widget.resolved.officeData as dynamic).oration as List<dynamic>?;

      if (oration != null && oration.isNotEmpty) {
        return LiturgyPartFormattedText(
          oration.map((e) => e.toString()).join("\n"),
          textAlign: TextAlign.justify,
          includeVerseIdPlaceholder: false,
        );
      }
    } catch (e) {
      // Error accessing oration
    }

    return const Text('No oration available');
  }
}
