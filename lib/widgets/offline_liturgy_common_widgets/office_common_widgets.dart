import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/office_elements_class.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hymn_selector.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalms_display.dart';

/// ============================================
/// UTILITY FUNCTIONS
/// ============================================

/// Gets psalm display title with fallbacks
/// Returns title if available, otherwise shortReference, subtitle, or psalmKey
String getPsalmDisplayTitle(Psalm? psalm, String psalmKey) {
  if (psalm?.title != null && psalm!.title!.isNotEmpty) {
    return psalm.title!;
  }
  return psalm?.shortReference ?? psalm?.subtitle ?? psalmKey;
}

/// ============================================
/// COMMON WIDGETS
/// ============================================

/// Hymns tab widget - displays hymn selector
/// Uses pre-hydrated HymnEntry data (no YAML loading needed)
class HymnsTabWidget extends StatelessWidget {
  const HymnsTabWidget({
    super.key,
    required this.hymns,
    this.emptyMessage,
  });

  final List<HymnEntry> hymns;
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
    );
  }
}

/// Psalm tab widget - displays a single psalm with antiphons
/// Uses pre-hydrated psalmData (no YAML loading needed)
class PsalmTabWidget extends StatelessWidget {
  const PsalmTabWidget({
    super.key,
    required this.psalm,
    this.antiphon1,
    this.antiphon2,
    this.verseAfter,
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? verseAfter;

  @override
  Widget build(BuildContext context) {
    return PsalmDisplayWidget(
      psalm: psalm,
      antiphon1: antiphon1,
      antiphon2: antiphon2,
      verseAfter: verseAfter,
    );
  }
}
