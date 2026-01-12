import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/date_tools.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Header widget displaying office title, liturgical color, precedence, and description
class OfficeHeader extends StatelessWidget {
  const OfficeHeader({
    super.key,
    required this.resolved,
    required this.officeType,
  });

  final ResolvedOffice resolved;
  final OfficeType officeType;

  @override
  Widget build(BuildContext context) {
    String title = '';
    String? liturgicalColor;
    int? precedence;
    String? description;

    try {
      final definition = resolved.definition;

      switch (officeType) {
        case OfficeType.readings:
          title = (definition as dynamic).readingsDescription ?? '';
          break;
        case OfficeType.morning:
          title = (definition as dynamic).morningDescription ?? '';
          break;
        case OfficeType.compline:
          title = (definition as dynamic).complineDescription ?? '';
          break;
        case OfficeType.vespers:
          title = 'Vêpres';
          break;
      }

      liturgicalColor = (definition as dynamic).liturgicalColor as String?;
      precedence = (definition as dynamic).precedence as int?;
      description = (definition as dynamic).celebrationDescription as String?;
    } catch (e) {
      // Error accessing definition properties
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Liturgical color bar
        if (liturgicalColor != null)
          Container(
            width: double.infinity,
            height: 6,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: getLiturgicalColor(liturgicalColor),
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
        if (precedence != null)
          Text(
            getCelebrationTypeLabel(precedence),
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 8),

        // Description
        if (description != null && description.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          SizedBox(height: spaceBetweenElements),
        ],
      ],
    );
  }
}
