import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// ============================================
/// PSALM-SPECIFIC CONFIGURATION
/// ============================================
class PsalmConfig {
  static const double verseNumberSpacing = 4.0;
  static const double verseNumberSize = 10.0;
  static const double verseNumberWidth = 24.0;
  static const FontWeight verseNumberWeight = FontWeight.bold;
  static const double paragraphSpacing = 15.0;
  static const double lineSpacing = 1.3;
  static const double textSize = 16.0;
  static const double superscriptOffset = 3.0;
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
  final int indentLevel;
  TextLine({required this.segments, this.indentLevel = 0});
}

class Verse {
  final String? number;
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
    String? currentVerseNumber;
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

      final verseMatch = RegExp(r'^\{([^}]+)\}').firstMatch(line);
      if (verseMatch != null) {
        if (currentLines.isNotEmpty) {
          currentParagraphVerses.add(Verse(
              number: currentVerseNumber, lines: List.from(currentLines)));
          currentLines.clear();
        }
        currentVerseNumber = verseMatch.group(1)!;
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
    int indentLevel = 0;

    String trimmed = line.trimLeft();
    while (trimmed.startsWith('>')) {
      indentLevel++;
      trimmed = trimmed.substring(1).trimLeft();
    }
    line = trimmed;

    // _text_ for underline, %text% for italic, * displayed as liturgical symbol
    final regex = RegExp(r'(_|%|\*\*)(.*?)\1|(\*)|([^_*%]+)');
    final matches = regex.allMatches(line);

    for (var match in matches) {
      String? delimiter = match.group(1);
      String? content = match.group(2) ?? match.group(4);
      String? loneStar = match.group(3);

      if (loneStar != null) {
        segments.add(TextSegment(text: '*', hasRightIndent: indentLevel > 0));
      } else if (content != null && content.isNotEmpty) {
        segments.add(TextSegment(
          text: content,
          isUnderlined: delimiter == '_',
          isItalic: delimiter == '**' || delimiter == '%',
          hasRightIndent: indentLevel > 0,
        ));
      }
    }

    return TextLine(segments: segments, indentLevel: indentLevel);
  }
}

/// ============================================
/// UI WIDGETS
/// ============================================

class PsalmWidget extends StatelessWidget {
  final List<PsalmParagraph> paragraphs;
  final TextStyle? verseStyle;
  final TextStyle? numberStyle;
  final Color? symbolColor;
  final double zoom;

  const PsalmWidget({
    super.key,
    required this.paragraphs,
    this.verseStyle,
    this.numberStyle,
    this.symbolColor,
    this.zoom = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final scale = zoom / 100;
    final paragraphSpacing = PsalmConfig.paragraphSpacing * scale;
    final verseNumberWidth = PsalmConfig.verseNumberWidth * scale;
    final verseNumberSpacing = PsalmConfig.verseNumberSpacing * scale;
    final superscriptOffset = PsalmConfig.superscriptOffset * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: entry.key < paragraphs.length - 1 ? paragraphSpacing : 0,
          ),
          child: _buildParagraph(
            entry.value,
            verseNumberWidth: verseNumberWidth,
            verseNumberSpacing: verseNumberSpacing,
            superscriptOffset: superscriptOffset,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParagraph(
    PsalmParagraph paragraph, {
    required double verseNumberWidth,
    required double verseNumberSpacing,
    required double superscriptOffset,
  }) {
    final List<Widget> lineWidgets = [];

    for (var verse in paragraph.verses) {
      for (int i = 0; i < verse.lines.length; i++) {
        final isFirstLine = i == 0;
        lineWidgets.add(
          Padding(
            padding: EdgeInsets.only(
              left: isFirstLine ? 0 : (verseNumberWidth + verseNumberSpacing),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirstLine) ...[
                  SizedBox(
                    width: verseNumberWidth,
                    child: verse.number != null
                        ? Transform.translate(
                            offset: Offset(0, superscriptOffset),
                            child: Text(
                              verse.number!,
                              textAlign: TextAlign.right,
                              style: numberStyle ??
                                  TextStyle(
                                    fontWeight: PsalmConfig.verseNumberWeight,
                                    color: symbolColor ?? Colors.red,
                                    fontSize: PsalmConfig.verseNumberSize *
                                        zoom /
                                        100,
                                  ),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: verseNumberSpacing),
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
          .replaceAll(' :', '\u202F:')
          .replaceAll(' !', '\u202F!')
          .replaceAll(' ?', '\u202F?')
          .replaceAll(' ;', '\u202F;')
          .replaceAll(' *', '\u00A0*')
          .replaceAll(' +', '\u00A0+')
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
            style: style.copyWith(color: symbolColor ?? Colors.red),
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
    if (line.indentLevel > 0) {
      final indent =
          (baseStyle.fontSize ?? PsalmConfig.textSize) * 1.5 * line.indentLevel;
      widget = Padding(padding: EdgeInsets.only(left: indent), child: widget);
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
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value;
        // Note: Parsing in build is okay for small texts,
        // but consider pre-parsing for long offices.
        final paragraphs = PsalmParser.parseContent(content);
        final accentColor = Theme.of(context).colorScheme.secondary;
        return PsalmWidget(
          paragraphs: paragraphs,
          symbolColor: accentColor,
          zoom: zoom,
          verseStyle: verseStyle ??
              TextStyle(
                fontSize: PsalmConfig.textSize * zoom / 100,
                height: PsalmConfig.lineSpacing,
              ),
          numberStyle: numberStyle ??
              TextStyle(
                fontWeight: PsalmConfig.verseNumberWeight,
                color: accentColor,
                fontSize: PsalmConfig.verseNumberSize * zoom / 100,
              ),
        );
      },
    );
  }
}
