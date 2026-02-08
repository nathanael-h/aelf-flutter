import 'package:flutter/material.dart';
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';

class AntiphonWidget extends StatelessWidget {
  final String antiphon1;
  final String? antiphon2;
  final String? antiphon3;

  const AntiphonWidget({
    super.key,
    required this.antiphon1,
    this.antiphon2,
    this.antiphon3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAntiphon(antiphon1,
            hasMultiple:
                (antiphon2 ?? "").isNotEmpty || (antiphon3 ?? "").isNotEmpty,
            number: 1),
        if ((antiphon2 ?? "").isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: _buildAntiphon(antiphon2!, hasMultiple: true, number: 2),
          ),
        if ((antiphon3 ?? "").isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: _buildAntiphon(antiphon3!, hasMultiple: true, number: 3),
          ),
      ],
    );
  }

  Widget _buildAntiphon(String antiphon,
      {required bool hasMultiple, required int number}) {
    // Build the label text only
    final String label = hasMultiple ? 'Ant. $number' : 'Ant.';

    // Parse the antiphon content
    String htmlContent = antiphon;
    if (!htmlContent.trim().startsWith('<p>')) {
      htmlContent = '<p>$htmlContent</p>';
    }

    final paragraphs = FormattedTextParser.parseHtml(htmlContent);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Label with a minimum width for alignment, but flexible if needed
          Container(
            constraints: const BoxConstraints(minWidth: 45.0),
            margin: const EdgeInsets.only(right: 8.0),
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
