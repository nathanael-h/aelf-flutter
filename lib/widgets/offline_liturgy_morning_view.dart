import 'package:aelf_flutter/widgets/liturgy_part_rubric.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/fixed_texts_library.dart';
import 'package:offline_liturgy/classes/morning_class.dart';
import 'offline_liturgy_hymn_selector.dart';
import '../app_screens/layout_config.dart';
import 'package:aelf_flutter/utils/text_management.dart';
import '../widgets/offline_liturgy_evangelic_canticle_display.dart';
import '../widgets/offline_liturgy_scripture_display.dart';
import '../widgets/offline_liturgy_psalms_display.dart';

class morningView extends StatelessWidget {
  const morningView({
    Key? key,
    required this.morning,
  }) : super(key: key);

  final Morning morning;

  @override
  Widget build(BuildContext context) {
    // Get the number of psalms dynamically
    final int psalmCount = morning.getPsalmodyCount();

    // Build tabs list dynamically based on psalm count
    List<Tab> tabs = [
      const Tab(text: 'Introduction'),
      const Tab(text: 'Hymnes'),
    ];

    // Add psalm tabs dynamically
    for (int i = 0; i < psalmCount; i++) {
      final String? psalmKey = morning.getPsalm(i);
      if (psalmKey != null && psalms.containsKey(psalmKey)) {
        tabs.add(Tab(text: psalms[psalmKey]!.getTitle));
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
          Html(data: correctAelfHTML(fixedTexts['officeIntroduction']!)),
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
    for (int i = 0; i < psalmCount; i++) {
      final String? psalmKey = morning.getPsalm(i);
      final List<String>? antiphons = morning.getAntiphonList(i);

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

    // Add remaining views
    tabViews.addAll([
      // Reading Tab
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScriptureWidget(
            title: 'Parole de Dieu',
            reference: morning.readingRef,
            content: morning.reading,
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
      if (morning.evangelicAntiphon != null)
        CanticleWidget(
          canticleType: 'benedictus',
          antiphon1: morning.evangelicAntiphon!,
        )
      else
        const Center(child: Text('Aucune antienne disponible')),

      // Oration Tab
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (morning.oration != null)
            Text('${morning.oration}', style: psalmContentStyle)
          else
            const Text('Aucune oraison disponible'),
          SizedBox(height: spaceBetweenElements),
          SizedBox(height: spaceBetweenElements),
          Text(
            'Bénédiction',
            style: psalmTitleStyle,
          ),
          Html(data: correctAelfHTML(fixedTexts['morningConclusion']!)),
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
