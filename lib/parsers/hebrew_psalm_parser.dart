import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';

/// ============================================
/// HEBREW PSALM CONFIGURATION
/// ============================================
class HebrewPsalmConfig extends TextConfig {
  /// Spacing between verse number and text (in pixels)
  static const double verseNumberSpacing = 8.0;

  /// Font size for verse numbers
  static const double verseNumberSize = 14.0;

  /// Font weight for verse numbers
  static const FontWeight verseNumberWeight = FontWeight.bold;

  // Re-expose parent class constants for convenience
  static const double paragraphSpacing = TextConfig.paragraphSpacing;
  static const double lineSpacing = TextConfig.lineSpacing;
  static const double textSize = TextConfig.textSize;
  static const Color redColor = TextConfig.redColor;
}

/// Parser for Hebrew psalms with Hebrew letter verse numbers
class HebrewPsalmParser {
  /// Hebrew letters used as verse numbers
  /// Note: 15 is יה and 16 is יו (special notation to avoid spelling divine name)
  static const hebrewNumbers = [
    // 1-10
    'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט', 'י',
    // 11-20
    'יא', 'יב', 'יג', 'יד', 'יה', 'יו', 'יז', 'יח', 'יט', 'כ',
    // 21-30
    'כא', 'כב', 'כג', 'כד', 'כה', 'כו', 'כז', 'כח', 'כט', 'ל',
    // 31-40
    'לא', 'לב', 'לג', 'לד', 'לה', 'לו', 'לז', 'לח', 'לט', 'מ',
    // 41-50
    'מא', 'מב', 'מג', 'מד', 'מה', 'מו', 'מז', 'מח', 'מט', 'נ',
    // 51-60
    'נא', 'נב', 'נג', 'נד', 'נה', 'נו', 'נז', 'נח', 'נט', 'ס',
    // 61-70
    'סא', 'סב', 'סג', 'סד', 'סה', 'סו', 'סז', 'סח', 'סט', 'ע',
    // 71-80
    'עא', 'עב', 'עג', 'עד', 'עה', 'עו', 'עז', 'עח', 'עט', 'פ',
    // 81-90
    'פא', 'פב', 'פג', 'פד', 'פה', 'פו', 'פז', 'פח', 'פט', 'צ',
    // 91-100
    'צא', 'צב', 'צג', 'צד', 'צה', 'צו', 'צז', 'צח', 'צט', 'ק',
    // 101-110
    'קא', 'קב', 'קג', 'קד', 'קה', 'קו', 'קז', 'קח', 'קט', 'קי',
    // 111-120
    'קיא', 'קיב', 'קיג', 'קיד', 'קטו', 'קטז', 'קיז', 'קיח', 'קיט', 'קכ',
    // 121-130
    'קכא', 'קכב', 'קכג', 'קכד', 'קכה', 'קכו', 'קכז', 'קכח', 'קכט', 'קל',
    // 131-140
    'קלא', 'קלב', 'קלג', 'קלד', 'קלה', 'קלו', 'קלז', 'קלח', 'קלט', 'קמ',
    // 141-150
    'קמא', 'קמב', 'קמג', 'קמד', 'קמה', 'קמו', 'קמז', 'קמח', 'קמט', 'קנ',
    // 151-176 (for longest psalms like Psalm 119)
    'קנא', 'קנב', 'קנג', 'קנד', 'קנה', 'קנו', 'קנז', 'קנח', 'קנט', 'קס',
    'קסא', 'קסב', 'קסג', 'קסד', 'קסה', 'קסו', 'קסז', 'קסח', 'קסט', 'קע',
    'קעא', 'קעב', 'קעג', 'קעד', 'קעה', 'קעו',
  ];

  /// Petusha (paragraph marker) - should also be highlighted in red
  static const petusha = 'פ';

  /// Parses HTML and returns a list of TextSpans with verse numbers in red
  static List<InlineSpan> parseHtml(String htmlContent, TextStyle baseStyle) {
    final document = html_parser.parse(htmlContent);
    final spans = <InlineSpan>[];

    // Get all <p> elements
    final pElements = document.querySelectorAll('p');

    for (var i = 0; i < pElements.length; i++) {
      final pElement = pElements[i];
      _parseParagraph(pElement, spans, baseStyle);

      // Add spacing between paragraphs
      if (i < pElements.length - 1) {
        spans.add(const TextSpan(text: '\n\n'));
      }
    }

    return spans;
  }

