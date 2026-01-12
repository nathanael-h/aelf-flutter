import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/widgets/office_view/tabs/introduction_tab.dart';
import 'package:aelf_flutter/widgets/office_view/tabs/invitatory_tab.dart';
import 'package:aelf_flutter/widgets/office_view/tabs/hymn_tab.dart';
import 'package:aelf_flutter/widgets/office_view/tabs/psalm_tab.dart';
import 'package:aelf_flutter/widgets/office_view/tabs/reading_tab.dart';
import 'package:aelf_flutter/widgets/office_view/tabs/canticle_tab.dart';
import 'package:aelf_flutter/widgets/office_view/tabs/conclusion_tab.dart';

/// Builds tab views for different office types
class OfficeTabBuilder {
  static List<Widget> buildTabViews({
    required OfficeConfig config,
    required ResolvedOffice resolved,
    required Map<String, dynamic> definitions,
    required DataLoader dataLoader,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
    dynamic additionalData,
  }) {
    switch (config.type) {
      case OfficeType.readings:
        return _buildReadingsTabs(
          resolved: resolved,
          definitions: definitions,
          dataLoader: dataLoader,
          onCelebrationChanged: onCelebrationChanged,
          onCommonChanged: onCommonChanged,
        );
      case OfficeType.morning:
        return _buildMorningTabs(
          resolved: resolved,
          definitions: definitions,
          dataLoader: dataLoader,
          onCelebrationChanged: onCelebrationChanged,
          onCommonChanged: onCommonChanged,
        );
      case OfficeType.compline:
        return _buildComplineTabs(
          resolved: resolved,
          definitions: definitions,
          dataLoader: dataLoader,
          onCelebrationChanged: onCelebrationChanged,
          additionalData: additionalData,
        );
      case OfficeType.vespers:
        throw UnimplementedError('Vespers not yet implemented');
    }
  }

  static List<Widget> _buildReadingsTabs({
    required ResolvedOffice resolved,
    required Map<String, dynamic> definitions,
    required DataLoader dataLoader,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
  }) {
    final views = <Widget>[
      // Introduction tab
      IntroductionTab(
        officeType: OfficeType.readings,
        resolved: resolved,
        definitions: definitions,
        dataLoader: dataLoader,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
      ),
      // Hymn tab
      HymnTab(
        resolved: resolved,
        dataLoader: dataLoader,
      ),
    ];

    // Psalm tabs
    views.addAll(
      PsalmTab.buildPsalmTabs(
        resolved: resolved,
        dataLoader: dataLoader,
        officeType: OfficeType.readings,
      ),
    );

    // Biblical reading tab
    views.add(
      ReadingTab(
        resolved: resolved,
        readingType: ReadingType.biblical,
      ),
    );

    // Patristic reading tab
    views.add(
      ReadingTab(
        resolved: resolved,
        readingType: ReadingType.patristic,
      ),
    );

    // Te Deum tab (conditional)
    if (resolved.showTeDeum) {
      views.add(
        ReadingTab(
          resolved: resolved,
          readingType: ReadingType.teDeum,
        ),
      );
    }

    // Conclusion tab (oration + blessing)
    views.add(
      ConclusionTab(
        resolved: resolved,
        dataLoader: dataLoader,
        officeType: OfficeType.readings,
      ),
    );

    return views;
  }

  static List<Widget> _buildMorningTabs({
    required ResolvedOffice resolved,
    required Map<String, dynamic> definitions,
    required DataLoader dataLoader,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
  }) {
    final views = <Widget>[
      // Introduction tab (without invitatory now)
      IntroductionTab(
        officeType: OfficeType.morning,
        resolved: resolved,
        definitions: definitions,
        dataLoader: dataLoader,
        onCelebrationChanged: onCelebrationChanged,
        onCommonChanged: onCommonChanged,
        showInvitatory: false,
      ),
      // Invitatory tab (new separate tab)
      InvitatoryTab(
        resolved: resolved,
        dataLoader: dataLoader,
      ),
      // Hymn tab
      HymnTab(
        resolved: resolved,
        dataLoader: dataLoader,
      ),
    ];

    // Psalm tabs
    views.addAll(
      PsalmTab.buildPsalmTabs(
        resolved: resolved,
        dataLoader: dataLoader,
        officeType: OfficeType.morning,
      ),
    );

    // Reading tab
    views.add(
      ReadingTab(
        resolved: resolved,
        readingType: ReadingType.scripture,
      ),
    );

    // Canticle tab (Benedictus)
    views.add(
      CanticleTab(
        resolved: resolved,
        dataLoader: dataLoader,
        canticleType: 'benedictus',
      ),
    );

    // Conclusion tab (intercession + Notre Père + oration)
    views.add(
      ConclusionTab(
        resolved: resolved,
        dataLoader: dataLoader,
        officeType: OfficeType.morning,
      ),
    );

    return views;
  }

  static List<Widget> _buildComplineTabs({
    required ResolvedOffice resolved,
    required Map<String, dynamic> definitions,
    required DataLoader dataLoader,
    required ValueChanged<String> onCelebrationChanged,
    dynamic additionalData,
  }) {
    final views = <Widget>[
      // Introduction tab
      IntroductionTab(
        officeType: OfficeType.compline,
        resolved: resolved,
        definitions: definitions,
        dataLoader: dataLoader,
        onCelebrationChanged: onCelebrationChanged,
        additionalData: additionalData,
      ),
      // Hymn tab
      HymnTab(
        resolved: resolved,
        dataLoader: dataLoader,
      ),
    ];

    // Psalm tabs
    views.addAll(
      PsalmTab.buildPsalmTabs(
        resolved: resolved,
        dataLoader: dataLoader,
        officeType: OfficeType.compline,
      ),
    );

    // Reading tab
    views.add(
      ReadingTab(
        resolved: resolved,
        readingType: ReadingType.scripture,
      ),
    );

    // Canticle tab (Nunc Dimittis)
    views.add(
      CanticleTab(
        resolved: resolved,
        dataLoader: dataLoader,
        canticleType: 'nunc_dimittis',
      ),
    );

    // Oration tab
    views.add(
      ConclusionTab(
        resolved: resolved,
        dataLoader: dataLoader,
        officeType: OfficeType.compline,
      ),
    );

    // Marial hymn tab
    views.add(
      HymnTab(
        resolved: resolved,
        dataLoader: dataLoader,
        isMarialHymn: true,
      ),
    );

    return views;
  }
}
