import 'package:flutter/material.dart';
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';

class AntiphonWidget extends StatelessWidget {
  final String antiphon1;
  final String? antiphon2;
  final String? antiphon3;

  const AntiphonWidget({
    Key? key,
    required this.antiphon1,
    this.antiphon2,
    this.antiphon3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasAntiphon2 = (antiphon2 ?? "").isNotEmpty;
    final bool hasAntiphon3 = (antiphon3 ?? "").isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAntiphon(antiphon1,
            hasMultiple: hasAntiphon2 || hasAntiphon3, number: 1),
        if (hasAntiphon2)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: _buildAntiphon(antiphon2!, hasMultiple: true, number: 2),
          ),
        if (hasAntiphon3)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: _buildAntiphon(antiphon3!, hasMultiple: true, number: 3),
          ),
      ],
    );
  }

  Widget _buildAntiphon(String antiphon,
      {required bool hasMultiple, required int number}) {
    // Build the label text only (no HTML span)
    final String label = hasMultiple ? 'Ant. $number' : 'Ant.';

    // Parse the antiphon content (without the label)
    String htmlContent = antiphon;
    if (!htmlContent.trim().startsWith('<p>')) {
      htmlContent = '<p>$htmlContent</p>';
    }

    final paragraphs = FormattedTextParser.parseHtml(htmlContent);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label column (Ant., Ant. 1, etc.) in red
          // Width set to 45.0 to accommodate "Ant. 1", "Ant. 2", etc.
          SizedBox(
            width: 45.0,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13.0,
                height: 1.4,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 4.0),
          // Antiphon text
          Expanded(
            child: FormattedTextWidget(
              paragraphs: paragraphs,
              textStyle: const TextStyle(
                fontSize: 13.0,
                height: 1.4,
              ),
              paragraphSpacing: 8.0,
            ),
          ),
        ],
      ),
    );
  }
}
