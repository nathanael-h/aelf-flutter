import 'package:aelf_flutter/models/liturgy_tab_data.dart';
import 'package:aelf_flutter/utils/text_management.dart';

/// Parser spécialisé pour les offices (laudes, vêpres, complies, etc.)
class OfficeParser {
  /// Parse les données d'un office et retourne les onglets
  static LiturgyParseResult parse(Map aelfJson) {
    final List<String> tabTitles = [];
    final List<LiturgyTabData> tabData = [];

    // Récupérer le type d'office (première clé du JSON)
    final String officeType = aelfJson.keys.first;
    final Map office = aelfJson[officeType];

    // Parser chaque partie de l'office
    office.forEach((dynamic partKey, dynamic partValue) {
      // Ignorer les valeurs null, vides, ou les tableaux vides
      if (partValue == null || partValue.toString().isEmpty) return;
      if (partValue is List && partValue.isEmpty) return;

      final tabInfo = _parsePart(
        partKey: partKey.toString(),
        partValue: partValue,
        office: office,
      );

      if (tabInfo != null) {
        tabTitles.add(tabInfo.title);
        tabData.add(tabInfo);
      }
    });

    return LiturgyParseResult(
      tabTitles: tabTitles,
      tabData: tabData,
    );
  }

  /// Parse une partie individuelle de l'office
  static LiturgyTabData? _parsePart({
    required String partKey,
    required dynamic partValue,
    required Map office,
  }) {
    // Extraire la référence si elle existe
    String ref = "";
    if (partValue is Map && partValue.containsKey("reference")) {
      ref = partValue["reference"] ?? "";
    }

    switch (partKey) {
      case 'introduction':
        return LiturgyTabData(
          title: "Introduction",
          content: partValue.toString(),
        );

      case 'psaume_invitatoire':
        return _parsePsaumeInvitatoire(partValue, office, ref);

      case 'hymne':
        return _parseHymne(partValue);

      case 'cantique_mariale':
        return _parseCantiqueMariale(partValue, office, ref);

      case 'pericope':
        return _parsePericope(partValue, office, ref);

      case 'lecture':
        return _parseLecture(partValue, office, ref);

      case 'te_deum':
        if (partValue is! Map) return null;
        return LiturgyTabData(
          title: partValue["titre"] ?? "Te Deum",
          ref: ref,
          content: partValue["texte"] ?? "",
        );

      case 'texte_patristique':
        return _parseTextePatristique(partValue, office, ref);

      case 'intercession':
        return LiturgyTabData(
          title: "Intercession",
          ref: ref,
          content: partValue.toString(),
        );

      case 'notre_pere':
        return _parseNotrePere();

      case 'oraison':
        return _parseOraison(partValue, ref);

      case 'hymne_mariale':
        if (partValue is! Map) return null;
        return LiturgyTabData(
          title: partValue["titre"] ?? "Hymne mariale",
          content: partValue["texte"] ?? "",
        );

      case 'verset_psaume':
        return LiturgyTabData(
          title: "Verset",
          content: partValue.toString(),
        );

      case 'erreur_technique':
        return LiturgyTabData.error(partValue.toString());

      default:
        // Gérer les psaumes et cantiques numérotés
        if (partKey.contains("psaume_") || partKey.contains("cantique_")) {
          return _parsePsaumeOrCantique(partKey, partValue, office);
        }
        return null;
    }
  }

  static LiturgyTabData? _parsePsaumeInvitatoire(
      dynamic partValue, Map office, String ref) {
    if (partValue is! Map) return null;

    String subtitle = office.containsKey("antienne_invitatoire")
        ? office["antienne_invitatoire"]
        : "";
    subtitle = addAntienneBefore(subtitle);

    String text = (partValue["texte"] ?? "")
        .replaceAll(RegExp(r'</p>$'), '<br /><br />Gloire au Père, ...</p>');

    return LiturgyTabData(
      title: "Psaume invitatoire",
      subtitle: subtitle,
      repeatSubtitle: true,
      ref: ref.isNotEmpty ? "Ps $ref" : "",
      content: text,
    );
  }

  static LiturgyTabData? _parseHymne(dynamic partValue) {
    if (partValue is! Map) return null;

    return LiturgyTabData(
      title: "Hymne",
      subtitle: partValue["titre"] ?? "",
      content: partValue["texte"] ?? "",
    );
  }

  static LiturgyTabData? _parseCantiqueMariale(
      dynamic partValue, Map office, String ref) {
    if (partValue is! Map) return null;

    String subtitle = office.containsKey("antienne_magnificat")
        ? office["antienne_magnificat"]
        : "";
    subtitle = addAntienneBefore(subtitle);

    return LiturgyTabData(
      title: partValue["titre"] ?? "Cantique",
      subtitle: subtitle,
      repeatSubtitle: true,
      ref: ref,
      content: partValue["texte"] ?? "",
    );
  }

