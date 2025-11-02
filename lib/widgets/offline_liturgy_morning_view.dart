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
    final String psalm1Title = morning.morningPsalm1 ?? "";
    final String psalm2Title = morning.morningPsalm2 ?? "";
    final String psalm3Title = morning.morningPsalm3 ?? "";
    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          if (psalm2Title != "") ...[
            TabBar(
              isScrollable: true,
              tabs: [
                const Tab(text: 'Introduction'),
                const Tab(text: 'Hymnes'),
                Tab(text: psalms[psalm1Title]!.getTitle),
                Tab(text: psalms[psalm2Title]!.getTitle),
                Tab(text: psalms[psalm3Title]!.getTitle),
                const Tab(text: 'Lecture'),
                const Tab(text: 'Cantique de Syméon'),
                const Tab(text: 'Oraison'),
                const Tab(text: 'Hymne mariale'),
              ],
            )
          ] else ...[
            TabBar(
              isScrollable: true,
              tabs: [
                const Tab(text: 'Introduction'),
                const Tab(text: 'Hymnes'),
                Tab(text: psalms[psalm1Title]!.getTitle),
                const Tab(text: 'Lecture'),
                const Tab(text: 'Cantique de Syméon'),
                const Tab(text: 'Oraison'),
                const Tab(text: 'Hymne mariale'),
              ],
            )
          ],
          Expanded(
            child: TabBarView(
              children: [
                // Introduction Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Html(
                        data:
                            correctAelfHTML(fixedTexts['officeIntroduction']!)),
                    SizedBox(height: spaceBetweenElements),
                    Text(
                        'On peut commencer par une révision de la journée, ou par un acte pénitentiel dans la célébration commune',
                        style: rubricStyle),
                  ],
                ),
                // Hymns Tab
                HymnSelectorWithTitle(
                  title: 'Hymnes',
                  hymns: morning.morningHymn!,
                ),

                // Psalm 1 Tab
                PsalmWidget(
                  psalmKey: morning.morningPsalm1,
                  psalms: psalms,
                  antiphon1: morning.morningPsalm1Antiphon,
                  antiphon2: morning.morningPsalm1Antiphon2,
                ),

                // Psalm 2 Tab
                if (morning.morningPsalm2 != "") ...[
                  PsalmWidget(
                    psalmKey: morning.morningPsalm2,
                    psalms: psalms,
                    antiphon1: morning.morningPsalm2Antiphon,
                    antiphon2: morning.morningPsalm2Antiphon2,
                  ),
                ],
                // Reading Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ScriptureWidget(
                      title: 'Parole de Dieu',
                      reference: morning.morningReadingRef,
                      content: morning.morningReading,
                    ),
                    SizedBox(height: spaceBetweenElements),
                    SizedBox(height: spaceBetweenElements),
                    Text(
                      'Répons',
                      style: psalmTitleStyle,
                    ),
                    Html(data: correctAelfHTML(morning.morningResponsory!)),
                    SizedBox(height: spaceBetweenElements),
                  ],
                ),

                // Canticle Tab
                CanticleWidget(
                  canticleType: 'benedictus',
                  antiphon1: morning.morningEvangelicAntiphon!,
                ),

                // Oration Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('${morning.morningOration}', style: psalmContentStyle),
                    SizedBox(height: spaceBetweenElements),
                    SizedBox(height: spaceBetweenElements),
                    Text(
                      'Bénédiction',
                      style: psalmTitleStyle,
                    ),
                    Html(
                        data:
                            correctAelfHTML(fixedTexts['morningConclusion']!)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
