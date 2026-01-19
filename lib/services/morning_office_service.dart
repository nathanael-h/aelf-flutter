import 'package:offline_liturgy/classes/morning_class.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/offices/morning/morning.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';

/// Represents the complete resolved state of a Morning Office
class ResolvedMorningOffice {
  final String celebrationKey;
  final MorningDefinition celebration;
  final String? selectedCommon;
  final Morning morningData;
  final Map<String, dynamic> psalmsCache;

  ResolvedMorningOffice({
    required this.celebrationKey,
    required this.celebration,
    this.selectedCommon,
    required this.morningData,
    required this.psalmsCache,
  });
}

/// Service class to handle all Morning Office data resolution and loading
/// Separates business logic from UI widgets
class MorningOfficeService {
  final DataLoader dataLoader;

  MorningOfficeService({required this.dataLoader});

  /// Get the first celebrable option from the morning list
  MapEntry<String, MorningDefinition>? getFirstCelebrableOption(
    Map<String, MorningDefinition> morningList,
  ) {
    final celebrableEntries =
        morningList.entries.where((entry) => entry.value.isCelebrable).toList();

    return celebrableEntries.isNotEmpty ? celebrableEntries.first : null;
  }

  /// Determine which common should be auto-selected based on celebration
  /// Returns:
  /// - null if no common available or if ferial celebration
  /// - first common if one or more commons available (always auto-select first)
  String? determineAutoCommon(MorningDefinition celebration) {
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

  /// Resolve the complete Morning Office with all data loaded
  Future<ResolvedMorningOffice> resolveCompleteMorningOffice({
    required String celebrationKey,
    required MorningDefinition celebration,
    String? common,
    required DateTime date,
  }) async {
    // Step 1: Resolve the morning data
    final celebrationContext = CelebrationContext(
      celebrationCode: celebration.celebrationCode,
      ferialCode: celebration.ferialCode,
      common: common,
      date: date,
      breviaryWeek: celebration.breviaryWeek,
      precedence: celebration.precedence,
      dataLoader: dataLoader,
    );
    final morningData = await morningResolution(celebrationContext);

    // Step 2: Collect all psalm codes
    final allPsalmCodes = <String>[];

    if (morningData.psalmody != null) {
      for (var entry in morningData.psalmody!) {
        if (entry.psalm != null) {
          allPsalmCodes.add(entry.psalm!);
        }
      }
    }

    if (morningData.invitatory?.psalms != null) {
      for (var psalmCode in morningData.invitatory!.psalms!) {
        allPsalmCodes.add(psalmCode.toString());
      }
    }

    // Step 3: Load all psalms
    final psalmsCache = allPsalmCodes.isNotEmpty
        ? await PsalmsLibrary.getPsalms(allPsalmCodes, dataLoader)
        : <String, dynamic>{};

    // Step 4: Return complete resolved office
    return ResolvedMorningOffice(
      celebrationKey: celebrationKey,
      celebration: celebration,
      selectedCommon: common,
      morningData: morningData,
      psalmsCache: psalmsCache,
    );
  }
}
