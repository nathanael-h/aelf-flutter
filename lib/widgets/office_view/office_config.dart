/// Type of liturgical office
enum OfficeType {
  readings,
  morning,
  compline,
  vespers,
}

/// Configuration for an office view
/// Defines which sections/tabs should appear and in what order
class OfficeConfig {
  final OfficeType type;
  final String title;
  final bool hasCommonSelection;
  final bool hasCelebrationSelection;

  const OfficeConfig({
    required this.type,
    required this.title,
    this.hasCommonSelection = false,
    this.hasCelebrationSelection = true,
  });

  /// Configuration for Office of Readings (Lectures)
  /// Tabs: Introduction, Hymn, 3 Psalms, Biblical Reading, Patristic Reading, Te Deum (conditional), Conclusion
  static OfficeConfig forReadings() => const OfficeConfig(
        type: OfficeType.readings,
        title: 'Office des Lectures',
        hasCommonSelection: true,
      );

  /// Configuration for Morning Prayer (Laudes)
  /// Tabs: Introduction, Invitatoire, Hymn, 3 Psalms, Reading, Canticle (Benedictus), Conclusion
  static OfficeConfig forMorning() => const OfficeConfig(
        type: OfficeType.morning,
        title: 'Office des Laudes',
        hasCommonSelection: true,
      );

  /// Configuration for Compline (Night Prayer)
  /// Tabs: Introduction, Hymn, 1 Psalm, Reading, Canticle (Nunc Dimittis), Oration, Marial Hymn
  static OfficeConfig forCompline() => const OfficeConfig(
        type: OfficeType.compline,
        title: 'Complies',
        hasCommonSelection: false,
      );

  /// Calculate total number of tabs for this office with given psalm count
  int calculateTabCount(int psalmCount, {bool hasTeDeum = false}) {
    switch (type) {
      case OfficeType.readings:
        // Introduction + Hymn + Psalms + Biblical + Patristic + Conclusion (+ Te Deum if applicable, before Conclusion)
        return 5 + psalmCount + (hasTeDeum ? 1 : 0);
      case OfficeType.morning:
        // Introduction + Invitatoire + Hymn + Psalms + Reading + Canticle + Conclusion
        return 7 + psalmCount;
      case OfficeType.compline:
        // Introduction + Hymn + Psalms + Reading + Canticle + Oration + Marial
        return 7 + psalmCount;
      case OfficeType.vespers:
        // To be implemented
        return 6 + psalmCount;
    }
  }

  /// Get the label for a tab at given index
  String getTabLabel(
    int index,
    int psalmCount, {
    List<String>? psalmTitles,
    bool hasTeDeum = false,
  }) {
    switch (type) {
      case OfficeType.readings:
        return _getReadingsTabLabel(
          index,
          psalmCount,
          psalmTitles: psalmTitles,
          hasTeDeum: hasTeDeum,
        );
      case OfficeType.morning:
        return _getMorningTabLabel(index, psalmCount,
            psalmTitles: psalmTitles);
      case OfficeType.compline:
        return _getComplineTabLabel(index, psalmCount,
            psalmTitles: psalmTitles);
      case OfficeType.vespers:
        return 'Tab $index';
    }
  }

  String _getReadingsTabLabel(
    int index,
    int psalmCount, {
    List<String>? psalmTitles,
    bool hasTeDeum = false,
  }) {
    if (index == 0) return 'Introduction';
    if (index == 1) return 'Hymne';
    if (index >= 2 && index < 2 + psalmCount) {
      final psalmIndex = index - 2;
      return psalmTitles != null && psalmIndex < psalmTitles.length
          ? psalmTitles[psalmIndex]
          : 'Psaume ${psalmIndex + 1}';
    }
    final afterPsalms = index - 2 - psalmCount;
    if (afterPsalms == 0) return 'Lecture biblique';
    if (afterPsalms == 1) return 'Lecture patristique';
    if (hasTeDeum && afterPsalms == 2) return 'Te Deum';
    return 'Conclusion';
  }

  String _getMorningTabLabel(
    int index,
    int psalmCount, {
    List<String>? psalmTitles,
  }) {
    if (index == 0) return 'Introduction';
    if (index == 1) return 'Invitatoire';
    if (index == 2) return 'Hymnes';
    if (index >= 3 && index < 3 + psalmCount) {
      final psalmIndex = index - 3;
      return psalmTitles != null && psalmIndex < psalmTitles.length
          ? psalmTitles[psalmIndex]
          : 'Psaume ${psalmIndex + 1}';
    }
    final afterPsalms = index - 3 - psalmCount;
    if (afterPsalms == 0) return 'Lecture';
    if (afterPsalms == 1) return 'Cantique';
    return 'Conclusion';
  }

  String _getComplineTabLabel(
    int index,
    int psalmCount, {
    List<String>? psalmTitles,
  }) {
    if (index == 0) return 'Introduction';
    if (index == 1) return 'Hymnes';
    if (index >= 2 && index < 2 + psalmCount) {
      final psalmIndex = index - 2;
      return psalmTitles != null && psalmIndex < psalmTitles.length
          ? psalmTitles[psalmIndex]
          : 'Psaume ${psalmIndex + 1}';
    }
    final afterPsalms = index - 2 - psalmCount;
    if (afterPsalms == 0) return 'Lecture';
    if (afterPsalms == 1) return 'Cantique';
    if (afterPsalms == 2) return 'Oraison';
    return 'Hymne mariale';
  }
}
