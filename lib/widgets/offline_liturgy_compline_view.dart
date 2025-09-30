import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/fixed_texts_library.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'offline_liturgy_hymn_selector.dart';
import '../app_screens/layout_config.dart';
import '../app_screens/liturgy_formatter.dart';
import '../widgets/offline_liturgy_evangelic_canticle_display.dart';
import '../widgets/offline_liturgy_scripture_display.dart';
import '../widgets/offline_liturgy_psalms_display.dart';

class complineView extends StatelessWidget {
  const complineView({
    Key? key,
    required this.compline,
  }) : super(key: key);

  final Compline compline;

  @override
  Widget build(BuildContext context) {
    final String psalm1Title = compline.complinePsalm1 ?? "";
    final String psalm2Title = compline.complinePsalm2 ?? "";
    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          if (psalm2Title != "") ...[
            Container(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                isScrollable: true,
                indicatorColor: Theme.of(context).tabBarTheme.labelColor,
                labelColor: Theme.of(context).tabBarTheme.labelColor,
                unselectedLabelColor:
                    Theme.of(context).tabBarTheme.unselectedLabelColor,
                tabs: [
                  const Tab(text: 'Introduction'),
                  const Tab(text: 'Hymnes'),
                  Tab(text: psalms[psalm1Title]!.getTitle),
                  Tab(text: psalms[psalm2Title]!.getTitle),
                  const Tab(text: 'Lecture'),
                  const Tab(text: 'Cantique de Syméon'),
                  const Tab(text: 'Oraison'),
                  const Tab(text: 'Hymne mariale'),
                ],
              ),
            )
          ] else ...[
            Container(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                isScrollable: true,
                indicatorColor: Theme.of(context).tabBarTheme.labelColor,
                labelColor: Theme.of(context).tabBarTheme.labelColor,
                unselectedLabelColor:
                    Theme.of(context).tabBarTheme.unselectedLabelColor,
                tabs: [
                  const Tab(text: 'Introduction'),
                  const Tab(text: 'Hymnes'),
                  Tab(text: psalms[psalm1Title]!.getTitle),
                  const Tab(text: 'Lecture'),
                  const Tab(text: 'Cantique de Syméon'),
                  const Tab(text: 'Oraison'),
                  const Tab(text: 'Hymne mariale'),
                ],
              ),
            )
          ],
          Expanded(
            child: TabBarView(
              children: [
                // Introduction Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (compline.complineCommentary != null)
                      Text('Commentary: ${compline.complineCommentary}'),
                    if (compline.celebrationType != null)
                      Text(
                          'Celebration Type: ${compline.celebrationType ?? "-"}'),
                    SizedBox(height: spaceBetweenElements),
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
                  hymns: compline.complineHymns!,
                ),

                // Psalm 1 Tab
                PsalmWidget(
                  psalmKey: compline.complinePsalm1,
                  psalms: psalms,
                  antiphon1: compline.complinePsalm1Antiphon,
                  antiphon2: compline.complinePsalm1Antiphon2,
                ),

                // Psalm 2 Tab
                if (compline.complinePsalm2 != "") ...[
                  PsalmWidget(
                    psalmKey: compline.complinePsalm2,
                    psalms: psalms,
                    antiphon1: compline.complinePsalm2Antiphon,
                    antiphon2: compline.complinePsalm2Antiphon2,
                  ),
                ],
                // Reading Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ScriptureWidget(
                      title: 'Parole de Dieu',
                      reference: compline.complineReadingRef,
                      content: compline.complineReading,
                    ),
                    SizedBox(height: spaceBetweenElements),
                    SizedBox(height: spaceBetweenElements),
                    Text(
                      'Répons',
                      style: psalmTitleStyle,
                    ),
                    Html(data: correctAelfHTML(compline.complineResponsory!)),
                    SizedBox(height: spaceBetweenElements),
                  ],
                ),

                // Canticle Tab
                CanticleWidget(
                  canticleType: 'nunc_dimittis',
                  antiphon1: compline.complineEvangelicAntiphon!,
                ),

                // Oration Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('${compline.complineOration?.join("\n")}',
                        style: psalmContentStyle),
                    SizedBox(height: spaceBetweenElements),
                    SizedBox(height: spaceBetweenElements),
                    Text(
                      'Bénédiction',
                      style: psalmTitleStyle,
                    ),
                    Html(
                        data:
                            correctAelfHTML(fixedTexts['complineConclusion']!)),
                  ],
                ),

                // Marial Hymn Tab
                HymnSelectorWithTitle(
                  title: 'Hymnes mariales',
                  hymns: compline.marialHymnRef!,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
