import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class VerseData {
  final String number;
  final String content;
  final bool startsNewParagraph;
  final bool endsWithParagraph;

  VerseData(this.number, this.content,
      {this.startsNewParagraph = false, this.endsWithParagraph = false});
}

/// Display psalm content with verse numbers on the left margin
class PsalmVerseDisplay extends StatelessWidget {
  const PsalmVerseDisplay({
    super.key,
    required this.htmlContent,
    this.verseNumberWidth = 40.0,
    this.verseNumberSpacing = 8.0,
    this.verseNumberColor,
    this.verseNumberFontSize = 10.0,
    this.contentFontSize = 16.0,
    this.contentLineHeight = 1.2,
  });

  final String htmlContent;
  final double verseNumberWidth;
  final double verseNumberSpacing;
  final Color? verseNumberColor;
  final double verseNumberFontSize;
  final double contentFontSize;
  final double contentLineHeight;

  @override
  Widget build(BuildContext context) {
    final verses = _extractVersesWithParagraphInfo(htmlContent);

    // If no verse numbers found, display as single block
    if (verses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Html(
          data: _applyLiturgicalSymbols(htmlContent),
          style: _getHtmlStyles(context),
        ),
      );
    }

    // Display verses with numbers on the left
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < verses.length; i++) ...[
            // Add spacing before verse if it starts a new paragraph (except for first)
            if (i > 0 && verses[i].startsNewParagraph)
              const SizedBox(height: 4),
            _buildVerseRow(context, verses[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseRow(BuildContext context, VerseData verse) {
    final numberColor = verseNumberColor ?? Colors.red[700];

    // Apply liturgical transformations
    String cleanedContent = _applyLiturgicalSymbols(verse.content);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verse number on the left
        SizedBox(
          width: verseNumberWidth,
          child: verse.number.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    verse.number,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: verseNumberFontSize,
                      color: numberColor,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.right,
                  ),
                )
              : null,
        ),

        SizedBox(width: verseNumberSpacing),

        // Verse content on the right
        Expanded(
          child: Html(
            data: cleanedContent,
            style: _getHtmlStyles(context),
          ),
        ),
      ],
    );
  }

  Map<String, Style> _getHtmlStyles(BuildContext context) {
    return {
      "body": Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        fontSize: FontSize(contentFontSize),
        lineHeight: LineHeight(contentLineHeight),
      ),
      "p": Style(
        margin: Margins.zero, // ← Pas de marge du tout
        padding: HtmlPaddings.zero,
        display: Display.inline, // ← Force inline pour éviter tout espacement
      ),
      "br": Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
      ".red-text": Style(
        color: Colors.red,
      ),
    };
  }

  /// Apply liturgical symbol transformations
  String _applyLiturgicalSymbols(String content) {
    return content
        .replaceAll('R/', '<span class="red-text">℟</span>')
        .replaceAll('R /', '<span class="red-text">℟</span>')
        .replaceAll('V/', '<span class="red-text">℣</span>')
        .replaceAll('V /', '<span class="red-text">℣</span>')
        .replaceAll('+', '<span class="red-text">+</span>')
        .replaceAll('*', '<span class="red-text">*</span>');
  }

  /// Extract verses while preserving paragraph structure
  List<VerseData> _extractVersesWithParagraphInfo(String htmlContent) {
    if (htmlContent.isEmpty || !htmlContent.contains('verse_number')) {
      return [];
    }

    try {
      final document = html_parser.parse(htmlContent);
      if (document.body == null) {
        return [];
      }

      final List<VerseData> verses = [];

      // Find all <p> elements
      final pElements = document.querySelectorAll('p');

      for (var pElement in pElements) {
        String currentVerseNumber = '';
        StringBuffer currentVerseContent = StringBuffer();
        bool isFirstVerseInParagraph = true;
        List<String> verseNumbersInParagraph = [];

        // Collect all verse numbers in this paragraph
        for (var child in pElement.nodes) {
          if (child.nodeType == html_dom.Node.ELEMENT_NODE) {
            final childElement = child as html_dom.Element;
            if (childElement.classes.contains('verse_number')) {
              verseNumbersInParagraph.add(childElement.text.trim());
            }
          }
        }

        int verseIndex = 0;

        // Process paragraph content
        for (var child in pElement.nodes) {
          if (child.nodeType == html_dom.Node.ELEMENT_NODE) {
            final childElement = child as html_dom.Element;

            if (childElement.classes.contains('verse_number')) {
              // Save previous verse if any
              if (currentVerseNumber.isNotEmpty &&
                  currentVerseContent.isNotEmpty) {
                verses.add(VerseData(
                  currentVerseNumber,
                  currentVerseContent.toString(),
                  startsNewParagraph: isFirstVerseInParagraph,
                  endsWithParagraph: false,
                ));
                isFirstVerseInParagraph = false;
              }

              // Start new verse
              currentVerseNumber = childElement.text.trim();
              currentVerseContent = StringBuffer();
              verseIndex++;
            } else {
              currentVerseContent.write(childElement.outerHtml);
            }
          } else if (child.nodeType == html_dom.Node.TEXT_NODE) {
            currentVerseContent.write(child.text);
          }
        }

        // Save last verse of paragraph
        if (currentVerseNumber.isNotEmpty && currentVerseContent.isNotEmpty) {
          // Don't wrap in <p> tag anymore, we handle spacing with SizedBox
          verses.add(VerseData(
            currentVerseNumber,
            currentVerseContent.toString(), // ← Pas de <p>
            startsNewParagraph: isFirstVerseInParagraph,
            endsWithParagraph: true,
          ));
        }
      }

      return verses;
    } catch (e) {
      return [];
    }
  }
}
