/// Represents a fully resolved office with all its data loaded and ready to display
class ResolvedOffice {
  /// The key identifying which celebration was selected
  final String celebrationKey;

  /// The definition/metadata for this celebration
  final dynamic definition;

  /// The selected common (if applicable)
  final String? selectedCommon;

  /// The actual office data (Readings, Morning, or Compline)
  final dynamic officeData;

  /// Cached psalm data
  final Map<String, dynamic> psalmsCache;

  /// Whether Te Deum should be shown (for Readings office)
  final bool showTeDeum;

  const ResolvedOffice({
    required this.celebrationKey,
    required this.definition,
    required this.selectedCommon,
    required this.officeData,
    required this.psalmsCache,
    this.showTeDeum = false,
  });

  /// Get psalmody count for tab calculation
  int get psalmodyCount {
    final psalmody = _getPsalmody();
    return psalmody?.length ?? 0;
  }

  /// Get psalm titles for tab labels
  List<String> get psalmTitles {
    final psalmody = _getPsalmody();
    if (psalmody == null) return [];

    return psalmody.map((entry) {
      final psalmKey = _getPsalmKey(entry);
      if (psalmKey == null) return 'Psaume';

      final psalm = psalmsCache[psalmKey];
      if (psalm == null) return psalmKey;

      return _getPsalmDisplayTitle(psalm, psalmKey);
    }).toList();
  }

  List<dynamic>? _getPsalmody() {
    try {
      return (officeData as dynamic).psalmody as List<dynamic>?;
    } catch (e) {
      return null;
    }
  }

  String? _getPsalmKey(dynamic entry) {
    try {
      return (entry as dynamic).psalm as String?;
    } catch (e) {
      return null;
    }
  }

  String _getPsalmDisplayTitle(dynamic psalm, String psalmKey) {
    try {
      final title = (psalm as dynamic).title as String?;
      if (title != null && title.isNotEmpty) {
        return title;
      }
      return psalmKey;
    } catch (e) {
      return psalmKey;
    }
  }
}
