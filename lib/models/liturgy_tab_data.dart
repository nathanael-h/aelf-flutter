/// Modèle de données représentant un onglet de liturgie
class LiturgyTabData {
  final String title; // Titre de l'onglet (court)
  final String? contentTitle; // Titre affiché dans le contenu (détaillé)
  final String subtitle;
  final bool repeatSubtitle;
  final String intro;
  final String introRef;
  final String ref;
  final String content;

  const LiturgyTabData({
    required this.title,
    this.contentTitle, // Optionnel, si null on utilise title
    this.subtitle = "",
    this.repeatSubtitle = false,
    this.intro = "",
    this.introRef = "",
    this.ref = "",
    required this.content,
  });

  /// Retourne le titre à afficher dans le contenu
  String get displayTitle => contentTitle ?? title;

  /// Factory pour créer un onglet d'erreur
  factory LiturgyTabData.error(String message) {
    return LiturgyTabData(
      title: "Erreur",
      content: message,
    );
  }

  /// Factory pour créer un onglet de chargement
  factory LiturgyTabData.loading() {
    return const LiturgyTabData(
      title: "Chargement",
      content: "",
    );
  }
}

/// Résultat du parsing contenant tous les onglets
class LiturgyParseResult {
  final List<String> tabTitles;
  final List<LiturgyTabData> tabData;
  final List<int> massPositions;

  const LiturgyParseResult({
    required this.tabTitles,
    required this.tabData,
    this.massPositions = const [],
  });

  int get length => tabTitles.length;

  bool get isEmpty => tabTitles.isEmpty;
}
