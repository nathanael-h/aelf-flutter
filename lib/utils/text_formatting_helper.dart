import 'package:flutter/material.dart';
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';

/// Helper function to build formatted text from HTML content
/// Used throughout the liturgy views for consistent text formatting
Widget buildFormattedText(
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

  return FormattedTextWidget(
    paragraphs: paragraphs,
    textStyle: textStyle ??
        const TextStyle(
          fontSize: 16.0,
          height: 1.3,
        ),
    textAlign: textAlign,
  );
}
