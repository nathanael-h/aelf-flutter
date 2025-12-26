import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';
import 'package:provider/provider.dart';

/// Helper function to build formatted text from HTML content
/// Used throughout the liturgy views for consistent text formatting
Widget LiturgyPartFormattedText(
  String? content, {
  TextStyle? textStyle,
  TextAlign textAlign = TextAlign.left,
}) {
  if (content == null || content.isEmpty) {
    return const SizedBox.shrink();
  }

  // Wrap content in <p> if not already wrapped
  String htmlContent = content;
  if (!htmlContent.trim().startsWith('<p>')) {
    htmlContent = '<p>$htmlContent</p>';
  }

  final paragraphs = FormattedTextParser.parseHtml(htmlContent);

  return Consumer<CurrentZoom>(
    builder: (context, currentZoom, child) => Row(
      children: [
        verseIdPlaceholder(),
        Expanded(
          child: FormattedTextWidget(
            paragraphs: paragraphs,
            textStyle: textStyle ??
                TextStyle(
                  fontSize: 16.0 * currentZoom.value! / 100,
                  height: 1.3 * currentZoom.value! / 100,
                ),
            textAlign: textAlign,
          ),
        ),
      ],
    ),
  );
}
