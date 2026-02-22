import 'package:flutter/material.dart';

/// ============================================
/// YAML TEXT PARSER
/// Handles text from YAML files with markdown formatting
/// ============================================

/// Represents a text segment with formatting for YAML content
class YamlTextSegment {
  final String text;
  final bool isItalic;
  final bool isRubric;
  final bool hasRightIndent;

  YamlTextSegment({
    required this.text,
    this.isItalic = false,
    this.isRubric = false,
    this.hasRightIndent = false,
  });
}

/// Represents a line of YAML-formatted text
class YamlTextLine {
  final List<YamlTextSegment> segments;
  final bool hasRightIndent;

  YamlTextLine({required this.segments, this.hasRightIndent = false});
}

/// Represents a paragraph of YAML text
class YamlTextParagraph {
  final List<YamlTextLine> lines;

  YamlTextParagraph({required this.lines});
}

/// Parser for YAML-formatted text
/// Handles:
/// - *text* as italic markdown
/// - \* as escaped asterisk (displays as *)
/// - R/ and V/ as liturgical symbols
/// - + and * as special liturgical markers
/// - > at line start as right indent
class YamlTextParser {
  /// Parses YAML text content and returns a list of YamlTextParagraphs
  static List<YamlTextParagraph> parseText(String content) {
    if (content.isEmpty) {
      return [];
    }

    final paragraphs = <YamlTextParagraph>[];

    // Split by double newlines for paragraphs
    final paragraphTexts = content.split('\n\n');

    for (var paragraphText in paragraphTexts) {
      if (paragraphText.trim().isEmpty) continue;

      final lines = _parseParagraph(paragraphText);
      if (lines.isNotEmpty) {
        paragraphs.add(YamlTextParagraph(lines: lines));
      }
    }

    return paragraphs;
  }

  /// Parses a paragraph and extracts all lines with formatting
  static List<YamlTextLine> _parseParagraph(String paragraphText) {
    final lines = <YamlTextLine>[];

    // Split by single newlines for lines
    final lineTexts = paragraphText.split('\n');

    for (var lineText in lineTexts) {
      if (lineText.trim().isEmpty) continue;

      // Check for right indent (line starts with >)
      bool hasRightIndent = lineText.trimLeft().startsWith('>');
      if (hasRightIndent) {
        lineText = lineText.trimLeft().substring(1).trimLeft();
      }

      final segments = _parseLine(lineText, hasRightIndent);
      if (segments.isNotEmpty) {
        lines.add(
            YamlTextLine(segments: segments, hasRightIndent: hasRightIndent));
      }
    }

    return lines;
  }

  /// Parses a single line and extracts segments with italic and rubric formatting
  static List<YamlTextSegment> _parseLine(
      String lineText, bool hasRightIndent) {
    final segments = <YamlTextSegment>[];

    // First, replace escaped asterisks with a placeholder
    final placeholder = '\u{E000}'; // Private use area character
    lineText = lineText.replaceAll(r'\*', placeholder);

    // Placeholders for rubric tags
    final rubricStartPlaceholder = '\u{E001}';
    final rubricEndPlaceholder = '\u{E002}';
    lineText = lineText.replaceAll('[rubric]', rubricStartPlaceholder);
    lineText = lineText.replaceAll(r'[/rubric]', rubricEndPlaceholder);

    // Now parse markdown italic (*text*) and rubric tags
    final buffer = StringBuffer();
    bool isItalic = false;
    bool isRubric = false;

    for (int i = 0; i < lineText.length; i++) {
      final char = lineText[i];

      if (char == rubricStartPlaceholder) {
        // Start rubric mode
        if (buffer.isNotEmpty) {
          segments.add(YamlTextSegment(
            text: buffer.toString().replaceAll(placeholder, '*'),
            isItalic: isItalic,
            isRubric: isRubric,
            hasRightIndent: hasRightIndent,
          ));
          buffer.clear();
        }
        isRubric = true;
      } else if (char == rubricEndPlaceholder) {
        // End rubric mode
        if (buffer.isNotEmpty) {
          segments.add(YamlTextSegment(
            text: buffer.toString().replaceAll(placeholder, '*'),
            isItalic: isItalic,
            isRubric: isRubric,
            hasRightIndent: hasRightIndent,
          ));
          buffer.clear();
        }
        isRubric = false;
      } else if (char == '*') {
        // Toggle italic mode
        if (buffer.isNotEmpty) {
          segments.add(YamlTextSegment(
            text: buffer.toString().replaceAll(placeholder, '*'),
            isItalic: isItalic,
            isRubric: isRubric,
            hasRightIndent: hasRightIndent,
          ));
          buffer.clear();
        }
        isItalic = !isItalic;
      } else {
        buffer.write(char);
      }
    }

    // Add remaining text
    if (buffer.isNotEmpty) {
      segments.add(YamlTextSegment(
        text: buffer.toString().replaceAll(placeholder, '*'),
        isItalic: isItalic,
        isRubric: isRubric,
        hasRightIndent: hasRightIndent,
      ));
    }

    return segments;
  }
}

