import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// ============================================
/// DISPLAY PARAMETERS CONFIGURATION
/// Modify these values to customize the appearance
/// ============================================
class PsalmConfig {
  // ===== COLORS =====
  /// Color for verse numbers and special symbols (+, *, ℟, ℣)
  static const Color couleurRouge = Colors.red;

  // ===== SPACING =====
  /// Spacing between paragraphs (in pixels)
  static const double espacementParagraphes = 16.0;

  /// Spacing between verse number and text (in pixels)
  static const double espacementNumeroTexte = 5.0;

  /// Spacing between text lines (line height)
  static const double espacementLignes = 1.3;

  // ===== SIZES =====
  /// Font size for verse numbers
  static const double tailleNumero = 10.0;

  /// Font size for verse text
  static const double tailleTexte = 16.0;

  /// Width reserved for verse numbers (in pixels)
  static const double largeurNumero = 40.0;

  // ===== ADDITIONAL STYLES =====
  /// Font weight for special characters (+, *, ℟, ℣)
  static const FontWeight grasFaibleSymboles = FontWeight.w500;

  /// Font weight for verse numbers
  static const FontWeight grasNumeros = FontWeight.bold;
}

/// Represents a text segment with formatting
class TextSegment {
  final String text;
  final bool isUnderlined;
  final bool isItalic;

  TextSegment({
    required this.text,
    this.isUnderlined = false,
    this.isItalic = false,
  });
}

/// Represents a verse with its number and formatted lines
class Verset {
  final int numero;
  final List<List<TextSegment>> lignes;

  Verset({
    required this.numero,
    required this.lignes,
  });
}

/// Represents a paragraph containing one or more verses
class Paragraphe {
  final List<Verset> versets;

  Paragraphe({required this.versets});
}

/// Parser for HTML psalms/canticles that preserves formatting
class PsalmParser {
  /// Parses HTML and returns a list of Paragraphs
  static List<Paragraphe> parseHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final paragraphes = <Paragraphe>[];

    // Get all <p> elements (one <p> = one paragraph)
    final pElements = document.querySelectorAll('p');

    for (var pElement in pElements) {
      final versets = _parseParagraphe(pElement);
      if (versets.isNotEmpty) {
        paragraphes.add(Paragraphe(versets: versets));
      }
    }

    return paragraphes;
  }

  /// Parses a <p> element and extracts all verses with formatting
  static List<Verset> _parseParagraphe(dom.Element pElement) {
    final versets = <Verset>[];
    int? currentVersetNumero;
    List<List<TextSegment>> currentLignes = [];
    List<TextSegment> currentLigne = [];

    void finalizeVerset() {
      if (currentVersetNumero != null && currentLignes.isNotEmpty) {
        versets.add(Verset(
          numero: currentVersetNumero!,
          lignes: List.from(currentLignes),
        ));
        currentLignes.clear();
      }
    }

    void finalizeLigne() {
      if (currentLigne.isNotEmpty) {
        currentLignes.add(List.from(currentLigne));
        currentLigne.clear();
      }
    }

    void processNode(dom.Node node,
        {bool isUnderlined = false, bool isItalic = false}) {
      if (node is dom.Element) {
        // If it's a verse number
        if (node.className == 'verse_number') {
          // Finalize current line
          finalizeLigne();
          // Finalize the previous verse
          finalizeVerset();
          // Start a new verse
          currentVersetNumero = int.tryParse(node.text.trim());
        }
        // If it's a <br>, it marks a new line
        else if (node.localName == 'br') {
          finalizeLigne();
        }
        // If it's a <u> (underlined text), recurse with underline flag
        else if (node.localName == 'u') {
          for (var child in node.nodes) {
            processNode(child, isUnderlined: true, isItalic: isItalic);
          }
        }
        // If it's an <em> (italic text), recurse with italic flag
        else if (node.localName == 'em') {
          for (var child in node.nodes) {
            processNode(child, isUnderlined: isUnderlined, isItalic: true);
          }
        }
        // Other elements (like <span>), process children
        else {
          for (var child in node.nodes) {
            processNode(child, isUnderlined: isUnderlined, isItalic: isItalic);
          }
        }
      }
      // If it's plain text
      else if (node is dom.Text) {
        final text = node.text;
        if (text.isNotEmpty && text.trim().isNotEmpty) {
          currentLigne.add(TextSegment(
            text: text,
            isUnderlined: isUnderlined,
            isItalic: isItalic,
          ));
        }
      }
    }

    // Process all nodes in the paragraph
    for (var node in pElement.nodes) {
      processNode(node);
    }

    // Finalize the last line and last verse
    finalizeLigne();
    finalizeVerset();

    return versets;
  }
}

