import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';

class ScriptureWidget extends StatelessWidget {
  final String title;
  final String? reference;
  final String? content;
  final TextStyle? titleStyle;
  final TextStyle? referenceStyle;
  final TextStyle? contentStyle;
  final double? spacing;

  const ScriptureWidget({
    super.key,
    required this.title,
    this.reference,
    this.content,
    this.titleStyle,
    this.referenceStyle,
    this.contentStyle,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and reference
        Row(
          children: [
            LiturgyPartTitle(title),
            if (reference != null && reference!.isNotEmpty)
              Expanded(
                child: Text(
                  reference!,
                  style: referenceStyle ?? biblicalReferenceStyle,
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),

        // Spacing
        SizedBox(height: spacing ?? 16.0),

        // Reading content - use FormattedTextParser
        if (content != null && content!.isNotEmpty) _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    // Check if content contains HTML tags
    if (content!.contains('<') && content!.contains('>')) {
      // Wrap content in <p> if not already wrapped
      String htmlContent = content!;
      if (!htmlContent.trim().startsWith('<p>')) {
        htmlContent = '<p>$htmlContent</p>';
      }

      final paragraphs = FormattedTextParser.parseHtml(htmlContent);

      return FormattedTextWidget(
        paragraphs: paragraphs,
        textStyle: TextStyle(
          fontSize: 16.0, // Same size as psalms
          height: 1.3,
        ),
        textAlign: TextAlign.justify, // Justified text
      );
    } else {
      // Plain text, use simple Text widget with apostrophe replacement
      return Text(
        content!.replaceAll("'", '\u2019'),
        style: const TextStyle(
          fontSize: 16.0, // Same size as psalms
          height: 1.3,
        ),
        textAlign: TextAlign.justify, // Justified text
      );
    }
  }
}
