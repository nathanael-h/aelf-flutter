import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_marker_icon.dart';

class YamlTextSegment {
  final String text;
  final bool isItalic;
  final bool isRubric;
  final bool isSuperscript;

  /// The opening letter of a reading, drawn red and larger.
  final bool isInitial;

  YamlTextSegment({
    required this.text,
    this.isItalic = false,
    this.isRubric = false,
    this.isSuperscript = false,
    this.isInitial = false,
  });
}

class YamlTextLine {
  final List<YamlTextSegment> segments;
  final int indentLevel;
  final String? leadingSymbol;

  YamlTextLine({
    required this.segments,
    this.indentLevel = 0,
    this.leadingSymbol,
  });
}

class YamlTextParagraph {
  final List<YamlTextLine> lines;

  YamlTextParagraph({required this.lines});
}

class YamlTextParser {
  static final RegExp _paragraphRegExp = RegExp(r'\n\s*\n');
  static final RegExp _lineRegExp =
      RegExp(r'(§R)|(§E)|(%)|(\^([a-zA-Z0-9éèêâàîïôûù]+))|([^%^§]+)');

  // Liturgical marks rendered through the LiturgicalSymbols font. R/ and V/
  // are pre-substituted to these codepoints by _applyTypography; a number
  // right after R/ (R/1, R/2...) is kept and drawn as a subscript by
  // symbolSpan. '*' and '+' are translated at render time via glyphFor
  // since they stay literal in the source text.
  static const String responseGlyph = '\u{E000}'; // R/
  static const String versicleGlyph = '\u{E002}'; // V/
  // Sans-serif R/ and V/, swapped in at render time for the modern display.
  static const String responseSansGlyph = '\u{E010}'; // R/
  static const String versicleSansGlyph = '\u{E012}'; // V/
  static const String starGlyph = '\u{E00E}'; // *
  static const String daggerGlyph = '\u{E00D}'; // +
  static const String outlinedCrossGlyph =
      '\u{E00F}'; // hand-drawn cross, e.g. before the Gospel announcement

  /// R/ glyph with its optional subscript number.
  static const String responsePattern = '$responseGlyph[0-9]*';

  static final RegExp _symbolRegex =
      RegExp('($responsePattern|$versicleGlyph|\\+|/|\\*)');
  static final RegExp _leadingSymbolRegex =
      RegExp('^($responsePattern|$versicleGlyph|\\*)\\s*');

  /// Glyph drawing [symbol]; R/ and V/ get their sans-serif form outside
  /// the [classic] display.
  static String glyphFor(String symbol, {bool classic = true}) {
    if (symbol == '*') return starGlyph;
    if (symbol == '+') return daggerGlyph;
    if (!classic && symbol == responseGlyph) return responseSansGlyph;
    if (!classic && symbol == versicleGlyph) return versicleSansGlyph;
    return symbol;
  }

  /// Span for a liturgical symbol drawn with [glyphStyle]: a number following
  /// R/ (R/1, R/2...) is drawn as a subscript, like the A/ antiphon markers.
  static InlineSpan symbolSpan(String symbol, TextStyle glyphStyle,
      {required bool classic}) {
    if (!symbol.startsWith(responseGlyph) ||
        symbol.length == responseGlyph.length) {
      return TextSpan(
          text: glyphFor(symbol, classic: classic), style: glyphStyle);
    }
    return TextSpan(
        text: glyphFor(responseGlyph, classic: classic),
        style: glyphStyle,
        children: [
          glyphSubscript(symbol.substring(responseGlyph.length),
              glyphStyle.fontSize ?? 14.0, glyphStyle.color,
              classic: classic),
        ]);
  }

  static final RegExp _letterRegex = RegExp(r'\p{L}', unicode: true);

