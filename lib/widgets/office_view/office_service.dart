import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/classes/readings_class.dart';
import 'package:offline_liturgy/classes/morning_class.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/offices/readings/readings.dart';
import 'package:offline_liturgy/offices/morning/morning.dart';
import 'package:offline_liturgy/offices/compline/compline.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';

/// Unified service for resolving all office types
/// Handles data loading, celebration selection, and resource caching
class OfficeService {
  final OfficeConfig config;
  final DataLoader dataLoader;

  OfficeService({
    required this.config,
    required this.dataLoader,
  });

  /// Resolve a complete office from definitions
  Future<ResolvedOffice> resolve({
    required Map<String, dynamic> definitions,
    required DateTime date,
    String? preselectedKey,
    String? preselectedCommon,
  }) async {
    // 1. Select celebration
    final selected = _selectCelebration(definitions, preselectedKey);
    if (selected == null) {
      throw Exception('No celebrable office found');
    }

    // 2. Determine common (if applicable)
    String? selectedCommon = preselectedCommon;
    if (selectedCommon == null && config.hasCommonSelection) {
      selectedCommon = _determineAutoCommon(selected.value);
    }

    // 3. Resolve office data based on type
    final officeData = await _resolveOfficeData(
      selected: selected,
      date: date,
      common: selectedCommon,
    );

    // 4. Load resources (psalms)
    final psalmsCache = await _loadPsalms(officeData);

    // 5. Determine Te Deum flag
    final showTeDeum = _shouldShowTeDeum(officeData, selected.value);

    return ResolvedOffice(
      celebrationKey: selected.key,
      definition: selected.value,
      selectedCommon: selectedCommon,
      officeData: officeData,
      psalmsCache: psalmsCache,
      showTeDeum: showTeDeum,
    );
  }

  /// Select the first celebrable option from definitions
  MapEntry<String, dynamic>? _selectCelebration(
    Map<String, dynamic> definitions,
    String? preselectedKey,
  ) {
    if (preselectedKey != null && definitions.containsKey(preselectedKey)) {
      return MapEntry(preselectedKey, definitions[preselectedKey]);
    }

    return definitions.entries
        .where((entry) => _isCelebrable(entry.value))
        .firstOrNull;
  }

  bool _isCelebrable(dynamic definition) {
    try {
      return (definition as dynamic).isCelebrable as bool? ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Determine auto-selected common if applicable
  String? _determineAutoCommon(dynamic definition) {
    try {
      final commonList = (definition as dynamic).commonList as List<String>?;
      if (commonList == null || commonList.isEmpty) return null;

      // Don't auto-select for ferial celebrations
      final celebrationCode = (definition as dynamic).celebrationCode as String?;
      final ferialCode = (definition as dynamic).ferialCode as String?;
      if (celebrationCode == ferialCode) return null;

      return commonList.first;
    } catch (e) {
      return null;
    }
  }

  /// Resolve office data based on type
  Future<dynamic> _resolveOfficeData({
    required MapEntry<String, dynamic> selected,
    required DateTime date,
    String? common,
  }) async {
    switch (config.type) {
      case OfficeType.readings:
        return await _resolveReadings(selected, date, common);
      case OfficeType.morning:
        return await _resolveMorning(selected, date, common);
      case OfficeType.compline:
        return _resolveCompline(selected);
      case OfficeType.vespers:
        throw UnimplementedError('Vespers not yet implemented');
    }
  }

  Future<dynamic> _resolveReadings(
    MapEntry<String, dynamic> selected,
    DateTime date,
    String? common,
  ) async {
    final definition = selected.value as ReadingsDefinition;
    return await readingsResolution(
      definition.celebrationCode,
      definition.ferialCode,
      common,
      date,
      definition.breviaryWeek,
      dataLoader,
      precedence: definition.precedence,
      teDeum: definition.teDeum,
    );
  }

  Future<dynamic> _resolveMorning(
    MapEntry<String, dynamic> selected,
    DateTime date,
    String? common,
  ) async {
    final definition = selected.value as MorningDefinition;
    return await morningResolution(
      definition.celebrationCode,
      definition.ferialCode,
      common,
      date,
      definition.breviaryWeek,
      dataLoader,
      precedence: definition.precedence,
    );
  }

  dynamic _resolveCompline(MapEntry<String, dynamic> selected) {
    final definition = selected.value as ComplineDefinition;
    final singleMap = {selected.key: definition};
    final compiled = complineTextCompilation(singleMap);
    return compiled.values.first;
  }

  /// Load psalms from office data
  Future<Map<String, dynamic>> _loadPsalms(dynamic officeData) async {
    final allPsalmCodes = <String>[];

    try {
      final psalmody = (officeData as dynamic).psalmody as List<dynamic>?;
      if (psalmody != null) {
        for (var entry in psalmody) {
          final psalmCode = (entry as dynamic).psalm as String?;
          if (psalmCode != null) {
            allPsalmCodes.add(psalmCode);
          }
        }
      }
    } catch (e) {
      // No psalmody or error accessing it
    }

    // For Morning office, also load invitatory psalms
    if (config.type == OfficeType.morning) {
      try {
        final invitatory = (officeData as dynamic).invitatory;
        if (invitatory != null) {
          final psalms = (invitatory as dynamic).psalms as List<dynamic>?;
          if (psalms != null) {
            for (var psalm in psalms) {
              allPsalmCodes.add(psalm.toString());
            }
          }
        }
      } catch (e) {
        // No invitatory or error
      }
    }

    if (allPsalmCodes.isEmpty) {
      return {};
    }

    return await PsalmsLibrary.getPsalms(allPsalmCodes, dataLoader);
  }

  /// Determine if Te Deum should be shown (for Readings office)
  bool _shouldShowTeDeum(dynamic officeData, dynamic definition) {
    if (config.type != OfficeType.readings) return false;

    try {
      return (officeData as dynamic).tedeum as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
