import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/assets/libraries/fixed_texts_library.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import '../widgets/liturgy_hymn_selector.dart';
import '../app_screens/layout_config.dart';
import '../app_screens/liturgy_formatter.dart';
import '../widgets/offline_liturgy_antiphon_view.dart';

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
            TabBar(
              isScrollable: true,
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
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Hymnes :',
                      style: psalmTitleStyle,
                    ),
                    SizedBox(height: 16),
                    Container(
                      child: HymnSelector(
                        hymns: compline.complineHymns!,
                      ),
                    ),
                  ],
                ),

                // Psalm 1 Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${psalms[compline.complinePsalm1]?.getTitle}',
                      style: psalmTitleStyle,
                    ),
                    SizedBox(height: spaceBetweenElements),
                    if (psalms[compline.complinePsalm1]?.getSubtitle != null)
                      Text('${psalms[compline.complinePsalm1]?.getSubtitle}',
                          style: psalmSubtitleStyle),
                    if (psalms[compline.complinePsalm1]?.getCommentary !=
                        null) ...[
                      Text('${psalms[compline.complinePsalm1]?.getCommentary}',
                          style: psalmCommentaryStyle),
                      SizedBox(height: spaceBetweenElements)
                    ],
                    AntiphonWidget(
                      // Using AntiphonWidget to display antiphons
                      antiphon1: compline.complinePsalm1Antiphon!,
                      antiphon2: compline.complinePsalm1Antiphon2,
                    ),
                    Html(
                        data: correctAelfHTML(
                            psalms[compline.complinePsalm1]!.getContent)),
                    AntiphonWidget(
                      // Using AntiphonWidget to display antiphons
                      antiphon1: compline.complinePsalm1Antiphon!,
                      antiphon2: compline.complinePsalm1Antiphon2,
                    ),
                  ],
                ),

                // Psalm 2 Tab
                if (compline.complinePsalm2 != "") ...[
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        '${psalms[compline.complinePsalm2]?.getTitle}',
                        style: psalmTitleStyle,
                      ),
                      SizedBox(height: spaceBetweenElements),
                      if (psalms[compline.complinePsalm2]?.getSubtitle != null)
                        Text('${psalms[compline.complinePsalm2]?.getSubtitle}',
                            style: psalmSubtitleStyle),
                      if (psalms[compline.complinePsalm2]?.getCommentary !=
                          null) ...[
                        Text(
                            '${psalms[compline.complinePsalm2]?.getCommentary}',
                            style: psalmCommentaryStyle),
                        SizedBox(height: spaceBetweenElements)
                      ],
                      AntiphonWidget(
                        // Using AntiphonWidget to display antiphons
                        antiphon1: compline.complinePsalm2Antiphon!,
                        antiphon2: compline.complinePsalm2Antiphon2,
                      ),
                      Html(
                          data: correctAelfHTML(
                              psalms[compline.complinePsalm2]!.getContent)),
                      AntiphonWidget(
                        // Using AntiphonWidget to display antiphons
                        antiphon1: compline.complinePsalm2Antiphon!,
                        antiphon2: compline.complinePsalm2Antiphon2,
                      ),
                    ],
                  )
                ],
                // Reading Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Text(
                          'Parole de Dieu',
                          style: psalmTitleStyle,
                        ),
                        Expanded(
                          child: Text(
                            '${compline.complineReadingRef}',
                            style: biblicalReferenceStyle,
                            textAlign: TextAlign.right, // Alignement à droite
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spaceBetweenElements),
                    Text('${compline.complineReading}',
                        style: psalmContentStyle),
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
                ListView(padding: const EdgeInsets.all(16), children: [
                  Row(
                    children: [
                      Text(
                        'Cantique de Syméon',
                        style: psalmTitleStyle,
                      ),
                      Expanded(
                        child: Text(
                          'NT3',
                          style: biblicalReferenceStyle,
                          textAlign: TextAlign.right, // Alignement à droite
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spaceBetweenElements),
                  AntiphonWidget(
                    // Using AntiphonWidget to display antiphons
                    antiphon1: compline.complineEvangelicAntiphon!,
                    antiphon2: null,
                  ),
                  SizedBox(height: spaceBetweenElements),
                  Html(data: correctAelfHTML(psalms['NT_3']!.getContent)),
                  AntiphonWidget(
                    // Using AntiphonWidget to display antiphons
                    antiphon1: compline.complineEvangelicAntiphon!,
                    antiphon2: null,
                  ),
                ]),

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
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Hymnes mariales',
                      style: psalmTitleStyle,
                    ),
                    SizedBox(height: 16),
                    Container(
                      child: HymnSelector(
                        hymns: compline.marialHymnRef!,
                      ),
                    ),
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
