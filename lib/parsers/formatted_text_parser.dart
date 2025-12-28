import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// ============================================
/// DISPLAY PARAMETERS CONFIGURATION
/// Modify these values to customize the appearance
/// ============================================
class TextConfig {
  // ===== COLORS =====
  /// Color for special symbols (+, *, ℟, ℣)
  // Default fallback color. Prefer using Theme.of(context).colorScheme.secondary, it provied different red colors for light and dark theme.
  static const Color redColor = Colors.red;

  // ===== SPACING =====
  /// Spacing between paragraphs (in pixels)
  static const double paragraphSpacing = 16.0;

  /// Spacing between text lines (line height)
  static const double lineSpacing = 1.3;

  /// Indentation for <span class="space">
  static const double spaceIndentation = 20.0;

  // ===== SIZES =====
  /// Font size for text
  static const double textSize = 16.0;

  /// Scale factor for liturgical symbols (℟, ℣)
  static const double liturgicalSymbolsScale = 1.3;

  // ===== ADDITIONAL STYLES =====
  /// Vertical offset for superscript (negative = up)
  static const double superscriptOffset = -2.0;

  /// Scale factor for superscript characters
  static const double superscriptScale = 0.7;
}

/// ============================================
/// BASE TEXT PARSER (no verse numbers)
/// ============================================

/// Represents a text segment with formatting
class TextSegment {
  final String text;
  final bool isUnderlined;
  final bool isItalic;
  final String? className;

  TextSegment({
    required this.text,
    this.isUnderlined = false,
    this.isItalic = false,
    this.className,
  });
}

/// Represents a line of formatted text
class TextLine {
  final List<TextSegment> segments;

  TextLine({required this.segments});
}

/// Represents a paragraph of text
class TextParagraph {
  final List<TextLine> lines;

  TextParagraph({required this.lines});
}

/// Base parser for formatted text (no verse numbers)
class FormattedTextParser {
  /// Parses HTML and returns a list of TextParagraphs
  static List<TextParagraph> parseHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final paragraphs = <TextParagraph>[];

    // Get all <p> elements
    final pElements = document.querySelectorAll('p');

    for (var pElement in pElements) {
      final lines = _parseParagraph(pElement);
      if (lines.isNotEmpty) {
        paragraphs.add(TextParagraph(lines: lines));
      }
    }

    return paragraphs;
  }

  /// Parses a <p> element and extracts all lines with formatting
  static List<TextLine> _parseParagraph(dom.Element pElement) {
    List<TextLine> lines = [];
    List<TextSegment> currentLine = [];

    void finalizeLine() {
      if (currentLine.isNotEmpty) {
        lines.add(TextLine(segments: List.from(currentLine)));
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
        // Skip verse numbers
        if (node.className == 'verse_number') {
          return;
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

    // Finalize the last line
    finalizeLine();

    return lines;
  }
}

/// Widget to display formatted text (no verse numbers)
class FormattedTextWidget extends StatelessWidget {
  final List<TextParagraph> paragraphs;
  final TextStyle? textStyle;
  final double paragraphSpacing;
  final TextAlign textAlign;
  final Color? redColor;

  const FormattedTextWidget({
    super.key,
    required this.paragraphs,
    this.textStyle,
    this.paragraphSpacing = TextConfig.paragraphSpacing,
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

  Widget _buildParagraph(TextParagraph paragraph, Color redColor) {
    final baseStyle = textStyle ??
        TextStyle(
          fontSize: TextConfig.textSize,
          height: TextConfig.lineSpacing,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraph.lines.map((line) {
        return _buildLine(line, baseStyle, redColor);
      }).toList(),
    );
  }

  Widget _buildLine(TextLine line, TextStyle baseStyle, Color redColor) {
    final spans = <InlineSpan>[];
    bool hasIndentationClass = false;
    bool hasRightClass = false;

    for (var segment in line.segments) {
      // Check for special classes
      if (segment.className == 'indentation') {
        hasIndentationClass = true;
      } else if (segment.className == 'align-right') {
        hasRightClass = true;
      }

      // Replace special characters and symbols
      var text = segment.text
          .replaceAll('R/', '℟')
          .replaceAll('V/', '℣')
          .replaceAll('&nbsp;', '\u00A0')
          .replaceAll(' !', '\u00A0!')
          .replaceAll(' :', '\u00A0:')
          .replaceAll(' ?', '\u00A0?')
          .replaceAll(' ;', '\u00A0;')
          .replaceAll(' *', '\u00A0*')
          .replaceAll(' +', '\u00A0')
          .replaceAll("'", '\u2019'); // Typographic apostrophe

      // Process text character by character
      final buffer = StringBuffer();

      for (int i = 0; i < text.length; i++) {
        final char = text[i];

        // Special characters (* and +) in red, normal size (not superscript)
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
              color: redColor,
            ),
          ));
        }
        // Liturgical symbols (℟ and ℣) in red and larger
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
              color: redColor,
              fontSize: baseStyle.fontSize! * TextConfig.liturgicalSymbolsScale,
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
      textAlign: hasRightClass ? TextAlign.right : textAlign,
    );

    // Apply indentation if "space" class is present
    if (hasIndentationClass) {
      textWidget = Padding(
        padding: const EdgeInsets.only(left: TextConfig.spaceIndentation),
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
