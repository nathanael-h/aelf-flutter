import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:provider/provider.dart';

/// Helper function to build formatted text from HTML or YAML content
/// Used throughout the liturgy views for consistent text formatting
/// Automatically detects format:
/// - If content starts with '<p>' or contains HTML tags -> HTML parser
/// - Otherwise -> YAML markdown parser
Widget LiturgyPartFormattedText(
  String? content, {
  TextStyle? textStyle,
  TextAlign textAlign = TextAlign.left,
  bool includeVerseIdPlaceholder = true,
}) {
  if (content == null || content.isEmpty) {
    return const SizedBox.shrink();
  }

  return Consumer<CurrentZoom>(
    builder: (context, currentZoom, child) {
      final zoomValue = currentZoom.value ?? 100.0;
      final baseTextStyle = textStyle ??
          TextStyle(
            fontSize: 16.0 * zoomValue / 100,
            height: 1.3,
          );

      // Detect format and use appropriate parser
      final bool isHtml = content.trim().startsWith('<p>') ||
          content.contains('<br') ||
          content.contains('<i>') ||
          content.contains('<em>') ||
          content.contains('<u>');

      Widget formattedWidget;

      if (isHtml) {
        // Use HTML parser for legacy content
        String htmlContent = content;
        if (!htmlContent.trim().startsWith('<p>')) {
          htmlContent = '<p>$htmlContent</p>';
        }

        final paragraphs = FormattedTextParser.parseHtml(htmlContent);
        formattedWidget = FormattedTextWidget(
          paragraphs: paragraphs,
          textStyle: baseTextStyle,
          textAlign: textAlign,
        );
      } else {
        // Use YAML parser for new markdown content
        final paragraphs = YamlTextParser.parseText(content);
        formattedWidget = YamlTextWidget(
          paragraphs: paragraphs,
          textStyle: baseTextStyle,
          textAlign: textAlign,
        );
      }

      // If we need verse ID placeholder, wrap in Row with Expanded
      if (includeVerseIdPlaceholder) {
        return Row(
          children: [
            // Pass zoom to avoid nested Consumer
            verseIdPlaceholder(zoom: zoomValue),
            Expanded(child: formattedWidget),
          ],
        );
      }

      // Otherwise, return widget directly (simpler layout)
      return formattedWidget;
    },
  );
}
