import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/widgets/office_view/widgets/office_header.dart';
import 'package:aelf_flutter/widgets/office_view/widgets/celebration_selector.dart';
import 'package:aelf_flutter/widgets/office_view/widgets/common_selector.dart';
import 'package:aelf_flutter/widgets/office_view/widgets/invitatory_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:aelf_flutter/widgets/liturgy_part_info_widget.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Introduction tab - handles office header, selectors, and introduction text
class IntroductionTab extends StatelessWidget {
  const IntroductionTab({
    super.key,
    required this.officeType,
    required this.resolved,
    required this.definitions,
    required this.dataLoader,
    required this.onCelebrationChanged,
    this.onCommonChanged,
    this.additionalData,
    this.showInvitatory = true,
  });

  final OfficeType officeType;
  final ResolvedOffice resolved;
  final Map<String, dynamic> definitions;
  final DataLoader dataLoader;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?>? onCommonChanged;
  final dynamic additionalData;
  final bool showInvitatory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // Office header (title, color, precedence, description)
        OfficeHeader(
          resolved: resolved,
          officeType: officeType,
        ),

        // Celebration selector (if multiple options)
        if (_hasMultipleCelebrations())
          CelebrationSelector(
            resolved: resolved,
            definitions: definitions,
            onCelebrationChanged: onCelebrationChanged,
            officeType: officeType,
          ),

        // Common selector (if applicable)
        if (onCommonChanged != null && _needsCommonSelection())
          CommonSelector(
            resolved: resolved,
            dataLoader: dataLoader,
            onCommonChanged: onCommonChanged!,
          ),

        // Compline specific info widget
        if (officeType == OfficeType.compline && additionalData != null) ...[
          LiturgyPartInfoWidget(
            complineDefinition: resolved.definition,
            calendar: additionalData.calendar,
            date: additionalData.date,
          ),
          _buildComplineCommentary(),
        ],

        // Introduction text
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
              if (officeType == OfficeType.compline)
                LiturgyPartRubric(fixedTexts['complineIntroduction'] ?? ''),
            ],
          ),
        ),

        // Invitatory (Morning only - deprecated, now in separate tab)
        if (officeType == OfficeType.morning && showInvitatory)
          InvitatoryDisplay(
            resolved: resolved,
            dataLoader: dataLoader,
          ),
      ],
    );
  }

  bool _hasMultipleCelebrations() {
    return definitions.values.where((d) {
      try {
        return (d as dynamic).isCelebrable as bool? ?? true;
      } catch (e) {
        return true;
      }
    }).length > 1;
  }

  bool _needsCommonSelection() {
    try {
      final definition = resolved.definition;
      final commonList = (definition as dynamic).commonList as List<dynamic>?;
      final liturgicalTime = (definition as dynamic).liturgicalTime as String?;
      final celebrationCode = (definition as dynamic).celebrationCode as String?;
      final ferialCode = (definition as dynamic).ferialCode as String?;
      final precedence = (definition as dynamic).precedence as int?;

      if (commonList == null || commonList.isEmpty) return false;

      if (liturgicalTime == 'paschaloctave' ||
          liturgicalTime == 'christmasoctave') {
        return false;
      }

      if (celebrationCode == ferialCode) return false;

      return commonList.length >= 2 ||
          (commonList.length == 1 && (precedence ?? 0) > 6);
    } catch (e) {
      return false;
    }
  }

  Widget _buildComplineCommentary() {
    try {
      final commentary = (resolved.officeData as dynamic).commentary as String?;
      if (commentary != null && commentary.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
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
                  Text(commentary),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // No commentary
    }
    return const SizedBox.shrink();
  }
}
