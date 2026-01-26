import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget to display hymn content with Markdown-like formatting
///
/// Supports:
/// - *text* for italics
/// - > prefix for indented paragraphs
/// - Line breaks and paragraphs
class HymnContentDisplay extends StatelessWidget {
  final String content;
  final TextStyle? baseStyle;

  const HymnContentDisplay({
    super.key,
    required this.content,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final fontSize = 16.0 * currentZoom.value! / 100;
        final defaultStyle = baseStyle ??
            TextStyle(
              fontSize: fontSize,
              height: 1.5,
              color: Colors.black87,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildParagraphs(content, defaultStyle),
        );
      },
    );
  }

  /// Build paragraphs from the content
  List<Widget> _buildParagraphs(String content, TextStyle baseStyle) {
    final paragraphs = content.split('\n\n');
    final widgets = <Widget>[];

    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();
      if (paragraph.isEmpty) continue;

      // Build paragraph with line-by-line indentation
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i < paragraphs.length - 1 ? 12.0 : 0,
          ),
          child: _buildParagraphContent(paragraph, baseStyle),
        ),
      );
    }

    return widgets;
  }

  /// Build the content of a single paragraph
  Widget _buildParagraphContent(
    String paragraph,
    TextStyle baseStyle,
  ) {
    // First, parse markdown at paragraph level (to handle multi-line italics)
    final spans = _parseMarkdown(paragraph, baseStyle);

    // Then render with proper indentation
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }

  /// Parse markdown formatting and create TextSpans
  /// Handles multi-line italics (text between * can span multiple lines)
  List<InlineSpan> _parseMarkdown(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];

    // Parse italics first (multi-line aware)
    final regex = RegExp(r'\*([^*]+)\*', dotAll: true);
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before the match (normal text)
      if (match.start > lastEnd) {
        final normalText = text.substring(lastEnd, match.start);
        spans.addAll(_textToSpans(normalText, baseStyle, false));
      }

      // Add italic text
      final italicText = match.group(1)!;
      spans.addAll(_textToSpans(italicText, baseStyle, true));

      lastEnd = match.end;
    }

    // Add remaining text after last match (or all text if no matches)
    if (lastEnd < text.length) {
      final remainingText = text.substring(lastEnd);
      spans.addAll(_textToSpans(remainingText, baseStyle, false));
    }

    return spans;
  }

  /// Convert text to TextSpans, handling line breaks, indentation (>) and special characters
  List<InlineSpan> _textToSpans(
      String text, TextStyle baseStyle, bool isItalic) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    final style =
        isItalic ? baseStyle.copyWith(fontStyle: FontStyle.italic) : baseStyle;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check if line starts with > (indentation)
      final trimmedLine = line.trimLeft();
      final isIndented = trimmedLine.startsWith('>');
      final lineContent =
          isIndented ? trimmedLine.substring(1).trimLeft() : line;

      // Add indentation if needed
      if (isIndented) {
        spans.add(const TextSpan(text: '    ')); // 4 spaces for indentation
      }

      // Add text if line is not empty
      if (lineContent.isNotEmpty) {
        // Replace special character codes with symbols
        var processedText = lineContent
            .replaceAll('R/', '℟')
            .replaceAll('V/', '℣')
            .replaceAll("'", '\u2019'); // Typographic apostrophe

        // Process character by character to apply red color to symbols
        spans.addAll(_processSpecialCharacters(processedText, style));
      }

      // Add line break if not the last line (even for empty lines to preserve spacing)
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  /// Process special characters (℟ and ℣) with red color
  List<InlineSpan> _processSpecialCharacters(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // Liturgical symbols in red and larger
      if (char == '℟' || char == '℣') {
        // Add buffered text first
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
          buffer.clear();
        }

        // Add symbol in red and larger
        spans.add(TextSpan(
          text: char,
          style: baseStyle.copyWith(
            color: Colors.red,
            fontSize: baseStyle.fontSize! * 1.3, // 30% larger
          ),
        ));
      } else {
        buffer.write(char);
      }
    }

    // Add remaining buffered text
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
    }

    return spans;
  }
}
