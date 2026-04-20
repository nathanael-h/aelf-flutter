import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

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
  static final RegExp _paragraphRegExp = RegExp(r'\n\s*\n');
  static final RegExp _lineRegExp =
      RegExp(r'(§R)|(§E)|(%)|(\^([a-zA-Z0-9éèêâàîïôûù]+))|([^%^§]+)');
  static final RegExp _symbolRegex = RegExp(r'(℟[12]?|℣|\+|\*)');

  static List<YamlTextParagraph> parseText(String content) {
    if (content.isEmpty) return [];

    return content
        .split(_paragraphRegExp)
        .where((p) => p.trim().isNotEmpty)
        .map((p) => YamlTextParagraph(lines: _parseParagraph(p)))
        .toList();
  }

  static List<YamlTextLine> _parseParagraph(String paragraphText) {
    String processed = _applyTypography(paragraphText)
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

      final matches = _lineRegExp.allMatches(lineToParse);
      List<YamlTextSegment> segments = [];

      for (final match in matches) {
        if (match.group(1) != null) {
          isCurrentlyRubric = true;
        } else if (match.group(2) != null) {
          isCurrentlyRubric = false;
        } else if (match.group(3) != null) {
          isCurrentlyItalic = !isCurrentlyItalic;
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

  static String _applyTypography(String text) {
    return text
        .replaceAll('R/', '℟')
        .replaceAll('V/', '℣')
        .replaceAll(' :', '\u202F:')
        .replaceAll(' !', '\u202F!')
        .replaceAll(' ?', '\u202F?')
        .replaceAll(' ;', '\u202F;')
        .replaceAll("'", '\u2019');
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
        DefaultTextStyle.of(context)
            .style
            .copyWith(fontSize: 16.0, height: 1.3);

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

      if (i + 1 < line.segments.length && line.segments[i + 1].isSuperscript) {
        final nextSegment = line.segments[i + 1];
        final currentText = segment.text;
        final lastSpaceIdx = currentText.lastIndexOf(' ');

        if (lastSpaceIdx != -1) {
          spans.add(_buildTextSpan(
            YamlTextSegment(
                text: currentText.substring(0, lastSpaceIdx + 1),
                isItalic: segment.isItalic,
                isRubric: segment.isRubric),
            baseStyle,
            redColor,
          ));
          spans.add(_createNonBreakingSuperscript(
            currentText.substring(lastSpaceIdx + 1),
            segment,
            nextSegment,
            baseStyle,
            redColor,
          ));
        } else {
          spans.add(_createNonBreakingSuperscript(
              currentText, segment, nextSegment, baseStyle, redColor));
        }
        i++;
        continue;
      }

      spans.add(segment.isSuperscript
          ? _buildSuperscriptSpan(segment, baseStyle, redColor)
          : _buildTextSpan(segment, baseStyle, redColor));
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          left: line.hasRightIndent ? (baseStyle.fontSize ?? 16.0) * 1.5 : 0.0),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: textAlign,
      ),
    );
  }

  WidgetSpan _createNonBreakingSuperscript(String word, YamlTextSegment wordSeg,
      YamlTextSegment superSeg, TextStyle base, Color red) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Text.rich(
        TextSpan(children: [
          _buildTextSpan(
              YamlTextSegment(
                  text: word,
                  isItalic: wordSeg.isItalic,
                  isRubric: wordSeg.isRubric),
              base,
              red),
          _buildSuperscriptSpan(superSeg, base, red),
        ]),
        textWidthBasis: TextWidthBasis.longestLine,
        softWrap: false,
      ),
    );
  }

  InlineSpan _buildTextSpan(
      YamlTextSegment segment, TextStyle baseStyle, Color redColor) {
    final subSpans = <InlineSpan>[];
    final parts = segment.text.split(YamlTextParser._symbolRegex);
    final matches =
        YamlTextParser._symbolRegex.allMatches(segment.text).toList();

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
        offset: Offset(0, -(baseStyle.fontSize ?? 16.0) * 0.45),
        child: Text(
          segment.text,
          // Fixed: Restored textWidthBasis for correct sizing inside WidgetSpan
          textWidthBasis: TextWidthBasis.longestLine,
          style: _getSegmentStyle(segment, baseStyle, redColor).copyWith(
            fontSize: (baseStyle.fontSize ?? 16.0) * 0.65,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  TextStyle _getSegmentStyle(
      YamlTextSegment segment, TextStyle base, Color red) {
    if (segment.isRubric) {
      return base.copyWith(
          color: red,
          fontStyle: FontStyle.italic,
          fontSize: (base.fontSize ?? 16.0) - 3.0);
    }
    return segment.isItalic ? base.copyWith(fontStyle: FontStyle.italic) : base;
  }
}

class YamlTextFromString extends StatefulWidget {
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
  State<YamlTextFromString> createState() => _YamlTextFromStringState();
}

class _YamlTextFromStringState extends State<YamlTextFromString> {
  late List<YamlTextParagraph> _parsedParagraphs;

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  @override
  void didUpdateWidget(YamlTextFromString oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _parseContent();
    }
  }

  void _parseContent() {
    _parsedParagraphs = YamlTextParser.parseText(widget.content);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, _) {
        final zoom = currentZoom.value;
        return YamlTextWidget(
          paragraphs: _parsedParagraphs,
          textStyle: widget.textStyle ??
              TextStyle(fontSize: 16.0 * zoom / 100, height: 1.3),
          textAlign: widget.textAlign,
          paragraphSpacing: widget.paragraphSpacing,
          redColor: Theme.of(context).colorScheme.secondary,
        );
      },
    );
  }
}
