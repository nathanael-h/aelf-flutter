import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/date_tools.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Widget for selecting between multiple celebrations
class CelebrationSelector extends StatelessWidget {
  const CelebrationSelector({
    super.key,
    required this.resolved,
    required this.definitions,
    required this.onCelebrationChanged,
    required this.officeType,
  });

  final ResolvedOffice resolved;
  final Map<String, dynamic> definitions;
  final ValueChanged<String> onCelebrationChanged;
  final OfficeType officeType;

  @override
  Widget build(BuildContext context) {
    String selectorLabel;
    String descriptionField;

    switch (officeType) {
      case OfficeType.readings:
        selectorLabel = 'Sélectionner l\'office des Lectures';
        descriptionField = 'readingsDescription';
        break;
      case OfficeType.morning:
        selectorLabel = 'Sélectionner l\'office des Laudes';
        descriptionField = 'morningDescription';
        break;
      case OfficeType.compline:
        selectorLabel = 'Choisir les Complies';
        descriptionField = 'complineDescription';
        break;
      case OfficeType.vespers:
        selectorLabel = 'Sélectionner les Vêpres';
        descriptionField = 'vespersDescription';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            selectorLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFEFE3CE),
            ),
            child: DropdownButton<String>(
              value: resolved.celebrationKey,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              dropdownColor: const Color(0xFFEFE3CE),
              items: definitions.entries
                  .where((e) => _isCelebrable(e.value))
                  .map((entry) {
                final liturgicalColor = _getLiturgicalColor(entry.value);
                final description = _getDescription(entry.value, descriptionField);
                final precedence = _getPrecedence(entry.value);

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
                          '$description ${getCelebrationTypeLabel(precedence)}',
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
                if (value != null) onCelebrationChanged(value);
              },
            ),
          ),
        ),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }

  bool _isCelebrable(dynamic definition) {
    try {
      return (definition as dynamic).isCelebrable as bool? ?? true;
    } catch (e) {
      return true;
    }
  }

  String? _getLiturgicalColor(dynamic definition) {
    try {
      return (definition as dynamic).liturgicalColor as String?;
    } catch (e) {
      return null;
    }
  }

  String _getDescription(dynamic definition, String field) {
    try {
      // Try to access the field directly based on office type
      switch (officeType) {
        case OfficeType.readings:
          return (definition as dynamic).readingsDescription as String? ?? '';
        case OfficeType.morning:
          return (definition as dynamic).morningDescription as String? ?? '';
        case OfficeType.compline:
          return (definition as dynamic).complineDescription as String? ?? '';
        case OfficeType.vespers:
          return (definition as dynamic).vespersDescription as String? ?? '';
      }
    } catch (e) {
      return '';
    }
  }

  int _getPrecedence(dynamic definition) {
    try {
      return (definition as dynamic).precedence as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
