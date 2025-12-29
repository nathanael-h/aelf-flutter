import 'package:flutter/material.dart';
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';

/// ============================================
/// PSALM-SPECIFIC CONFIGURATION
/// ============================================
class PsalmConfig extends TextConfig {
  // ===== PSALM-SPECIFIC =====
  /// Spacing between verse number and text (in pixels)
  static const double verseNumberSpacing = 4.0;

  /// Font size for verse numbers (slightly smaller than text)
  static const double verseNumberSize = 10.0;

  /// Width reserved for verse numbers (in pixels)
  static const double verseNumberWidth = 30.0;

  /// Font weight for verse numbers
  static const FontWeight verseNumberWeight = FontWeight.bold;

  // Re-expose parent class constants for convenience
  static const double paragraphSpacing = TextConfig.paragraphSpacing;
  static const double lineSpacing = TextConfig.lineSpacing;
  static const double textSize = TextConfig.textSize;
  static const double superscriptOffset =
      3.0; // Align with top of text (override TextConfig default of -2.0)
  static const double superscriptScale = TextConfig.superscriptScale;
  static const double spaceIndentation = TextConfig.spaceIndentation;
  static const Color redColor = TextConfig.redColor;
}

/// ============================================
/// PSALM PARSER (with verse numbers)
/// ============================================

/// Represents a verse with its number and formatted lines
class Verse {
  final int number;
  final List<TextLine> lines;

  Verse({
    required this.number,
    required this.lines,
  });
}

/// Represents a paragraph containing one or more verses
class PsalmParagraph {
  final List<Verse> verses;

  PsalmParagraph({required this.verses});
}

/// Parser for psalms with verse numbers (YAML/Markdown format)
class PsalmParser {
  /// Parses YAML/Markdown content and returns a list of PsalmParagraphs
  /// Format:
  /// - {n} for verse numbers
  /// - _text_ or **text** for underlined/emphasized text
  /// - > at start of line for right indentation
  /// - *, +, R/, V/ for special markers
  static List<PsalmParagraph> parseContent(String content) {
    final paragraphs = <PsalmParagraph>[];

    // Split by double newlines to get paragraphs
    final paragraphTexts = content.split('\n\n');

    for (var paragraphText in paragraphTexts) {
      if (paragraphText.trim().isEmpty) continue;

      final verses = _parseParagraph(paragraphText);
      if (verses.isNotEmpty) {
        paragraphs.add(PsalmParagraph(verses: verses));
      }
    }

    return paragraphs;
  }

  /// Parses a paragraph and extracts all verses with formatting
  static List<Verse> _parseParagraph(String paragraphText) {
    final verses = <Verse>[];
    int? currentVerseNumber;
    List<TextLine> currentLines = [];

    final lines = paragraphText.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      // Check for verse number {n}
      final verseMatch = RegExp(r'^\{(\d+)\}').firstMatch(line);
      if (verseMatch != null) {
        // Finalize previous verse
        if (currentVerseNumber != null && currentLines.isNotEmpty) {
          verses.add(Verse(
            number: currentVerseNumber,
            lines: List.from(currentLines),
          ));
          currentLines.clear();
        }

        // Start new verse
        currentVerseNumber = int.parse(verseMatch.group(1)!);
        // Remove verse number from line
        line = line.substring(verseMatch.end);
      }

      // Parse the line content
      if (line.trim().isNotEmpty) {
        final parsedLine = _parseLine(line);
        currentLines.add(parsedLine);
      }
    }

    // Finalize last verse
    if (currentVerseNumber != null && currentLines.isNotEmpty) {
      verses.add(Verse(
        number: currentVerseNumber,
        lines: List.from(currentLines),
      ));
    }

    return verses;
  }

  /// Parses a single line with markdown formatting
  static TextLine _parseLine(String line) {
    final segments = <TextSegment>[];
    bool hasRightIndent = false;

    // Check for > (right indentation)
    if (line.trimLeft().startsWith('>')) {
      hasRightIndent = true;
      line = line.trimLeft().substring(1).trimLeft();
    }

    // Parse markdown formatting: _text_ for underlined
    int i = 0;
    StringBuffer buffer = StringBuffer();
    bool isUnderlined = false;

    while (i < line.length) {
      if (line[i] == '_') {
        // Save current buffer
        if (buffer.isNotEmpty) {
          segments.add(TextSegment(
            text: buffer.toString(),
            isUnderlined: isUnderlined,
            isItalic: false,
            hasRightIndent: hasRightIndent,
          ));
          buffer.clear();
        }
        // Toggle underline
        isUnderlined = !isUnderlined;
        i++;
      } else if (i + 1 < line.length && line[i] == '*' && line[i + 1] == '*') {
        // Save current buffer
        if (buffer.isNotEmpty) {
          segments.add(TextSegment(
            text: buffer.toString(),
            isUnderlined: isUnderlined,
            isItalic: false,
            hasRightIndent: hasRightIndent,
          ));
          buffer.clear();
        }
        // Toggle italic (using **text**)
        isUnderlined = !isUnderlined;
        i += 2;
      } else {
        buffer.write(line[i]);
        i++;
      }
    }

    // Add remaining buffer
    if (buffer.isNotEmpty) {
      segments.add(TextSegment(
        text: buffer.toString(),
        isUnderlined: isUnderlined,
        isItalic: false,
        hasRightIndent: hasRightIndent,
      ));
    }

    return TextLine(segments: segments, hasRightIndent: hasRightIndent);
  }
}

