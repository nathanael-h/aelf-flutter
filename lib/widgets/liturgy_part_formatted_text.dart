import 'package:aelf_flutter/parsers/formatted_text_parser.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget LiturgyPartFormattedText(
  String? content, {
  TextStyle? textStyle,
  TextAlign textAlign = TextAlign.left,
  bool includeVerseIdPlaceholder = true,
  double paragraphSpacing = 16.0,
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

      // Detect format: HTML tags → FormattedTextParser, otherwise → YamlTextParser
      final bool isHtml = content.trim().startsWith('<p>') ||
          content.contains('<br') ||
          content.contains('<i>') ||
          content.contains('<em>') ||
          content.contains('<u>');

      Widget formattedWidget;

      if (isHtml) {
        String htmlContent = content;
        if (!htmlContent.trim().startsWith('<p>')) {
          htmlContent = '<p>$htmlContent</p>';
        }
        formattedWidget = FormattedTextWidget(
          paragraphs: FormattedTextParser.parseHtml(htmlContent),
          textStyle: baseTextStyle,
          textAlign: textAlign,
          paragraphSpacing: paragraphSpacing,
        );
      } else {
        formattedWidget = YamlTextWidget(
          paragraphs: YamlTextParser.parseText(content),
          textStyle: baseTextStyle,
          textAlign: textAlign,
          paragraphSpacing: paragraphSpacing,
        );
      }

      if (includeVerseIdPlaceholder) {
        return Row(
          children: [
            verseIdPlaceholder(zoom: zoomValue),
            Expanded(child: formattedWidget),
          ],
        );
      }

      return formattedWidget;
    },
  );
}
