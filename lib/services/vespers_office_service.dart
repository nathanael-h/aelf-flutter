import 'package:offline_liturgy/classes/vespers_class.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/offices/vespers/vespers.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';

/// Represents the complete resolved state of a Vespers Office
class ResolvedVespersOffice {
  final String celebrationKey;
  final VespersDefinition celebration;
  final String? selectedCommon;
  final Vespers vespersData;
  final Map<String, dynamic> psalmsCache;

  ResolvedVespersOffice({
    required this.celebrationKey,
    required this.celebration,
    this.selectedCommon,
    required this.vespersData,
    required this.psalmsCache,
  });
}

/// Service class to handle all Vespers Office data resolution and loading
/// Separates business logic from UI widgets
class VespersOfficeService {
  final DataLoader dataLoader;

  VespersOfficeService({required this.dataLoader});

  /// Get the first celebrable option from the vespers list
  MapEntry<String, VespersDefinition>? getFirstCelebrableOption(
    Map<String, VespersDefinition> vespersList,
  ) {
    final celebrableEntries =
        vespersList.entries.where((entry) => entry.value.isCelebrable).toList();

    return celebrableEntries.isNotEmpty ? celebrableEntries.first : null;
  }

  /// Determine which common should be auto-selected based on celebration
  /// Returns:
  /// - null if no common available or if ferial celebration
  /// - first common if one or more commons available (always auto-select first)
  String? determineAutoCommon(VespersDefinition celebration) {
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

  /// Resolve the complete Vespers Office with all data loaded
  Future<ResolvedVespersOffice> resolveCompleteVespersOffice({
    required String celebrationKey,
    required VespersDefinition celebration,
    String? common,
    required DateTime date,
  }) async {
    // Step 1: Resolve the vespers data
    final celebrationContext = CelebrationContext(
      celebrationCode: celebration.celebrationCode,
      ferialCode: celebration.ferialCode,
      common: common,
      date: date,
      liturgicalTime: celebration.liturgicalTime,
      breviaryWeek: celebration.breviaryWeek,
      precedence: celebration.precedence,
      dataLoader: dataLoader,
    );
    final vespersData = await vespersResolution(celebrationContext);

    // Step 2: Collect all psalm codes
    final allPsalmCodes = <String>[];

    if (vespersData.psalmody != null) {
      for (var entry in vespersData.psalmody!) {
        if (entry.psalm != null) {
          allPsalmCodes.add(entry.psalm!);
        }
      }
    }

    // Step 3: Load all psalms
    final psalmsCache = allPsalmCodes.isNotEmpty
        ? await PsalmsLibrary.getPsalms(allPsalmCodes, dataLoader)
        : <String, dynamic>{};

    // Step 4: Return complete resolved office
    return ResolvedVespersOffice(
      celebrationKey: celebrationKey,
      celebration: celebration,
      selectedCommon: common,
      vespersData: vespersData,
      psalmsCache: psalmsCache,
    );
  }
}
