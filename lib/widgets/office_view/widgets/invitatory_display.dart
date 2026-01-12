import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Widget for displaying the invitatory (Morning office only)
class InvitatoryDisplay extends StatefulWidget {
  const InvitatoryDisplay({
    super.key,
    required this.resolved,
    required this.dataLoader,
  });

  final ResolvedOffice resolved;
  final DataLoader dataLoader;

  @override
  State<InvitatoryDisplay> createState() => _InvitatoryDisplayState();
}

class _InvitatoryDisplayState extends State<InvitatoryDisplay> {
  String? selectedPsalmKey;

  @override
  void initState() {
    super.initState();
    final psalms = _getPsalms();
    if (psalms != null && psalms.isNotEmpty) {
      selectedPsalmKey = psalms.first.toString();
    }
  }

  List<dynamic>? _getPsalms() {
    try {
      final invitatory = (widget.resolved.officeData as dynamic).invitatory;
      return (invitatory as dynamic).psalms as List<dynamic>?;
    } catch (e) {
      return null;
    }
  }

  List<String>? _getAntiphons() {
    try {
      final invitatory = (widget.resolved.officeData as dynamic).invitatory;
      final antiphons = (invitatory as dynamic).antiphon as List<dynamic>?;
      return antiphons?.map((e) => e.toString()).toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final psalms = _getPsalms();
    final antiphons = _getAntiphons();

    if (psalms == null || psalms.isEmpty) {
      return const SizedBox.shrink();
    }

    final psalmsList = psalms.map((e) => e.toString()).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiturgyPartTitle(liturgyLabels['invitatory'] ?? 'Invitatoire'),
          const SizedBox(height: 16),

          // Antiphons
          if (antiphons != null && antiphons.isNotEmpty) ...[
            AntiphonWidget(
              antiphon1: antiphons[0],
              antiphon2: antiphons.length > 1 ? antiphons[1] : null,
              antiphon3: antiphons.length > 2 ? antiphons[2] : null,
            ),
            const SizedBox(height: 16),
          ],

          // Psalm selector
          DropdownButton<String>(
            value: selectedPsalmKey,
            hint: const Text('Sélectionner un psaume'),
            isExpanded: true,
            items: psalmsList.map((String psalmKey) {
              final psalm = widget.resolved.psalmsCache[psalmKey];
              final displayText = getPsalmDisplayTitle(psalm, psalmKey);
              return DropdownMenuItem<String>(
                value: psalmKey,
                child: Text(displayText),
              );
            }).toList(),
            onChanged: (String? newKey) {
              setState(() {
                selectedPsalmKey = newKey;
              });
            },
          ),
          const SizedBox(height: 20),

          // Display selected psalm
          if (selectedPsalmKey != null) _buildPsalm(selectedPsalmKey!, antiphons),
        ],
      ),
    );
  }

  Widget _buildPsalm(String psalmKey, List<String>? antiphons) {
    final psalm = widget.resolved.psalmsCache[psalmKey];
    if (psalm == null) {
      return const Text('Psalm not found');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PsalmFromHtml(htmlContent: psalm.getContent),
        if (antiphons != null && antiphons.isNotEmpty) ...[
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