/// Widget to display YAML-formatted text
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
    // Use provided redColor or fall back to the theme's secondary color
    final Color effectiveRed =
        redColor ?? Theme.of(context).colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final index = entry.key;
        final paragraph = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < paragraphs.length - 1 ? paragraphSpacing : 0,
          ),
          child: _buildParagraph(paragraph, effectiveRed),
        );
      }).toList(),
    );
  }

  Widget _buildParagraph(YamlTextParagraph paragraph, Color redColor) {
    final baseStyle = textStyle ??
        const TextStyle(
          fontSize: 16.0,
          height: 1.3,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraph.lines.map((line) {
        return _buildLine(line, baseStyle, redColor);
      }).toList(),
    );
  }

  Widget _buildLine(YamlTextLine line, TextStyle baseStyle, Color redColor) {
    final spans = <InlineSpan>[];

    for (var segment in line.segments) {
      // Replace special characters and symbols (but handle R/1 and R/2 specially)
      var text = segment.text
          .replaceAll(RegExp(r'R/(?![12])'), '℟') // R/ not followed by 1 or 2
          .replaceAll('V/', '℣')
          .replaceAll('\u00A0', '\u00A0') // Keep non-breaking spaces
          .replaceAll(' !', '\u00A0!')
          .replaceAll(' :', '\u00A0:')
          .replaceAll(' ?', '\u00A0?')
          .replaceAll(' ;', '\u00A0;')
          .replaceAll(' *', '\u00A0*')
          .replaceAll(' +', '\u00A0+')
          .replaceAll("'", '\u2019'); // Typographic apostrophe

      // Process text character by character for special symbols
      final buffer = StringBuffer();

      for (int i = 0; i < text.length; i++) {
        final char = text[i];

        // Check for R/1 or R/2 pattern
        if (char == 'R' && i + 2 < text.length && text[i + 1] == '/') {
          final nextChar = text[i + 2];
          if (nextChar == '1' || nextChar == '2') {
            // Flush buffer first
            if (buffer.isNotEmpty) {
              spans.add(TextSpan(
                text: buffer.toString(),
                style: _getTextStyle(baseStyle, segment, redColor),
              ));
              buffer.clear();
            }

            // Add ℟ symbol with subscript number, with accessibility
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Semantics(
                label: 'Refrain $nextChar',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '℟',
                        style: _getTextStyle(baseStyle, segment, redColor)
                            .copyWith(
                          color: redColor,
                          fontSize: (baseStyle.fontSize ?? 16.0) * 1.3,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, 2),
                        child: Text(
                          nextChar,
                          style: _getTextStyle(baseStyle, segment, redColor)
                              .copyWith(
                            color: redColor,
                            fontSize: (baseStyle.fontSize ?? 16.0) * 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));

            i += 2; // Skip the /1 or /2
            continue;
          }
        }

        // Special characters (* and +) in red, normal size
        if (char == '+' || char == '*') {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(
              text: buffer.toString(),
              style: _getTextStyle(baseStyle, segment, redColor),
            ));
            buffer.clear();
          }

          spans.add(TextSpan(
            text: char,
            style: _getTextStyle(baseStyle, segment, redColor).copyWith(
              color: redColor,
            ),
          ));
        }
        // Liturgical symbols (℟ and ℣) in red and larger, with accessibility
        else if (char == '℟' || char == '℣') {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(
              text: buffer.toString(),
              style: _getTextStyle(baseStyle, segment, redColor),
            ));
            buffer.clear();
          }

          final semanticLabel = char == '℟' ? 'Refrain' : 'Verset';
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Semantics(
              label: semanticLabel,
              child: ExcludeSemantics(
                child: Text(
                  char,
                  style: _getTextStyle(baseStyle, segment, redColor).copyWith(
                    color: redColor,
                    fontSize: (baseStyle.fontSize ?? 16.0) * 1.3,
                  ),
                ),
              ),
            ),
          ));
        } else {
          buffer.write(char);
        }
      }

      // Add remaining text
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(
          text: buffer.toString(),
          style: _getTextStyle(baseStyle, segment, redColor),
        ));
      }
    }

    Widget textWidget = Text.rich(
      TextSpan(children: spans),
      textAlign: line.hasRightIndent ? TextAlign.right : textAlign,
    );

    // Apply indentation if right indent is present
    if (line.hasRightIndent) {
      textWidget = Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: textWidget,
      );
    }

    return textWidget;
  }

  TextStyle _getTextStyle(
      TextStyle baseStyle, YamlTextSegment segment, Color redColor) {
    var style = baseStyle;

    if (segment.isItalic) {
      style = style.copyWith(
        fontStyle: FontStyle.italic,
      );
    }

    // Rubric: red and italic
    if (segment.isRubric) {
      style = style.copyWith(
        fontStyle: FontStyle.italic,
        color: redColor,
      );
    }

    return style;
  }
}
