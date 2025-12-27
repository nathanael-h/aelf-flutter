import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_selector.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';

/// ============================================
/// UTILITY FUNCTIONS
/// ============================================

/// Gets psalm display title with fallbacks
/// Returns title if available, otherwise shortReference, subtitle, or psalmKey
String getPsalmDisplayTitle(dynamic psalm, String psalmKey) {
  if (psalm?.getTitle != null && psalm!.getTitle!.isNotEmpty) {
    return psalm.getTitle!;
  }
  return psalm?.getShortReference ?? psalm?.getSubtitle ?? psalmKey;
}

/// Loads all psalms from a psalmody list
/// Returns a map of psalm codes to Psalm objects
Future<Map<String, dynamic>> loadPsalmsFromPsalmody(
  List<dynamic>? psalmody,
  DataLoader dataLoader,
) async {
  final allPsalmCodes = <String>[];

  if (psalmody != null) {
    for (var entry in psalmody) {
      if (entry.psalm != null) {
        allPsalmCodes.add(entry.psalm!);
      }
    }
  }

  if (allPsalmCodes.isEmpty) {
    return <String, dynamic>{};
  }

  return await PsalmsLibrary.getPsalms(allPsalmCodes, dataLoader);
}

/// ============================================
/// COMMON WIDGETS
/// ============================================

/// Hymns tab widget - displays hymn selector
/// Used by both Morning and Compline offices
class HymnsTabWidget extends StatelessWidget {
  const HymnsTabWidget({
    super.key,
    required this.hymns,
    required this.dataLoader,
    this.emptyMessage,
  });

  final List<String> hymns;
  final DataLoader dataLoader;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (hymns.isEmpty) {
      return Center(
        child: Text(emptyMessage ?? 'No hymn available'),
      );
    }
    return HymnSelectorWithTitle(
      title: liturgyLabels['hymns'] ?? 'Hymnes',
      hymns: hymns,
      dataLoader: dataLoader,
    );
  }
}

/// Psalm tab widget - displays a single psalm with antiphons
/// Used by both Morning and Compline offices
class PsalmTabWidget extends StatelessWidget {
  const PsalmTabWidget({
    super.key,
    required this.psalmKey,
    required this.psalmsCache,
    required this.dataLoader,
    this.antiphon1,
    this.antiphon2,
  });

  final String? psalmKey;
  final Map<String, dynamic> psalmsCache;
  final DataLoader dataLoader;
  final String? antiphon1;
  final String? antiphon2;

  @override
  Widget build(BuildContext context) {
    return PsalmDisplayWidget(
      psalmKey: psalmKey,
      psalms: psalmsCache,
      dataLoader: dataLoader,
      antiphon1: antiphon1,
      antiphon2: antiphon2,
    );
  }
}
