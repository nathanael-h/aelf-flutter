import '../models/liturgy_tab_data.dart';
import '../utils/text_management.dart';

/// Parser spécialisé pour les informations liturgiques
class InformationParser {
  /// Parse les informations liturgiques et retourne un onglet unique
  static LiturgyParseResult parse(Map aelfJson) {
    if (!aelfJson.containsKey("informations")) {
      return LiturgyParseResult(
        tabTitles: ["Erreur"],
        tabData: [LiturgyTabData.error("Informations non disponibles")],
      );
    }

    final info = aelfJson["informations"];
    final String content = _buildInformationText(info);

    return LiturgyParseResult(
      tabTitles: ["Informations"],
      tabData: [
        LiturgyTabData(
          title: "Informations",
          content: content,
        ),
      ],
    );
  }

  /// Construit le texte des informations liturgiques
  static String _buildInformationText(Map info) {
    final StringBuffer buffer = StringBuffer();

    // Titre et sous-titre
    final String title = capitalizeFirstLowerElse(info["liturgical_day"] ?? "");
    final String subtitle = _buildSubtitle(info);

    buffer.writeln(title);
    if (subtitle.isNotEmpty) {
      buffer.writeln(subtitle);
    }
    buffer.writeln("---");

    // Options liturgiques
    final List options = info["liturgy_options"] ?? [];
    for (var option in options) {
      buffer.writeln("Couleur liturgique : ${option["liturgical_color"]}");
      buffer.writeln(capitalizeFirst(option["liturgical_name"]));
      buffer.writeln(option["liturgical_degree"]);
      buffer.writeln("---");
    }

    return buffer.toString();
  }

  /// Construit le sous-titre avec l'année et la semaine du psautier
  static String _buildSubtitle(Map info) {
    final int? psalterWeek = info["psalter_week"];
    if (psalterWeek == null) return "";

    final String year = info["liturgical_year"] ?? "";
    final String week = _romanizePsalterWeek(psalterWeek);

    return "Année $year - Semaine $week";
  }

  /// Convertit le numéro de semaine en chiffres romains
  static String _romanizePsalterWeek(int week) {
    switch (week) {
      case 1:
        return "I";
      case 2:
        return "II";
      case 3:
        return "III";
      case 4:
        return "IV";
      default:
        return "";
    }
  }
}
