import 'package:aelf_flutter/models/liturgy_tab_data.dart';
import 'package:aelf_flutter/app_screens/mass_parser.dart';
import 'package:aelf_flutter/app_screens/office_parser.dart';
import 'package:aelf_flutter/parsers/information_parser.dart';

/// Service principal pour parser les données liturgiques
class LiturgyParserService {
  /// Parse les données JSON et retourne le résultat approprié
  static LiturgyParseResult parse(Map? aelfJson) {
    // Gérer le cas null
    if (aelfJson == null) {
      return _createLoadingResult();
    }

    // Vérifier les erreurs techniques au niveau racine
    if (aelfJson.containsKey("erreur_technique")) {
      return _createErrorResult(aelfJson["erreur_technique"]);
    }

    // Déterminer le type de liturgie et utiliser le parser approprié
    if (aelfJson.containsKey("messes")) {
      return MassParser.parse(aelfJson);
    } else if (aelfJson.containsKey("informations")) {
      return InformationParser.parse(aelfJson);
    } else {
      // C'est un office (laudes, vêpres, etc.)
      return OfficeParser.parse(aelfJson);
    }
  }

  /// Crée un résultat de chargement
  static LiturgyParseResult _createLoadingResult() {
    return LiturgyParseResult(
      tabTitles: ["Chargement"],
      tabData: [LiturgyTabData.loading()],
    );
  }

  /// Crée un résultat d'erreur
  static LiturgyParseResult _createErrorResult(String message) {
    return LiturgyParseResult(
      tabTitles: ["Erreur"],
      tabData: [LiturgyTabData.error(message)],
    );
  }
}