/// Widget to display a psalm
class PsalmWidget extends StatelessWidget {
  final List<Paragraphe> paragraphes;
  final TextStyle? versetStyle;
  final TextStyle? numeroStyle;
  final double espacementParagraphes;
  final double espacementNumero;

  const PsalmWidget({
    super.key,
    required this.paragraphes,
    this.versetStyle,
    this.numeroStyle,
    this.espacementParagraphes = PsalmConfig.espacementParagraphes,
    this.espacementNumero = PsalmConfig.espacementNumeroTexte,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphes.asMap().entries.map((entry) {
        final index = entry.key;
        final paragraphe = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < paragraphes.length - 1 ? espacementParagraphes : 0,
          ),
          child: _buildParagraphe(paragraphe),
        );
      }).toList(),
    );
  }

  Widget _buildParagraphe(Paragraphe paragraphe) {
    final lignesWidget = <Widget>[];

    for (var verset in paragraphe.versets) {
      for (int i = 0; i < verset.lignes.length; i++) {
        final isFirstLine = i == 0;

        lignesWidget.add(
          Padding(
            padding: EdgeInsets.only(
              left: isFirstLine
                  ? 0
                  : (PsalmConfig.largeurNumero + espacementNumero),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse number (only on the first line of the verse)
                if (isFirstLine) ...[
                  SizedBox(
                    width: PsalmConfig.largeurNumero,
                    child: Text(
                      '${verset.numero}',
                      textAlign: TextAlign.right,
                      style: numeroStyle ??
                          TextStyle(
                            fontWeight: PsalmConfig.grasNumeros,
                            color: PsalmConfig.couleurRouge,
                            fontSize: PsalmConfig.tailleNumero,
                          ),
                    ),
                  ),
                  SizedBox(width: espacementNumero),
                ],
                // Line text
                Expanded(
                  child: _buildLigneTexte(verset.lignes[i]),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lignesWidget,
    );
  }

  Widget _buildLigneTexte(List<TextSegment> segments) {
    final spans = <TextSpan>[];

    final baseStyle = versetStyle ??
        TextStyle(
          fontSize: PsalmConfig.tailleTexte,
          height: PsalmConfig.espacementLignes,
        );

    for (var segment in segments) {
      // Replace R/ with ℟ and V/ with ℣
      var text = segment.text.replaceAll('R/', '℟').replaceAll('V/', '℣');

      // Process text character by character to handle special characters
      final buffer = StringBuffer();
      final segmentSpans = <TextSpan>[];

      for (int i = 0; i < text.length; i++) {
        final char = text[i];

        if (char == '+' || char == '*' || char == '℟' || char == '℣') {
          // Add accumulated text
          if (buffer.isNotEmpty) {
            segmentSpans.add(TextSpan(
              text: buffer.toString(),
              style: _getTextStyle(baseStyle, segment),
            ));
            buffer.clear();
          }

          // Add special character in red
          segmentSpans.add(TextSpan(
            text: char,
            style: _getTextStyle(baseStyle, segment).copyWith(
              color: PsalmConfig.couleurRouge,
              fontWeight: PsalmConfig.grasFaibleSymboles,
            ),
          ));
        } else {
          buffer.write(char);
        }
      }

      // Add remaining text
      if (buffer.isNotEmpty) {
        segmentSpans.add(TextSpan(
          text: buffer.toString(),
          style: _getTextStyle(baseStyle, segment),
        ));
      }

      spans.addAll(segmentSpans);
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }

  /// Returns the appropriate TextStyle based on segment formatting
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
  final String? titre;
  final TextStyle? versetStyle;
  final TextStyle? numeroStyle;
  final TextStyle? titreStyle;

  const PsalmFromHtml({
    super.key,
    required this.htmlContent,
    this.titre,
    this.versetStyle,
    this.numeroStyle,
    this.titreStyle,
  });

  @override
  Widget build(BuildContext context) {
    final paragraphes = PsalmParser.parseHtml(htmlContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titre != null) ...[
          Text(
            titre!,
            style: titreStyle ??
                const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
        ],
        PsalmWidget(
          paragraphes: paragraphes,
          versetStyle: versetStyle,
          numeroStyle: numeroStyle,
        ),
      ],
    );
  }
}