  /// Marks the first letter of [paragraphs] as the opening initial of a
  /// reading. The letter is looked for in the first line only, outside
  /// rubrics and superscripts (verse numbers); leading punctuation such as
  /// an opening quote keeps its normal size. Returns [paragraphs] unchanged
  /// when that line has no letter.
  static List<YamlTextParagraph> withInitialLetter(
      List<YamlTextParagraph> paragraphs) {
    if (paragraphs.isEmpty || paragraphs.first.lines.isEmpty) {
      return paragraphs;
    }
    final firstLine = paragraphs.first.lines.first;
    final segments = firstLine.segments;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.isRubric || segment.isSuperscript) continue;
      final match = _letterRegex.firstMatch(segment.text);
      if (match == null) continue;

      YamlTextSegment part(String text, {bool isInitial = false}) =>
          YamlTextSegment(
              text: text, isItalic: segment.isItalic, isInitial: isInitial);
      final split = [
        if (match.start > 0) part(segment.text.substring(0, match.start)),
        part(match.group(0)!, isInitial: true),
        if (match.end < segment.text.length)
          part(segment.text.substring(match.end)),
      ];
      final line = YamlTextLine(
        segments: [
          ...segments.sublist(0, i),
          ...split,
          ...segments.sublist(i + 1)
        ],
        indentLevel: firstLine.indentLevel,
        leadingSymbol: firstLine.leadingSymbol,
      );
      return [
        YamlTextParagraph(lines: [line, ...paragraphs.first.lines.skip(1)]),
        ...paragraphs.skip(1),
      ];
    }
    return paragraphs;
  }

  /// With [inTextSymbol], a symbol starting a line (e.g. R/ in an antiphon)
  /// stays inline in the text instead of moving to the leading symbol column.
  static List<YamlTextParagraph> parseText(String content,
      {bool inTextSymbol = false}) {
    if (content.isEmpty) return [];

    return content
        .split(_paragraphRegExp)
        .where((p) => p.trim().isNotEmpty)
        .map((p) => YamlTextParagraph(
            lines: _parseParagraph(p, inTextSymbol: inTextSymbol)))
        .toList();
  }

  static List<YamlTextLine> _parseParagraph(String paragraphText,
      {bool inTextSymbol = false}) {
    String processed = _applyTypography(paragraphText)
        .replaceAll('[rubric]', '§R')
        .replaceAll('[/rubric]', '§E');

    final rawLines = processed.split('\n');
    List<YamlTextLine> parsedLines = [];
    bool isCurrentlyItalic = false;
    bool isCurrentlyRubric = false;

    for (var rawLine in rawLines) {
      if (rawLine.trim().isEmpty && rawLines.length > 1) continue;

      int indentLevel = 0;
      String lineToParse = rawLine.trimLeft();
      while (lineToParse.startsWith('>')) {
        indentLevel++;
        lineToParse = lineToParse.substring(1).trimLeft();
      }
      if (indentLevel == 0) lineToParse = rawLine;

      final leadingMatch =
          inTextSymbol ? null : _leadingSymbolRegex.firstMatch(lineToParse);
      final String? leadingSymbol = leadingMatch?.group(1);
      if (leadingSymbol != null) {
        lineToParse = lineToParse.substring(leadingMatch!.end);
      }

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
      parsedLines.add(YamlTextLine(
          segments: segments,
          indentLevel: indentLevel,
          leadingSymbol: leadingSymbol));
    }
    return parsedLines;
  }

  static String _applyTypography(String text) {
    return text
        .replaceAll('R/', responseGlyph)
        .replaceAll('V/', versicleGlyph)
        .replaceAll(' :', ' :')
        .replaceAll(' !', ' !')
        .replaceAll(' ?', ' ?')
        .replaceAll(' ;', ' ;')
        .replaceAll("'", '’');
  }
}

/// Size of a reading's opening letter relative to its text.
const double initialLetterScale = 1.6;

