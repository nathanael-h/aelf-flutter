import 'package:offline_liturgy/offline_liturgy.dart';

/// Represents the complete resolved state of a Morning Office
class ResolvedMorningOffice {
  final String celebrationKey;
  final CelebrationContext celebration;
  final String? selectedCommon;
  final Morning morningData;

  ResolvedMorningOffice({
    required this.celebrationKey,
    required this.celebration,
    this.selectedCommon,
    required this.morningData,
  });
}

/// Service class to handle all Morning Office data resolution and loading
/// Separates business logic from UI widgets
class MorningOfficeService {
  final DataLoader dataLoader;

  MorningOfficeService({required this.dataLoader});

  /// Get the first celebrable option from the morning list
  MapEntry<String, CelebrationContext>? getFirstCelebrableOption(
    Map<String, CelebrationContext> morningList,
  ) {
    final celebrableEntries =
        morningList.entries.where((entry) => entry.value.isCelebrable).toList();

    return celebrableEntries.isNotEmpty ? celebrableEntries.first : null;
  }

  /// Determine which common should be auto-selected based on celebration
  /// Returns:
  /// - null if no common available or if ferial celebration
  /// - first common if one or more commons available (always auto-select first)
  String? determineAutoCommon(CelebrationContext celebration) {
    final commonList = celebration.commonList;

    // No common available
    if (commonList == null || commonList.isEmpty) {
      return null;
    }

    // For ferial celebrations, don't auto-select common
    if (celebration.celebrationCode == celebration.ferialCode) {
      return null;
    }

    // Auto-select first common (whether there's 1 or multiple)
    return commonList.first;
  }

  /// Resolve the complete Morning Office with all data loaded.
  /// Psalm and hymn data is pre-hydrated by the package resolution.
  Future<ResolvedMorningOffice> resolveCompleteMorningOffice({
    required String celebrationKey,
    required CelebrationContext celebration,
    String? common,
    required DateTime date,
  }) async {
    // Update CelebrationContext with the selected common
    final celebrationContext = celebration.copyWith(
      commonList: common != null ? [common] : null,
      date: date,
    );
    final morningData = await morningResolution(celebrationContext);

    return ResolvedMorningOffice(
      celebrationKey: celebrationKey,
      celebration: celebrationContext,
      selectedCommon: common,
      morningData: morningData,
    );
  }
}