  /// Parses a <p> element and adds spans to the list
  static void _parseParagraph(
    dom.Element pElement,
    List<InlineSpan> spans,
    TextStyle baseStyle,
  ) {
    void processNode(dom.Node node) {
      if (node is dom.Text) {
        final text = node.text;
        _processTextWithVerseNumbers(text, spans, baseStyle);
      } else if (node is dom.Element) {
        if (node.localName == 'br') {
          spans.add(const TextSpan(text: '\n'));
        } else {
          // Process children
          for (var child in node.nodes) {
            processNode(child);
          }
        }
      }
    }

    for (var node in pElement.nodes) {
      processNode(node);
    }
  }

  /// Processes text and highlights Hebrew letter verse numbers in red
  static void _processTextWithVerseNumbers(
    String text,
    List<InlineSpan> spans,
    TextStyle baseStyle,
  ) {
    final buffer = StringBuffer();
    int i = 0;

    while (i < text.length) {
      final currentChar = text[i];

      // Special case: check for petusha (isolated פ at end of verse)
      if (currentChar == petusha) {
        // Petusha must be preceded by whitespace (or be at start) AND followed by whitespace/end
        final precededBySpace = i == 0 || text[i - 1].trim().isEmpty;
        final followedBySpaceOrEnd = i + 1 >= text.length || text[i + 1].trim().isEmpty;

        if (precededBySpace && followedBySpaceOrEnd) {
          // Flush the buffer
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
            buffer.clear();
          }

          // Add the petusha in red
          spans.add(TextSpan(
            text: petusha,
            style: baseStyle.copyWith(
              color: HebrewPsalmConfig.redColor,
              fontWeight: HebrewPsalmConfig.verseNumberWeight,
            ),
          ));

          i++;
          continue;
        }
      }

      // Check if this is at the start of a line or after whitespace
      final isStartOfSegment = i == 0 ||
          (i > 0 && text[i - 1].trim().isEmpty);

      if (isStartOfSegment) {
        // Try to match multi-character Hebrew numbers first (longer matches first)
        String? matchedNumber;
        int matchLength = 0;

        // Check for three-character numbers (קיא, קכא, etc.)
        if (i + 2 < text.length) {
          final threeChar = text.substring(i, i + 3);
          if (hebrewNumbers.contains(threeChar)) {
            // Check if followed by space
            if (i + 3 < text.length && text[i + 3].trim().isEmpty) {
              matchedNumber = threeChar;
              matchLength = 3;
            }
          }
        }

        // Check for two-character numbers (יא, יב, כא, etc.)
        if (matchedNumber == null && i + 1 < text.length) {
          final twoChar = text.substring(i, i + 2);
          if (hebrewNumbers.contains(twoChar)) {
            // Check if followed by space
            if (i + 2 < text.length && text[i + 2].trim().isEmpty) {
              matchedNumber = twoChar;
              matchLength = 2;
            }
          }
        }

        // If no multi-character match, try single character
        if (matchedNumber == null) {
          final oneChar = text[i];
          if (hebrewNumbers.contains(oneChar)) {
            // Check if followed by space
            if (i + 1 < text.length && text[i + 1].trim().isEmpty) {
              matchedNumber = oneChar;
              matchLength = 1;
            }
          }
        }

        if (matchedNumber != null) {
          // Flush the buffer
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
            buffer.clear();
          }

          // Add the verse number in red
          spans.add(TextSpan(
            text: matchedNumber,
            style: baseStyle.copyWith(
              color: HebrewPsalmConfig.redColor,
              fontWeight: HebrewPsalmConfig.verseNumberWeight,
            ),
          ));

          // Add spacing after verse number
          spans.add(TextSpan(
            text: ' ',
            style: baseStyle,
          ));

          // Skip the verse number and the following space
          i += matchLength + 1;
          continue;
        }
      }

      buffer.write(text[i]);
      i++;
    }

    // Flush remaining buffer
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
    }
  }
}

/// Widget to display a Hebrew psalm from HTML
class HebrewPsalmFromHtml extends StatelessWidget {
  final String htmlContent;
  final String? title;
  final TextStyle? textStyle;
  final TextStyle? titleStyle;

  const HebrewPsalmFromHtml({
    super.key,
    required this.htmlContent,
    this.title,
    this.textStyle,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = textStyle ??
        const TextStyle(
          fontFamily: 'GentiumPlus',
          fontSize: 18,
          height: 1.6,
          color: Colors.black,
        );

    final spans = HebrewPsalmParser.parseHtml(htmlContent, baseStyle);

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
        Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text.rich(
              TextSpan(children: spans),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}