class YamlTextWidget extends StatelessWidget {
  final List<YamlTextParagraph> paragraphs;
  final TextStyle? textStyle;
  final double paragraphSpacing;
  final TextAlign textAlign;
  final Color? redColor;
  final bool useSymbolColumn;
  final double rightIndentMultiplier;

  const YamlTextWidget({
    super.key,
    required this.paragraphs,
    this.textStyle,
    this.paragraphSpacing = 12.0,
    this.textAlign = TextAlign.left,
    this.redColor,
    this.useSymbolColumn = false,
    this.rightIndentMultiplier = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveRed =
        redColor ?? Theme.of(context).colorScheme.secondary;
    final classic = context.watch<ThemeNotifier>().classicDisplay;
    final baseStyle = textStyle ??
        DefaultTextStyle.of(context)
            .style
            .copyWith(fontSize: 16.0, height: 1.2);

    final hasAnyLeadingSymbol =
        paragraphs.any((p) => p.lines.any((l) => l.leadingSymbol != null));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i < paragraphs.length - 1 ? paragraphSpacing : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: paragraphs[i]
                  .lines
                  .map((l) => _buildLine(l, baseStyle, effectiveRed, classic,
                      useSymbolColumn || hasAnyLeadingSymbol))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLine(
      YamlTextLine line, TextStyle baseStyle, Color redColor, bool classic,
      [bool effectiveSymbolColumn = false]) {
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
                isRubric: segment.isRubric,
                isInitial: segment.isInitial),
            baseStyle,
            redColor,
            classic,
          ));
          spans.add(_createNonBreakingSuperscript(
            currentText.substring(lastSpaceIdx + 1),
            segment,
            nextSegment,
            baseStyle,
            redColor,
            classic,
          ));
        } else {
          spans.add(_createNonBreakingSuperscript(
              currentText, segment, nextSegment, baseStyle, redColor, classic));
        }
        i++;
        continue;
      }

      spans.add(segment.isSuperscript
          ? _buildSuperscriptSpan(segment, baseStyle, redColor)
          : _buildTextSpan(segment, baseStyle, redColor, classic));
    }

    final textWidget = Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          left: (baseStyle.fontSize ?? 16.0) *
              rightIndentMultiplier *
              line.indentLevel),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: textAlign,
        // Liturgical-symbol glyphs (R/, V/, *, +) come from a font with
        // taller vertical metrics than the body font; without a strut,
        // Flutter sizes the line box from those metrics and only lines
        // containing these symbols end up with a bigger interligne.
        strutStyle: StrutStyle(
          fontSize: baseStyle.fontSize ?? 16.0,
          height: baseStyle.height ?? 1.2,
          forceStrutHeight: true,
        ),
      ),
    );

    if (!effectiveSymbolColumn) return textWidget;

    final symbolColWidth = 10.0 + (baseStyle.fontSize ?? verseFontSize);
    final symbol = line.leadingSymbol;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: symbolColWidth,
          child: symbol != null
              ? Text.rich(
                  YamlTextParser.symbolSpan(
                    symbol,
                    baseStyle.copyWith(
                      color: redColor,
                      fontFamily: 'LiturgicalSymbols',
                      fontWeight: FontWeight.normal,
                      fontSize: (baseStyle.fontSize ?? 16.0) * 0.85,
                    ),
                    classic: classic,
                  ),
                  textAlign: TextAlign.center,
                )
              : null,
        ),
        Expanded(child: textWidget),
      ],
    );
  }

  WidgetSpan _createNonBreakingSuperscript(String word, YamlTextSegment wordSeg,
      YamlTextSegment superSeg, TextStyle base, Color red, bool classic) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Text.rich(
        TextSpan(children: [
          _buildTextSpan(
              YamlTextSegment(
                  text: word,
                  isItalic: wordSeg.isItalic,
                  isRubric: wordSeg.isRubric,
                  isInitial: wordSeg.isInitial),
              base,
              red,
              classic),
          _buildSuperscriptSpan(superSeg, base, red),
        ]),
        textWidthBasis: TextWidthBasis.longestLine,
        softWrap: false,
      ),
    );
  }

  InlineSpan _buildTextSpan(YamlTextSegment segment, TextStyle baseStyle,
      Color redColor, bool classic) {
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
        final rawSymbol = matches[i].group(0)!;
        if (rawSymbol == '/') {
          // Literal repeat-marker slash in responsory text, not a font glyph.
          subSpans.add(TextSpan(
            text: rawSymbol,
            style: _getSegmentStyle(segment, baseStyle, redColor)
                .copyWith(color: redColor),
          ));
        } else if (rawSymbol == '*' || rawSymbol == '+') {
          // Mediant/flex marks hang above the baseline rather than sitting
          // on it. The font's own ascent leaves a lot of headroom above
          // these glyphs, so PlaceholderAlignment.top ends up putting them
          // near the bottom of the line instead — anchor to the baseline.
          subSpans.add(WidgetSpan(
            alignment: PlaceholderAlignment.aboveBaseline,
            baseline: TextBaseline.alphabetic,
            child: Text(
              YamlTextParser.glyphFor(rawSymbol),
              style: _getSegmentStyle(segment, baseStyle, redColor).copyWith(
                color: redColor,
                fontFamily: 'LiturgicalSymbols',
                fontWeight: FontWeight.normal,
                fontSize: (baseStyle.fontSize ?? 16.0) * 0.85,
              ),
            ),
          ));
        } else {
          // R/ and V/ stay upright even inside italic text (e.g. antiphons).
          subSpans.add(YamlTextParser.symbolSpan(
            rawSymbol,
            _getSegmentStyle(segment, baseStyle, redColor).copyWith(
              color: redColor,
              fontFamily: 'LiturgicalSymbols',
              fontWeight: FontWeight.normal,
              fontStyle: FontStyle.normal,
              fontSize: (baseStyle.fontSize ?? 16.0) * 0.85,
            ),
            classic: classic,
          ));
        }
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
    final style =
        segment.isItalic ? base.copyWith(fontStyle: FontStyle.italic) : base;
    // The line's strut keeps the larger initial from pushing lines apart.
    return segment.isInitial
        ? style.copyWith(
            color: red, fontSize: (base.fontSize ?? 16.0) * initialLetterScale)
        : style;
  }
}

