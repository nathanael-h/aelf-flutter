import 'package:flutter/material.dart';

/// ============================================
/// YAML TEXT PARSER & WIDGET
/// Handles multi-line italics and line-specific indentation
/// ============================================

class YamlTextSegment {
  final String text;
  final bool isItalic;
  final bool isRubric;
  final bool isSuperscript;

  YamlTextSegment({
    required this.text,
    this.isItalic = false,
    this.isRubric = false,
    this.isSuperscript = false,
  });
}

class YamlTextLine {
  final List<YamlTextSegment> segments;
  final bool hasRightIndent;

  YamlTextLine({required this.segments, this.hasRightIndent = false});
}

class YamlTextParagraph {
  final List<YamlTextLine> lines;

  YamlTextParagraph({required this.lines});
}

class YamlTextParser {
  static const String _starPlaceholder = '\u{E000}';

  static List<YamlTextParagraph> parseText(String content) {
    if (content.isEmpty) return [];
    return content
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .map((p) => YamlTextParagraph(lines: _parseParagraph(p)))
        .toList();
  }

  static List<YamlTextLine> _parseParagraph(String paragraphText) {
    // 1. Pre-process escaped stars and rubric tags
    String processed = paragraphText.replaceAll(r'\*', _starPlaceholder);
    processed =
        processed.replaceAll('[rubric]', '§R').replaceAll('[/rubric]', '§E');

    // 2. Split by literal lines to handle '>' independently for each line
    final rawLines = processed.split('\n');

    List<YamlTextLine> parsedLines = [];
    bool isCurrentlyItalic = false; // Persistent state across lines
    bool isCurrentlyRubric = false;

    for (var rawLine in rawLines) {
      if (rawLine.trim().isEmpty && rawLines.length > 1) continue;

      bool hasRightIndent = rawLine.trimLeft().startsWith('>');
      String lineToParse =
          hasRightIndent ? rawLine.trimLeft().substring(1).trimLeft() : rawLine;

      // 3. Regex to detect format toggles (*, ^, rubrics) within the line
      final regex =
          RegExp(r'(§R)|(§E)|(\*)|(\^([a-zA-Z0-9éèêâàîïôûù]+))|([^*^§]+)');
      final matches = regex.allMatches(lineToParse);

      List<YamlTextSegment> segments = [];

      for (final match in matches) {
        if (match.group(1) != null) {
          // [rubric] start
          isCurrentlyRubric = true;
        } else if (match.group(2) != null) {
          // [/rubric] end
          isCurrentlyRubric = false;
        } else if (match.group(3) != null) {
          // Italic toggle (*)
          isCurrentlyItalic = !isCurrentlyItalic;
        } else if (match.group(4) != null) {
          // Superscript
          segments.add(YamlTextSegment(
            text: match.group(5)!,
            isSuperscript: true,
            isItalic: isCurrentlyItalic,
            isRubric: isCurrentlyRubric,
          ));
        } else if (match.group(6) != null) {
          // Normal text
          String text = match.group(6)!;
          if (text.isNotEmpty) {
            segments.add(YamlTextSegment(
              text: text.replaceAll(_starPlaceholder, '*'),
              isItalic: isCurrentlyItalic,
              isRubric: isCurrentlyRubric,
            ));
          }
        }
      }

      // If a line is empty but we are in a formatting state,
      // we still need to add it or skip it based on your needs.
      parsedLines.add(
          YamlTextLine(segments: segments, hasRightIndent: hasRightIndent));
    }

    return parsedLines;
  }
}

class YamlTextWidget extends StatelessWidget {
  final List<YamlTextParagraph> paragraphs;
  final TextStyle? textStyle;
  final double paragraphSpacing;
  final TextAlign textAlign;
  final Color? redColor;

  const YamlTextWidget({
    super.key,
    required this.paragraphs,
    this.textStyle,
    this.paragraphSpacing = 16.0,
    this.textAlign = TextAlign.left,
    this.redColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveRed = redColor ?? Theme.of(context).colorScheme.error;
    final baseStyle = textStyle ??
        const TextStyle(fontSize: 16.0, height: 1.4, color: Colors.black);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs
          .map((p) => Padding(
                padding: EdgeInsets.only(bottom: paragraphSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: p.lines
                      .map((l) => _buildLine(l, baseStyle, effectiveRed))
                      .toList(),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildLine(YamlTextLine line, TextStyle baseStyle, Color redColor) {
    final spans = <InlineSpan>[];

    for (int i = 0; i < line.segments.length; i++) {
      final segment = line.segments[i];

      // Atomic grouping to prevent line breaks between word and superscript
      if (i + 1 < line.segments.length && line.segments[i + 1].isSuperscript) {
        final nextSegment = line.segments[i + 1];
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Text.rich(
            TextSpan(children: [
              _buildTextSpan(segment, baseStyle, redColor),
              _buildSuperscriptSpan(nextSegment, baseStyle, redColor),
            ]),
          ),
        ));
        i++;
        continue;
      }

      if (segment.isSuperscript) {
        spans.add(_buildSuperscriptSpan(segment, baseStyle, redColor));
      } else {
        spans.add(_buildTextSpan(segment, baseStyle, redColor));
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: line.hasRightIndent ? 24.0 : 0),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: line.hasRightIndent ? TextAlign.right : textAlign,
      ),
    );
  }

  InlineSpan _buildTextSpan(
      YamlTextSegment segment, TextStyle baseStyle, Color redColor) {
    String processedText = _applyTypography(segment.text);
    final subSpans = <InlineSpan>[];

    final symbolRegex = RegExp(r'(℟[12]?|℣|\+|\*)');
    final parts = processedText.split(symbolRegex);
    final matches = symbolRegex.allMatches(processedText).toList();

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        subSpans.add(TextSpan(
          text: parts[i],
          style: _getSegmentStyle(segment, baseStyle, redColor),
        ));
      }
      if (i < matches.length) {
        final symbol = matches[i].group(0)!;
        bool isLarge = symbol.contains('℟') || symbol.contains('℣');

        subSpans.add(TextSpan(
          text: symbol,
          style: _getSegmentStyle(segment, baseStyle, redColor).copyWith(
            color: redColor,
            fontWeight: FontWeight.bold,
            fontSize: isLarge ? (baseStyle.fontSize ?? 16) * 1.2 : null,
          ),
        ));
      }
    }
    return TextSpan(children: subSpans);
  }

  InlineSpan _buildSuperscriptSpan(
      YamlTextSegment segment, TextStyle baseStyle, Color redColor) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.top,
      child: Transform.translate(
        offset: Offset(0, -(baseStyle.fontSize ?? 16.0) * 0.35),
        child: Text(
          segment.text,
          style: _getSegmentStyle(segment, baseStyle, redColor).copyWith(
            fontSize: (baseStyle.fontSize ?? 16.0) * 0.65,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _applyTypography(String text) {
    return text
        .replaceAll('R/', '℟')
        .replaceAll('V/', '℣')
        .replaceAll(' :', '\u00A0:')
        .replaceAll(' !', '\u00A0!')
        .replaceAll(' ?', '\u00A0?')
        .replaceAll(' ;', '\u00A0;')
        .replaceAll("'", '\u2019');
  }

  TextStyle _getSegmentStyle(
      YamlTextSegment segment, TextStyle base, Color red) {
    TextStyle style = base;
    if (segment.isRubric) {
      style = style.copyWith(color: red, fontStyle: FontStyle.italic);
    }
    if (segment.isItalic) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    return style;
  }
}