  static LiturgyTabData? _parsePericope(
      dynamic partValue, Map office, String ref) {
    if (partValue is! Map) return null;

    return LiturgyTabData(
      title: "Parole de Dieu",
      ref: ref,
      content:
          '${partValue["texte"] ?? ""}<p class="repons">Répons</p>${office["repons"] ?? ""}',
    );
  }

  static LiturgyTabData? _parseLecture(
      dynamic partValue, Map office, String ref) {
    if (partValue is! Map) return null;

    return LiturgyTabData(
      title: "Lecture", // Titre simple pour l'onglet
      contentTitle:
          "« ${capitalizeFirstLowerElse(partValue["titre"])} »", // Titre détaillé pour le contenu
      ref: ref,
      content:
          '${partValue["texte"] ?? ""}<p class="repons">Répons</p>${office["repons_lecture"] ?? ""}',
    );
  }

  static LiturgyTabData? _parseTextePatristique(
      dynamic partValue, Map office, String ref) {
    return LiturgyTabData(
      title: "Lecture patristique",
      contentTitle:
          '« ${office["titre_patristique"] ?? "Lecture patristique"} »',
      ref: ref,
      content:
          '$partValue<p class="repons">Répons</p>${office["repons_patristique"] ?? ""}',
    );
  }

  static LiturgyTabData _parseNotrePere() {
    return const LiturgyTabData(
      title: "Notre Père",
      content:
          "Notre Père, qui es aux cieux, <br>que ton nom soit sanctifié,<br>"
          "que ton règne vienne,<br>que ta volonté soit faite sur la terre comme au ciel.<br>"
          "Donne-nous aujourd'hui notre pain de ce jour.<br>Pardonne-nous nos offenses,<br>"
          "comme nous pardonnons aussi à ceux qui nous ont offensés.<br>"
          "Et ne nous laisse pas entrer en tentation<br>mais délivre-nous du Mal.<br><br>Amen",
    );
  }

  static LiturgyTabData _parseOraison(dynamic partValue, String ref) {
    final text = '$partValue<p class="spacer"><br></p>'
        'Que le seigneur nous bénisse, qu\'il nous garde de tout mal, '
        'et nous conduise à la vie éternelle.<br>Amen.';

    return LiturgyTabData(
      title: "Oraison et bénédiction",
      ref: ref,
      content: text,
    );
  }

  static LiturgyTabData? _parsePsaumeOrCantique(
      String partKey, dynamic partValue, Map office) {
    // Vérifier que partValue est un Map et non un tableau vide
    if (partValue is! Map) return null;

    // Extraire le numéro
    final nb = partKey.split('_')[1];
    final isPsaume = partKey.contains("psaume_");

    String title = isPsaume
        ? "Psaume ${partValue["reference"]}"
        : partValue["titre"] ?? "Cantique";

    // Récupérer l'antienne
    String subtitle =
        (office.containsKey("antienne_$nb") && office["antienne_$nb"] != null)
            ? office["antienne_$nb"]
            : "";
    subtitle = addAntienneBefore(subtitle);

    // Si pas d'antienne et psaume splitté, chercher l'antienne précédente
    if (subtitle.isEmpty && RegExp(r"- (I|V)").hasMatch(title)) {
      subtitle = _findPreviousAntienne(office, int.parse(nb));
    }

    String ref = partValue["reference"] ?? "";

    // Parser le nom du cantique si nécessaire
    if (isPsaume && ref.toLowerCase().contains("cantique")) {
      final parts = ref.split("(");
      if (parts.isNotEmpty) {
        title = capitalizeFirstLowerElse(parts[0]);
      }
      if (parts.length > 1) {
        ref = parts[1].replaceAll(RegExp(r"(\(|\).|\))"), "");
      }
    } else if (isPsaume) {
      ref = ref.isNotEmpty ? "Ps $ref" : "";
    }

    String text = (partValue["texte"] ?? "")
        .replaceAll(RegExp(r'</p>$'), '<br /><br />Gloire au Père, ...</p>');

    return LiturgyTabData(
      title: title,
      subtitle: subtitle,
      repeatSubtitle: true,
      ref: ref,
      content: text,
    );
  }

  static String _findPreviousAntienne(Map office, int currentNumber) {
    for (int i = currentNumber - 1; i > 0; i--) {
      final key = "antienne_$i";
      if (office.containsKey(key) && office[key].toString().isNotEmpty) {
        return addAntienneBefore(office[key]);
      }
    }
    return "";
  }
}
