import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// ============================================
/// YAML TEXT PARSER & WIDGET
/// Logic: %text% for italics, ^text for superscript
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
  static List<YamlTextParagraph> parseText(String content) {
    if (content.isEmpty) return [];

    return content
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .map((p) => YamlTextParagraph(lines: _parseParagraph(p)))
        .toList();
  }

  static List<YamlTextLine> _parseParagraph(String paragraphText) {
    // 1. Pre-process rubric tags
    String processed = paragraphText
        .replaceAll('[rubric]', '§R')
        .replaceAll('[/rubric]', '§E');

    final rawLines = processed.split('\n');
    List<YamlTextLine> parsedLines = [];
    bool isCurrentlyItalic = false;
    bool isCurrentlyRubric = false;

    for (var rawLine in rawLines) {
      if (rawLine.trim().isEmpty && rawLines.length > 1) continue;

      bool hasRightIndent = rawLine.trimLeft().startsWith('>');
      String lineToParse =
          hasRightIndent ? rawLine.trimLeft().substring(1).trimLeft() : rawLine;

      // 2. REGEX: Detects Rubric Start (§R), End (§E), Italic Toggle (%),
      // Superscript (^), or Normal Text
      final regex =
          RegExp(r'(§R)|(§E)|(%)|(\^([a-zA-Z0-9éèêâàîïôûù]+))|([^%^§]+)');
      final matches = regex.allMatches(lineToParse);

      List<YamlTextSegment> segments = [];

      for (final match in matches) {
        if (match.group(1) != null) {
          isCurrentlyRubric = true;
        } else if (match.group(2) != null) {
          isCurrentlyRubric = false;
        } else if (match.group(3) != null) {
          isCurrentlyItalic = !isCurrentlyItalic; // Toggle italic on %
        } else if (match.group(4) != null) {
          segments.add(YamlTextSegment(
            text: match.group(5)!,
            isSuperscript: true,
            isItalic: isCurrentlyItalic,
            isRubric: isCurrentlyRubric,
          ));
        } else if (match.group(6) != null) {
          String text = match.group(6)!;
          if (text.isNotEmpty) {
            segments.add(YamlTextSegment(
              text: text,
              isItalic: isCurrentlyItalic,
              isRubric: isCurrentlyRubric,
            ));
          }
        }
      }
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
    this.paragraphSpacing = 15.0,
    this.textAlign = TextAlign.left,
    this.redColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveRed = redColor ?? Theme.of(context).colorScheme.error;
    final baseStyle = textStyle ??
        DefaultTextStyle.of(context).style.copyWith(
              fontSize: 16.0,
              height: 1.3,
            );

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

      // NO-BREAK GROUPING: Bind last word to its superscript.
      // Only the last word (no spaces) goes into the WidgetSpan so the inner
      // Text.rich cannot wrap — the prefix is emitted as a normal breakable span.
      if (i + 1 < line.segments.length && line.segments[i + 1].isSuperscript) {
        final nextSegment = line.segments[i + 1];
        final currentText = segment.text;
        final lastSpaceIdx = currentText.lastIndexOf(' ');

        if (lastSpaceIdx != -1) {
          // Emit the prefix (up to and including the last space) as a regular span.
          final prefixSeg = YamlTextSegment(
            text: currentText.substring(0, lastSpaceIdx + 1),
            isItalic: segment.isItalic,
            isRubric: segment.isRubric,
          );
          spans.add(_buildTextSpan(prefixSeg, baseStyle, redColor));

          // Wrap only the last word + superscript (no internal spaces → no wrapping).
          final lastWordSeg = YamlTextSegment(
            text: currentText.substring(lastSpaceIdx + 1),
            isItalic: segment.isItalic,
            isRubric: segment.isRubric,
          );
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Text.rich(
              TextSpan(children: [
                _buildTextSpan(lastWordSeg, baseStyle, redColor),
                _buildSuperscriptSpan(nextSegment, baseStyle, redColor),
              ]),
              textWidthBasis: TextWidthBasis.longestLine,
              softWrap: false,
            ),
          ));
        } else {
          // No space in the segment: wrap entirely (already no internal spaces).
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Text.rich(
              TextSpan(children: [
                _buildTextSpan(segment, baseStyle, redColor),
                _buildSuperscriptSpan(nextSegment, baseStyle, redColor),
              ]),
              textWidthBasis: TextWidthBasis.longestLine,
              softWrap: false,
            ),
          ));
        }
        i++;
        continue;
      }

      if (segment.isSuperscript) {
        spans.add(_buildSuperscriptSpan(segment, baseStyle, redColor));
      } else {
        spans.add(_buildTextSpan(segment, baseStyle, redColor));
      }
    }

    final indent =
        line.hasRightIndent ? (baseStyle.fontSize ?? 16.0) * 1.5 : 0.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: indent),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: textAlign,
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
            fontSize: isLarge ? (baseStyle.fontSize ?? 16) * 0.9 : null,
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
          textWidthBasis: TextWidthBasis.longestLine,
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
        .replaceAll(' :', '\u202F:')
        .replaceAll(' !', '\u202F!')
        .replaceAll(' ?', '\u202F?')
        .replaceAll(' ;', '\u202F;')
        .replaceAll("'", '\u2019');
  }

  TextStyle _getSegmentStyle(
      YamlTextSegment segment, TextStyle base, Color red) {
    TextStyle style = base;
    if (segment.isRubric) {
      style = style.copyWith(
        color: red,
        fontStyle: FontStyle.italic,
        fontSize: (base.fontSize ?? 16.0) - 1.5,
      );
    }
    if (segment.isItalic) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    return style;
  }
}

/// Parses and displays a YAML-formatted string with built-in zoom support.
/// If [textStyle] is null, applies zoom from [CurrentZoom] state automatically.
class YamlTextFromString extends StatelessWidget {
  final String content;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final double paragraphSpacing;

  const YamlTextFromString(
    this.content, {
    super.key,
    this.textStyle,
    this.textAlign = TextAlign.left,
    this.paragraphSpacing = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value;
        return YamlTextWidget(
          paragraphs: YamlTextParser.parseText(content),
          textStyle:
              textStyle ?? TextStyle(fontSize: 16.0 * zoom / 100, height: 1.3),
          textAlign: textAlign,
          paragraphSpacing: paragraphSpacing,
          redColor: Theme.of(context).colorScheme.secondary,
        );
      },
    );
  }
}
