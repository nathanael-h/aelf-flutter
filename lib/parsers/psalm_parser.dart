import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
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
  static const double superscriptOffset = TextConfig.superscriptOffset;
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

/// Parser for psalms with verse numbers
class PsalmParser {
  /// Parses HTML and returns a list of PsalmParagraphs
  static List<PsalmParagraph> parseHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final paragraphs = <PsalmParagraph>[];

    // Get all <p> elements
    final pElements = document.querySelectorAll('p');

    for (var pElement in pElements) {
      final verses = _parseParagraph(pElement);
      if (verses.isNotEmpty) {
        paragraphs.add(PsalmParagraph(verses: verses));
      }
    }

    return paragraphs;
  }

  /// Parses a <p> element and extracts all verses with formatting
  static List<Verse> _parseParagraph(dom.Element pElement) {
    final verses = <Verse>[];
    int? currentVerseNumber;
    List<TextLine> currentLines = [];
    List<TextSegment> currentLine = [];

    void finalizeVerse() {
      if (currentVerseNumber != null && currentLines.isNotEmpty) {
        verses.add(Verse(
          number: currentVerseNumber!,
          lines: List.from(currentLines),
        ));
        currentLines.clear();
      }
    }

    void finalizeLine() {
      if (currentLine.isNotEmpty) {
        currentLines.add(TextLine(segments: List.from(currentLine)));
        currentLine.clear();
      }
    }

    void processNode(
      dom.Node node, {
      bool isUnderlined = false,
      bool isItalic = false,
      String? className,
    }) {
      if (node is dom.Element) {
        // If it's a verse number
        if (node.className == 'verse_number') {
          finalizeLine();
          finalizeVerse();
          currentVerseNumber = int.tryParse(node.text.trim());
        }
        // If it's a <br>, it marks a new line
        else if (node.localName == 'br') {
          finalizeLine();
        }
        // If it's a <u> (underlined text)
        else if (node.localName == 'u') {
          for (var child in node.nodes) {
            processNode(child,
                isUnderlined: true, isItalic: isItalic, className: className);
          }
        }
        // If it's an <em> or <i> (italic text)
        else if (node.localName == 'em' || node.localName == 'i') {
          for (var child in node.nodes) {
            processNode(child,
                isUnderlined: isUnderlined,
                isItalic: true,
                className: className);
          }
        }
        // If it's a span with a class
        else if (node.localName == 'span' && node.className.isNotEmpty) {
          final spanClass = node.className;
          for (var child in node.nodes) {
            processNode(child,
                isUnderlined: isUnderlined,
                isItalic: isItalic,
                className: spanClass);
          }
        }
        // Other elements, process children
        else {
          for (var child in node.nodes) {
            processNode(child,
                isUnderlined: isUnderlined,
                isItalic: isItalic,
                className: className);
          }
        }
      }
      // If it's plain text
      else if (node is dom.Text) {
        final text = node.text;
        if (text.isNotEmpty && text.trim().isNotEmpty) {
          currentLine.add(TextSegment(
            text: text,
            isUnderlined: isUnderlined,
            isItalic: isItalic,
            className: className,
          ));
        }
      }
    }

    // Process all nodes in the paragraph
    for (var node in pElement.nodes) {
      processNode(node);
    }

    // Finalize the last line and last verse
    finalizeLine();
    finalizeVerse();

    return verses;
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

        // Check if this line has "droite" class
        final hasRightClass =
            verse.lines[i].segments.any((seg) => seg.className == 'droite');

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
                  child: _buildLineText(
                    verse.lines[i],
                    alignRight: hasRightClass,
                  ),
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

  Widget _buildLineText(TextLine line, {bool alignRight = false}) {
    final spans = <InlineSpan>[];

    final baseStyle = verseStyle ??
        TextStyle(
          fontSize: PsalmConfig.textSize,
          height: PsalmConfig.lineSpacing,
        );

    bool hasSpaceClass = false;

    for (var segment in line.segments) {
      // Check for special classes
      if (segment.className == 'espace') {
        hasSpaceClass = true;
      }

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

        // Special characters as superscript in red
        if (char == '+' || char == '*') {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(
              text: buffer.toString(),
              style: _getTextStyle(baseStyle, segment),
            ));
            buffer.clear();
          }

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Transform.translate(
                offset: const Offset(0, PsalmConfig.superscriptOffset),
                child: Text(
                  char,
                  style: baseStyle.copyWith(
                    color: PsalmConfig.redColor,
                    fontSize:
                        baseStyle.fontSize! * PsalmConfig.superscriptScale,
                  ),
                ),
              ),
            ),
          );
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
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
    );

    // Apply indentation if "espace" class is present
    if (hasSpaceClass) {
      textWidget = Padding(
        padding: const EdgeInsets.only(left: PsalmConfig.spaceIndentation),
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

/// Complete widget to display a psalm from HTML
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
    final paragraphs = PsalmParser.parseHtml(htmlContent);

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
