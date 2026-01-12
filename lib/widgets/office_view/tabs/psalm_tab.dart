import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/office_common_widgets.dart';

/// Builds psalm tabs dynamically based on psalmody
class PsalmTab {
  static List<Widget> buildPsalmTabs({
    required ResolvedOffice resolved,
    required DataLoader dataLoader,
    required OfficeType officeType,
  }) {
    final views = <Widget>[];

    try {
      final psalmody = (resolved.officeData as dynamic).psalmody as List<dynamic>?;
      if (psalmody == null) return views;

      int psalmIndex = 0;
      for (var psalmEntry in psalmody) {
        final psalmKey = (psalmEntry as dynamic).psalm as String?;
        if (psalmKey == null) continue;

        final antiphons = (psalmEntry as dynamic).antiphon as List<dynamic>?;

        // For Readings office, add verse after 3rd psalm
        String? verseAfter;
        if (officeType == OfficeType.readings && psalmIndex == 2) {
          try {
            verseAfter = (resolved.officeData as dynamic).verse as String?;
          } catch (e) {
            verseAfter = null;
          }
        }

        views.add(
          PsalmTabWidget(
            psalmKey: psalmKey,
            psalmsCache: resolved.psalmsCache,
            dataLoader: dataLoader,
            antiphon1: antiphons != null && antiphons.isNotEmpty
                ? antiphons[0].toString()
                : null,
            antiphon2: antiphons != null && antiphons.length > 1
                ? antiphons[1].toString()
                : null,
            verseAfter: verseAfter,
          ),
        );

        psalmIndex++;
      }
    } catch (e) {
      // Error accessing psalmody
    }

    return views;
  }
}
