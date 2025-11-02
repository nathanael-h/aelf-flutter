import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/classes/morning_class.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_hymn_selector.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/utils/text_management.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_evangelic_canticle_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_scripture_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_psalms_display.dart';

class morningView extends StatelessWidget {
  const morningView({
    Key? key,
    required this.morning,
  }) : super(key: key);

  final Morning morning;

  @override
  Widget build(BuildContext context) {
    // Vérifier si le Morning est vide
    if (morning.psalmody == null &&
        morning.reading == null &&
        morning.oration == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Données de l\'office non disponibles',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Vérifiez que le fichier JSON existe',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Get the number of psalms dynamically
    final int psalmCount = morning.psalmody?.length ?? 0;

    // Build tabs list dynamically based on psalm count
    List<Tab> tabs = [
      const Tab(text: 'Introduction'),
      const Tab(text: 'Hymnes'),
    ];

    // Add psalm tabs dynamically
    if (morning.psalmody != null) {
      for (int i = 0; i < psalmCount; i++) {
        final psalmEntry = morning.psalmody![i];
        final String? psalmKey = psalmEntry.psalm;
        if (psalmKey != null && psalms.containsKey(psalmKey)) {
          tabs.add(Tab(text: psalms[psalmKey]!.getTitle));
        }
      }
    }

    // Add remaining tabs
    tabs.addAll([
      const Tab(text: 'Lecture'),
      const Tab(text: 'Cantique de Zacharie'),
      const Tab(text: 'Oraison'),
    ]);

    // Build tab views dynamically
    List<Widget> tabViews = [
      // Introduction Tab
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (fixedTexts['officeIntroduction'] != null)
            Html(data: correctAelfHTML(fixedTexts['officeIntroduction']!))
          else
            const Text('Office du matin'),
          SizedBox(height: spaceBetweenElements),
          LiturgyPartRubric(
              'On peut commencer par une révision de la journée, ou par un acte pénitentiel dans la célébration commune'),
        ],
      ),

      // Hymns Tab
      if (morning.hymn != null)
        HymnSelectorWithTitle(
          title: 'Hymnes',
          hymns: morning.hymn!,
        )
      else
        const Center(child: Text('Aucune hymne disponible')),
    ];

    // Add psalm views dynamically
    if (morning.psalmody != null) {
      for (int i = 0; i < psalmCount; i++) {
        final psalmEntry = morning.psalmody![i];
        final String? psalmKey = psalmEntry.psalm;
        final List<String>? antiphons = psalmEntry.antiphon;

        tabViews.add(
          PsalmWidget(
            psalmKey: psalmKey,
            psalms: psalms,
            antiphon1:
                antiphons != null && antiphons.isNotEmpty ? antiphons[0] : null,
            antiphon2:
                antiphons != null && antiphons.length > 1 ? antiphons[1] : null,
          ),
        );
      }
    }

    // Add remaining views
    tabViews.addAll([
      // Reading Tab
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScriptureWidget(
            title: 'Parole de Dieu',
            reference: morning.reading?.biblicalReference,
            content: morning.reading?.content,
          ),
          SizedBox(height: spaceBetweenElements),
          SizedBox(height: spaceBetweenElements),
          Text(
            'Répons',
            style: psalmTitleStyle,
          ),
          if (morning.responsory != null)
            Html(data: correctAelfHTML(morning.responsory!))
          else
            const Text('Aucun répons disponible'),
          SizedBox(height: spaceBetweenElements),
        ],
      ),

      // Canticle Tab
      if (morning.evangelicAntiphon?.common != null)
        CanticleWidget(
          canticleType: 'benedictus',
          antiphon1: morning.evangelicAntiphon!.common!,
        )
      else
        const Center(child: Text('Aucune antienne disponible')),

      // Oration Tab
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Handle oration as a list
          if (morning.oration != null && morning.oration!.isNotEmpty)
            ...morning.oration!.map((orationText) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(orationText, style: psalmContentStyle),
                ))
          else
            const Text('Aucune oraison disponible'),
          SizedBox(height: spaceBetweenElements),
          SizedBox(height: spaceBetweenElements),
          Text(
            'Bénédiction',
            style: psalmTitleStyle,
          ),
          if (fixedTexts['morningConclusion'] != null)
            Html(data: correctAelfHTML(fixedTexts['morningConclusion']!))
          else
            const Text(
                'Que le Seigneur nous bénisse, qu\'il nous garde de tout mal et nous conduise à la vie éternelle. Amen.'),
        ],
      ),
    ]);

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(
              children: tabViews,
            ),
          ),
        ],
      ),
    );
  }
}
