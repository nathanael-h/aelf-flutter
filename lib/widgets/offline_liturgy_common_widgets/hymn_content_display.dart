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

      // Check if paragraph is indented (starts with >)
      final isIndented = paragraph.startsWith('>');

      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i < paragraphs.length - 1 ? 12.0 : 0,
            left: isIndented ? 24.0 : 0, // Indent paragraphs with >
          ),
          child: _buildParagraphContent(paragraph, baseStyle, isIndented),
        ),
      );
    }

    return widgets;
  }

  /// Build the content of a single paragraph
  Widget _buildParagraphContent(
    String paragraph,
    TextStyle baseStyle,
    bool isIndented,
  ) {
    // Remove > prefix from indented paragraphs
    String text = paragraph;
    if (isIndented) {
      text = paragraph
          .split('\n')
          .map((line) => line.trim().startsWith('>') ? line.substring(1).trim() : line)
          .join('\n');
    }

    // Parse markdown-like formatting
    final spans = _parseMarkdown(text, baseStyle);

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

  /// Convert text to TextSpans, handling line breaks
  List<InlineSpan> _textToSpans(String text, TextStyle baseStyle, bool isItalic) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    final style = isItalic
        ? baseStyle.copyWith(fontStyle: FontStyle.italic)
        : baseStyle;

    for (int i = 0; i < lines.length; i++) {
      // Add text if line is not empty
      if (lines[i].isNotEmpty) {
        spans.add(TextSpan(text: lines[i], style: style));
      }

      // Add line break if not the last line (even for empty lines to preserve spacing)
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }
}
