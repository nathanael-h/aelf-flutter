import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:yaml/yaml.dart';

/// Represents the complete resolved state of a Morning Office
class ResolvedMorningOffice {
  final String celebrationKey;
  final CelebrationContext celebration;
  final String? selectedCommon;
  final Morning morningData;
  final Map<String, String> commonTitles; // NOUVEAU : Titres pré-chargés

  ResolvedMorningOffice({
    required this.celebrationKey,
    required this.celebration,
    this.selectedCommon,
    required this.morningData,
    this.commonTitles = const {},
  });
}

/// Service class to handle all Morning Office data resolution and loading
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
  String? determineAutoCommon(CelebrationContext celebration) {
    final commonList = celebration.commonList;

    if (commonList == null || commonList.isEmpty) {
      return null;
    }

    if (celebration.celebrationCode == celebration.ferialCode) {
      return null;
    }

    return commonList.first;
  }

  /// Resolve the complete Morning Office with all data loaded.
  Future<ResolvedMorningOffice> resolveCompleteMorningOffice({
    required String celebrationKey,
    required CelebrationContext celebration,
    String? common,
    required DateTime date,
  }) async {
    // 1. Update CelebrationContext with the selected common
    final celebrationContext = celebration.copyWith(
      commonList: common != null ? [common] : null,
      date: date,
    );

    // 2. Load Office Data AND Common Titles in parallel
    final results = await Future.wait([
      morningExport(celebrationContext),
      _loadCommonTitles(celebration.commonList, celebrationContext.dataLoader),
    ]);

    final morningData = results[0] as Morning;
    final titles = results[1] as Map<String, String>;

    return ResolvedMorningOffice(
      celebrationKey: celebrationKey,
      celebration: celebrationContext,
      selectedCommon: common,
      morningData: morningData,
      commonTitles: titles,
    );
  }

  /// Helper to load YAML titles for commons
  Future<Map<String, String>> _loadCommonTitles(
      List<String>? commonList, DataLoader dataLoader) async {
    if (commonList == null || commonList.isEmpty) return {};

    final titles = <String, String>{};

    // Parallel loading of all common files
    await Future.wait(commonList.map((commonCode) async {
      try {
        final filePath = 'calendar_data/commons/$commonCode.yaml';
        final fileContent = await dataLoader.loadYaml(filePath);

        if (fileContent.isNotEmpty) {
          final yamlData = loadYaml(fileContent);
          final data = _convertYamlToDart(yamlData);
          final commonTitle = data['commonTitle'] as String?;
          titles[commonCode] = commonTitle ?? commonCode;
        } else {
          titles[commonCode] = commonCode;
        }
      } catch (e) {
        titles[commonCode] = commonCode;
      }
    }));

    return titles;
  }

  /// Recursively converts YamlMap/YamlList to Map/List
  dynamic _convertYamlToDart(dynamic value) {
    if (value is YamlMap) {
      return value
          .map((key, val) => MapEntry(key.toString(), _convertYamlToDart(val)));
    } else if (value is YamlList) {
      return value.map((item) => _convertYamlToDart(item)).toList();
    } else {
      return value;
    }
  }
}
