import 'package:aelf_flutter/models/liturgy_tab_data.dart';

/// Parser spécialisé pour les messes
class MassParser {
  /// Parse les données de messe et retourne les onglets
  static LiturgyParseResult parse(Map aelfJson) {
    final List<String> tabTitles = [];
    final List<LiturgyTabData> tabData = [];
    final List<int> massPositions = [];

    if (!aelfJson.containsKey("messes")) {
      return LiturgyParseResult(
        tabTitles: ["Erreur"],
        tabData: [LiturgyTabData.error("Format de données invalide")],
      );
    }

    final masses = aelfJson["messes"];

    // Vérifier si c'est une Map avec une erreur technique (pas une List)
    if (masses is Map && masses.containsKey("erreur_technique")) {
      return LiturgyParseResult(
        tabTitles: ["Erreur"],
        tabData: [LiturgyTabData.error(masses["erreur_technique"])],
      );
    }

    // Vérifier que masses est bien une liste
    if (masses is! List) {
      return LiturgyParseResult(
        tabTitles: ["Erreur"],
        tabData: [
          LiturgyTabData.error(
              "Format de données invalide (messes n'est pas une liste)")
        ],
      );
    }

    // Parser chaque messe
    for (int massIndex = 0; massIndex < masses.length; massIndex++) {
      // Ajouter le menu de sélection des messes si plusieurs messes
      if (masses.length > 1) {
        massPositions.add(tabTitles.length);
        tabTitles.add("Messes");
        tabData.add(LiturgyTabData(
          title: "Messes",
          content: "__MASS_MENU__", // Marqueur spécial pour le menu
        ));
      }

      // Parser les lectures de cette messe
      final lectures = masses[massIndex]["lectures"];
      for (var lecture in lectures) {
        final tabInfo = _parseLecture(lecture);
        if (tabInfo != null) {
          tabTitles.add(tabInfo.title);
          tabData.add(tabInfo);
        }
      }
    }

    return LiturgyParseResult(
      tabTitles: tabTitles,
      tabData: tabData,
      massPositions: massPositions,
    );
  }

  /// Parse une lecture individuelle
  static LiturgyTabData? _parseLecture(Map lecture) {
    final String type = lecture["type"] ?? "";
    final String ref = lecture["ref"] ?? "";
    final String content = lecture["contenu"] ?? "";

    switch (type) {
      case 'sequence':
        return LiturgyTabData(
          title: "Séquence",
          content: content,
        );

      case 'entree_messianique':
        return LiturgyTabData(
          title: "Entrée messianique",
          subtitle: lecture["intro_lue"] ?? "",
          ref: ref,
          content: content,
        );

      case 'psaume':
        return LiturgyTabData(
          title: "Psaume",
          subtitle: lecture["refrain_psalmique"] ?? "",
          ref: ref.contains("Ps") ? ref : "Ps $ref",
          content: content,
        );

      case 'cantique':
        return LiturgyTabData(
          title: "Cantique",
          subtitle: lecture["refrain_psalmique"] ?? "",
          ref: ref,
          content: content,
        );

      case 'evangile':
        return LiturgyTabData(
          title: "Évangile",
          contentTitle: lecture["titre"], // Titre détaillé dans le contenu
          subtitle: lecture["intro_lue"] ?? "",
          intro: lecture["verset_evangile"] ?? "",
          introRef: lecture["ref_verset"] ?? "",
          ref: ref,
          content: content,
        );

      case 'epitre':
        return LiturgyTabData(
          title: "Épître",
          contentTitle: lecture["titre"], // Titre détaillé dans le contenu
          subtitle: lecture["intro_lue"] ?? "",
          ref: ref,
          content: content,
        );

      default:
        // Gérer les lectures numérotées (lecture_1, lecture_2, etc.)
        if (type.contains("lecture_")) {
          final nb = type.split('_')[1];
          final index = [
            "Première",
            "Deuxième",
            "Troisième",
            "Quatrième",
            "Cinquième",
            "Sixième",
            "Septième",
            "Huitième",
            "Neuvième",
            "Dixième"
          ];

          final int number = int.tryParse(nb) ?? 1;
          final String tabTitle = number <= index.length
              ? "${index[number - 1]} Lecture"
              : "Lecture $nb";

          return LiturgyTabData(
            title: tabTitle, // Titre court pour l'onglet
            contentTitle: lecture["titre"], // Titre détaillé pour le contenu
            subtitle: lecture["intro_lue"] ?? "",
            ref: ref,
            content: content,
          );
        }
        return null;
    }
  }
}
