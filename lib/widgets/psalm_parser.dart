import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// ============================================
/// CONFIGURATION DES PARAMÈTRES D'AFFICHAGE
/// Modifiez ces valeurs pour personnaliser l'apparence
/// ============================================
class PsalmConfig {
  // ===== COULEURS =====
  /// Couleur des numéros de verset et des symboles spéciaux (+, *, ℟, ℣)
  static const Color couleurRouge = Colors.red;

  // ===== ESPACEMENTS =====
  /// Espacement entre les paragraphes (en pixels)
  static const double espacementParagraphes = 16.0;

  /// Espacement entre le numéro de verset et le texte (en pixels)
  static const double espacementNumeroTexte = 5.0;

  /// Espacement entre les lignes de texte (hauteur de ligne)
  /// 1.0 = simple, 1.5 = 1.5x, 2.0 = double, etc.
  static const double espacementLignes = 1.3;

  // ===== TAILLES =====
  /// Taille de police des numéros de verset
  static const double tailleNumero = 10.0;

  /// Taille de police du texte des versets
  static const double tailleTexte = 16.0;

  /// Largeur réservée pour les numéros de verset (en pixels)
  static const double largeurNumero = 40.0;

  // ===== STYLES SUPPLÉMENTAIRES =====
  /// Épaisseur des caractères spéciaux (+, *, ℟, ℣)
  static const FontWeight grasFaibleSymboles = FontWeight.w500;

  /// Épaisseur des numéros de verset
  static const FontWeight grasNumeros = FontWeight.bold;
}

/// Représente un verset avec son numéro et ses lignes de texte
class Verset {
  final int numero;
  final List<String> lignes;

  Verset({
    required this.numero,
    required this.lignes,
  });
}

/// Représente un paragraphe contenant un ou plusieurs versets
class Paragraphe {
  final List<Verset> versets;

  Paragraphe({required this.versets});
}

/// Parser générique pour tous les cantiques/psaumes HTML
class PsalmParser {
  /// Parse le HTML et retourne une liste de Paragraphes
  static List<Paragraphe> parseHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final paragraphes = <Paragraphe>[];

    // Récupérer tous les <p> (un <p> = un paragraphe)
    final pElements = document.querySelectorAll('p');

    for (var pElement in pElements) {
      final versets = _parseParagraphe(pElement);
      if (versets.isNotEmpty) {
        paragraphes.add(Paragraphe(versets: versets));
      }
    }

    return paragraphes;
  }

  /// Parse un élément <p> et extrait tous les versets qu'il contient
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
        // Si c'est un numéro de verset
        if (node.className == 'verse_number') {
          // Finaliser la ligne en cours si elle existe
          if (currentLigne.trim().isNotEmpty) {
            currentLignes.add(currentLigne.trim());
            currentLigne = '';
          }

          // Finaliser le verset précédent
          finalizeVerset();

          // Commencer un nouveau verset
          currentVersetNumero = int.tryParse(node.text.trim());
        }
        // Si c'est un <br>, ça marque une nouvelle ligne
        else if (node.localName == 'br') {
          if (currentLigne.trim().isNotEmpty) {
            currentLignes.add(currentLigne.trim());
            currentLigne = '';
          }
        }
        // Si c'est un <u> (accent), récupérer le texte
        else if (node.localName == 'u') {
          currentLigne += node.text;
        }
        // Autres éléments
        else {
          currentLigne += _extractText(node);
        }
      }
      // Si c'est du texte simple
      else if (node is dom.Text) {
        currentLigne += node.text;
      }
    }

    // Finaliser la dernière ligne et le dernier verset
    if (currentLigne.trim().isNotEmpty) {
      currentLignes.add(currentLigne.trim());
    }
    finalizeVerset();

    return versets;
  }

  /// Extrait tout le texte d'un élément, y compris les sous-éléments
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

/// Widget pour afficher un cantique ou psaume
class PsalmWidget extends StatelessWidget {
  final List<Paragraphe> paragraphes;
  final TextStyle? versetStyle;
  final TextStyle? numeroStyle;
  final double espacementParagraphes;
  final double espacementNumero;

  const PsalmWidget({
    Key? key,
    required this.paragraphes,
    this.versetStyle,
    this.numeroStyle,
    this.espacementParagraphes = PsalmConfig.espacementParagraphes,
    this.espacementNumero = PsalmConfig.espacementNumeroTexte,
  }) : super(key: key);

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
              // Numéro de verset (uniquement sur la première ligne du verset)
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
              // Texte de la ligne
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
    // Remplacer R/ par ℟ et V/ par ℣
    ligne = ligne.replaceAll('R/', '℟').replaceAll('V/', '℣');

    // Parser la ligne pour mettre +, *, ℟ et ℣ en rouge
    final spans = <TextSpan>[];
    final buffer = StringBuffer();

    for (int i = 0; i < ligne.length; i++) {
      final char = ligne[i];

      if (char == '+' || char == '*' || char == '℟' || char == '℣') {
        // Ajouter le texte accumulé en noir
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

        // Ajouter le caractère spécial en rouge (moins gras)
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

    // Ajouter le reste du texte
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

/// Widget complet pour afficher un cantique à partir de HTML
class PsalmFromHtml extends StatelessWidget {
  final String htmlContent;
  final String? titre;
  final TextStyle? versetStyle;
  final TextStyle? numeroStyle;
  final TextStyle? titreStyle;

  const PsalmFromHtml({
    Key? key,
    required this.htmlContent,
    this.titre,
    this.versetStyle,
    this.numeroStyle,
    this.titreStyle,
  }) : super(key: key);

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
