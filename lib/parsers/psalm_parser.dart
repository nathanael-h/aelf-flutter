import 'package:flutter/material.dart';

/// ============================================
/// PSALM-SPECIFIC CONFIGURATION
/// ============================================
class PsalmConfig {
  static const double verseNumberSpacing = 4.0;
  static const double verseNumberSize = 10.0;
  static const double verseNumberWidth = 30.0;
  static const FontWeight verseNumberWeight = FontWeight.bold;
  static const double paragraphSpacing = 16.0;
  static const double lineSpacing = 1.4;
  static const double textSize = 16.0;
  static const double superscriptOffset = 3.0;
  static const Color redColor = Colors.red;
}

/// ============================================
/// DATA MODELS
/// ============================================

class TextSegment {
  final String text;
  final bool isUnderlined;
  final bool isItalic;
  final bool hasRightIndent;

  TextSegment({
    required this.text,
    this.isUnderlined = false,
    this.isItalic = false,
    this.hasRightIndent = false,
  });
}

class TextLine {
  final List<TextSegment> segments;
  final bool hasRightIndent;
  TextLine({required this.segments, required this.hasRightIndent});
}

class Verse {
  final int? number;
  final List<TextLine> lines;
  Verse({this.number, required this.lines});
}

class PsalmParagraph {
  final List<Verse> verses;
  PsalmParagraph({required this.verses});
}

/// ============================================
/// PSALM PARSER
/// ============================================

class PsalmParser {
  static List<PsalmParagraph> parseContent(String content) {
    final paragraphs = <PsalmParagraph>[];
    int? currentVerseNumber;
    List<TextLine> currentLines = [];
    List<Verse> currentParagraphVerses = [];

    final lines = content.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) {
        if (currentLines.isNotEmpty) {
          currentParagraphVerses.add(Verse(
              number: currentVerseNumber, lines: List.from(currentLines)));
          currentLines.clear();
        }
        if (currentParagraphVerses.isNotEmpty) {
          paragraphs
              .add(PsalmParagraph(verses: List.from(currentParagraphVerses)));
          currentParagraphVerses.clear();
        }
        currentVerseNumber = null;
        continue;
      }

      final verseMatch = RegExp(r'^\{(\d+)\}').firstMatch(line);
      if (verseMatch != null) {
        if (currentLines.isNotEmpty) {
          currentParagraphVerses.add(Verse(
              number: currentVerseNumber, lines: List.from(currentLines)));
          currentLines.clear();
        }
        currentVerseNumber = int.parse(verseMatch.group(1)!);
        line = line.substring(verseMatch.end);
      }

      if (line.trim().isNotEmpty) {
        currentLines.add(_parseLine(line));
      }
    }

    if (currentLines.isNotEmpty) {
      currentParagraphVerses
          .add(Verse(number: currentVerseNumber, lines: currentLines));
    }
    if (currentParagraphVerses.isNotEmpty) {
      paragraphs.add(PsalmParagraph(verses: currentParagraphVerses));
    }

    return paragraphs;
  }

  static TextLine _parseLine(String line) {
    final segments = <TextSegment>[];
    bool hasRightIndent = false;

    if (line.trimLeft().startsWith('>')) {
      hasRightIndent = true;
      line = line.trimLeft().substring(1).trimLeft();
    }

    // Markdown simple: _text_ for underline, **text** for italic
    final regex = RegExp(r'(_|\*\*)(.*?)\1|([^_|\*]+)');
    final matches = regex.allMatches(line);

    for (var match in matches) {
      String? delimiter = match.group(1);
      String? content = match.group(2) ?? match.group(3);

      if (content != null && content.isNotEmpty) {
        segments.add(TextSegment(
          text: content,
          isUnderlined: delimiter == '_',
          isItalic: delimiter == '**',
          hasRightIndent: hasRightIndent,
        ));
      }
    }

    return TextLine(segments: segments, hasRightIndent: hasRightIndent);
  }
}

/// ============================================
/// UI WIDGETS
/// ============================================

class PsalmWidget extends StatelessWidget {
  final List<PsalmParagraph> paragraphs;
  final TextStyle? verseStyle;
  final TextStyle? numberStyle;

  const PsalmWidget({
    super.key,
    required this.paragraphs,
    this.verseStyle,
    this.numberStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: entry.key < paragraphs.length - 1
                ? PsalmConfig.paragraphSpacing
                : 0,
          ),
          child: _buildParagraph(entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildParagraph(PsalmParagraph paragraph) {
    final List<Widget> lineWidgets = [];

    for (var verse in paragraph.verses) {
      for (int i = 0; i < verse.lines.length; i++) {
        final isFirstLine = i == 0;
        lineWidgets.add(
          Padding(
            padding: EdgeInsets.only(
              left: isFirstLine
                  ? 0
                  : (PsalmConfig.verseNumberWidth +
                      PsalmConfig.verseNumberSpacing),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirstLine) ...[
                  SizedBox(
                    width: PsalmConfig.verseNumberWidth,
                    child: verse.number != null
                        ? Transform.translate(
                            offset:
                                const Offset(0, PsalmConfig.superscriptOffset),
                            child: Text(
                              '${verse.number}',
                              textAlign: TextAlign.right,
                              style: numberStyle ??
                                  const TextStyle(
                                    fontWeight: PsalmConfig.verseNumberWeight,
                                    color: PsalmConfig.redColor,
                                    fontSize: PsalmConfig.verseNumberSize,
                                  ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: PsalmConfig.verseNumberSpacing),
                ],
                Expanded(child: _buildLineText(verse.lines[i])),
              ],
            ),
          ),
        );
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: lineWidgets);
  }

  Widget _buildLineText(TextLine line) {
    final spans = <InlineSpan>[];
    final baseStyle = verseStyle ??
        const TextStyle(
            fontSize: PsalmConfig.textSize, height: PsalmConfig.lineSpacing);
    final symbolRegex = RegExp(r'([℟℣\*\+])');

    for (var segment in line.segments) {
      final text = segment.text
          .replaceAll('R/', '℟')
          .replaceAll('V/', '℣')
          .replaceAll('&nbsp;', '\u00A0')
          .replaceAll("'", '\u2019');

      final style = baseStyle.copyWith(
        decoration: segment.isUnderlined ? TextDecoration.underline : null,
        fontStyle: segment.isItalic ? FontStyle.italic : null,
      );

      // Optimized symbol rendering using splitMapJoin
      text.splitMapJoin(
        symbolRegex,
        onMatch: (m) {
          spans.add(TextSpan(
            text: m.group(0),
            style: style.copyWith(color: PsalmConfig.redColor),
          ));
          return '';
        },
        onNonMatch: (t) {
          if (t.isNotEmpty) spans.add(TextSpan(text: t, style: style));
          return '';
        },
      );
    }

    Widget widget =
        Text.rich(TextSpan(children: spans), textAlign: TextAlign.left);
    if (line.hasRightIndent) {
      widget =
          Padding(padding: const EdgeInsets.only(left: 25.0), child: widget);
    }
    return widget;
  }
}

class PsalmFromMarkdown extends StatelessWidget {
  final String content;
  final TextStyle? verseStyle;
  final TextStyle? numberStyle;

  const PsalmFromMarkdown({
    super.key,
    required this.content,
    this.verseStyle,
    this.numberStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Note: Parsing in build is okay for small texts,
    // but consider pre-parsing for long offices.
    final paragraphs = PsalmParser.parseContent(content);
    return PsalmWidget(
      paragraphs: paragraphs,
      verseStyle: verseStyle,
      numberStyle: numberStyle,
    );
  }
}
