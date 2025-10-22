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
  /// 1.0 = single, 1.5 = 1.5x, 2.0 = double, etc.
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

/// Represents a verse with its number and text lines
class Verset {
  final int numero;
  final List<String> lignes;

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

/// Generic parser for all HTML canticles/psalms
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

  /// Parses a <p> element and extracts all verses it contains
  static List<Verset> _parseParagraphe(dom.Element pElement) {
    final versets = <Verset>[];
    int? currentVersetNumero;
    List<String> currentLignes = [];

    void finalizeVerset() {
      if (currentVersetNumero != null && currentLignes.isNotEmpty) {
        versets.add(Verset(
          numero: currentVersetNumero!,
          lignes: List.from(currentLignes),
        ));
        currentLignes.clear();
      }
    }

    String currentLigne = '';

    for (var node in pElement.nodes) {
      if (node is dom.Element) {
        // If it's a verse number
        if (node.className == 'verse_number') {
          // Finalize the current line if it exists
          if (currentLigne.trim().isNotEmpty) {
            currentLignes.add(currentLigne.trim());
            currentLigne = '';
          }

          // Finalize the previous verse
          finalizeVerset();

          // Start a new verse
          currentVersetNumero = int.tryParse(node.text.trim());
        }
        // If it's a <br>, it marks a new line
        else if (node.localName == 'br') {
          if (currentLigne.trim().isNotEmpty) {
            currentLignes.add(currentLigne.trim());
            currentLigne = '';
          }
        }
        // If it's a <u> (accent), get the text
        else if (node.localName == 'u') {
          currentLigne += node.text;
        }
        // Other elements
        else {
          currentLigne += _extractText(node);
        }
      }
      // If it's plain text
      else if (node is dom.Text) {
        currentLigne += node.text;
      }
    }

    // Finalize the last line and last verse
    if (currentLigne.trim().isNotEmpty) {
      currentLignes.add(currentLigne.trim());
    }
    finalizeVerset();

    return versets;
  }

  /// Extracts all text from an element, including sub-elements
  static String _extractText(dom.Element element) {
    final buffer = StringBuffer();
    for (var node in element.nodes) {
      if (node is dom.Text) {
        buffer.write(node.text);
      } else if (node is dom.Element) {
        buffer.write(_extractText(node));
      }
    }
    return buffer.toString();
  }
}

/// Widget to display a canticle or psalm
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
        lignesWidget.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verse number (only on the first line of the verse)
              SizedBox(
                width: PsalmConfig.largeurNumero,
                child: i == 0
                    ? Text(
                        '${verset.numero}',
                        textAlign: TextAlign.right,
                        style: numeroStyle ??
                            TextStyle(
                              fontWeight: PsalmConfig.grasNumeros,
                              color: PsalmConfig.couleurRouge,
                              fontSize: PsalmConfig.tailleNumero,
                            ),
                      )
                    : const SizedBox(),
              ),
              SizedBox(width: espacementNumero),
              // Line text
              Expanded(
                child: _buildLigneTexte(verset.lignes[i]),
              ),
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lignesWidget,
    );
  }

  Widget _buildLigneTexte(String ligne) {
    // Replace R/ with ℟ and V/ with ℣
    ligne = ligne.replaceAll('R/', '℟').replaceAll('V/', '℣');

    // Parse the line to make +, *, ℟ and ℣ red
    final spans = <TextSpan>[];
    final buffer = StringBuffer();

    for (int i = 0; i < ligne.length; i++) {
      final char = ligne[i];

      if (char == '+' || char == '*' || char == '℟' || char == '℣') {
        // Add accumulated text in black
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(
            text: buffer.toString(),
            style: versetStyle ??
                TextStyle(
                  fontSize: PsalmConfig.tailleTexte,
                  height: PsalmConfig.espacementLignes,
                ),
          ));
          buffer.clear();
        }

        // Add the special character in red (less bold)
        spans.add(TextSpan(
          text: char,
          style: (versetStyle ??
                  TextStyle(
                      fontSize: PsalmConfig.tailleTexte,
                      height: PsalmConfig.espacementLignes))
              .copyWith(
                  color: PsalmConfig.couleurRouge,
                  fontWeight: PsalmConfig.grasFaibleSymboles),
        ));
      } else {
        buffer.write(char);
      }
    }

    // Add the remaining text
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(
        text: buffer.toString(),
        style: versetStyle ??
            TextStyle(
              fontSize: PsalmConfig.tailleTexte,
              height: PsalmConfig.espacementLignes,
            ),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }
}

/// Complete widget to display a canticle from HTML
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