class YamlTextFromString extends StatefulWidget {
  final String content;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final double paragraphSpacing;
  final bool useSymbolColumn;
  final double rightIndentMultiplier;

  /// Draws the text's first letter red and larger, as the opening of a
  /// reading.
  final bool initialLetter;

  const YamlTextFromString(
    this.content, {
    super.key,
    this.textStyle,
    this.textAlign = TextAlign.left,
    this.paragraphSpacing = 12.0,
    this.useSymbolColumn = false,
    this.rightIndentMultiplier = 1.5,
    this.initialLetter = false,
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
    if (oldWidget.content != widget.content ||
        oldWidget.initialLetter != widget.initialLetter) {
      _parseContent();
    }
  }

  void _parseContent() {
    final paragraphs = YamlTextParser.parseText(widget.content);
    _parsedParagraphs = widget.initialLetter
        ? YamlTextParser.withInitialLetter(paragraphs)
        : paragraphs;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, _) {
        final zoom = currentZoom.value;
        return YamlTextWidget(
          paragraphs: _parsedParagraphs,
          textStyle: widget.textStyle ??
              TextStyle(fontSize: 16.0 * zoom / 100, height: 1.2),
          textAlign: widget.textAlign,
          paragraphSpacing: widget.paragraphSpacing * zoom / 100,
          redColor: Theme.of(context).colorScheme.secondary,
          useSymbolColumn: widget.useSymbolColumn,
          rightIndentMultiplier: widget.rightIndentMultiplier,
        );
      },
    );
  }
}