/// Widget to display a psalm with verse numbers
class PsalmWidget extends StatelessWidget {
  final List<PsalmParagraph> paragraphs;
  final TextStyle? verseStyle;
  final TextStyle? numberStyle;
  final double paragraphSpacing;
  final double numberSpacing;

  const PsalmWidget({
    super.key,
    required this.paragraphs,
    this.verseStyle,
    this.numberStyle,
    this.paragraphSpacing = PsalmConfig.paragraphSpacing,
    this.numberSpacing = PsalmConfig.verseNumberSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final index = entry.key;
        final paragraph = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < paragraphs.length - 1 ? paragraphSpacing : 0,
          ),
          child: _buildParagraph(paragraph),
        );
      }).toList(),
    );
  }

  Widget _buildParagraph(PsalmParagraph paragraph) {
    final lineWidgets = <Widget>[];

    for (var verse in paragraph.verses) {
      for (int i = 0; i < verse.lines.length; i++) {
        final isFirstLine = i == 0;

        lineWidgets.add(
          Padding(
            padding: EdgeInsets.only(
              left: isFirstLine
                  ? 0
                  : (PsalmConfig.verseNumberWidth + numberSpacing),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse number (only on the first line of the verse)
                if (isFirstLine) ...[
                  SizedBox(
                    width: PsalmConfig.verseNumberWidth,
                    child: Transform.translate(
                      offset: const Offset(0, PsalmConfig.superscriptOffset),
                      child: Text(
                        '${verse.number}',
                        textAlign: TextAlign.right,
                        style: numberStyle ??
                            TextStyle(
                              fontWeight: PsalmConfig.verseNumberWeight,
                              color: PsalmConfig.redColor,
                              fontSize: PsalmConfig.verseNumberSize,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(width: numberSpacing),
                ],
                // Line text
                Expanded(
                  child: _buildLineText(verse.lines[i]),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lineWidgets,
    );
  }

  Widget _buildLineText(TextLine line) {
    final spans = <InlineSpan>[];

    final baseStyle = verseStyle ??
        TextStyle(
          fontSize: PsalmConfig.textSize,
          height: PsalmConfig.lineSpacing,
        );

    for (var segment in line.segments) {

      // Replace special characters and symbols
      var text = segment.text
          .replaceAll('R/', '℟')
          .replaceAll('V/', '℣')
          .replaceAll('&nbsp;', '\u00A0')
          .replaceAll("'", '\u2019'); // Typographic apostrophe

      // Process text character by character
      final buffer = StringBuffer();

      for (int i = 0; i < text.length; i++) {
        final char = text[i];

        // Special characters (* and +) in red, same level as text
        if (char == '+' || char == '*') {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(
              text: buffer.toString(),
              style: _getTextStyle(baseStyle, segment),
            ));
            buffer.clear();
          }

          spans.add(TextSpan(
            text: char,
            style: _getTextStyle(baseStyle, segment).copyWith(
              color: PsalmConfig.redColor,
            ),
          ));
        }
        // Liturgical symbols in red (not superscript)
        else if (char == '℟' || char == '℣') {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(
              text: buffer.toString(),
              style: _getTextStyle(baseStyle, segment),
            ));
            buffer.clear();
          }

          spans.add(TextSpan(
            text: char,
            style: _getTextStyle(baseStyle, segment).copyWith(
              color: PsalmConfig.redColor,
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
          style: _getTextStyle(baseStyle, segment),
        ));
      }
    }

    Widget textWidget = Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.left,
    );

    // Apply right indentation if needed
    if (line.hasRightIndent) {
      textWidget = Padding(
        padding: const EdgeInsets.only(left: 25.0), // Shift 25 pixels to the right
        child: textWidget,
      );
    }

    return textWidget;
  }

  TextStyle _getTextStyle(TextStyle baseStyle, TextSegment segment) {
    var style = baseStyle;

    if (segment.isUnderlined) {
      style = style.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: Colors.black,
      );
    }

    if (segment.isItalic) {
      style = style.copyWith(
        fontStyle: FontStyle.italic,
      );
    }

    return style;
  }
}

/// Complete widget to display a psalm from YAML/Markdown content
class PsalmFromHtml extends StatelessWidget {
  final String htmlContent;
  final String? title;
  final TextStyle? verseStyle;
  final TextStyle? numberStyle;
  final TextStyle? titleStyle;

  const PsalmFromHtml({
    super.key,
    required this.htmlContent,
    this.title,
    this.verseStyle,
    this.numberStyle,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final paragraphs = PsalmParser.parseContent(htmlContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: titleStyle ??
                const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
        ],
        PsalmWidget(
          paragraphs: paragraphs,
          verseStyle: verseStyle,
          numberStyle: numberStyle,
        ),
      ],
    );
  }
}
