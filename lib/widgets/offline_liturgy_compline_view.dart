import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/assets/libraries/hymns_library.dart';
import '../app_screens/liturgy_formatter.dart';

class complineView extends StatelessWidget {
  const complineView({
    Key? key,
    required this.compline,
  }) : super(key: key);

  final Compline compline;

  final TextStyle psalmTitleStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.red,
    fontStyle: FontStyle.normal,
  );
  final TextStyle psalmSubtitleStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.normal,
  );
  final TextStyle psalmCommentaryStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.italic,
  );
  final TextStyle psalmAntiphonTitleStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.red,
    fontStyle: FontStyle.italic,
  );
  final TextStyle psalmAntiphonStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
  );
  final TextStyle psalmContentStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
  );
  final double spaceBetweenElements = 12;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          if (compline.complinePsalm2 != "") ...[
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Commentaire'),
                Tab(text: 'Hymnes'),
                Tab(text: 'Psalm 1'),
                Tab(text: 'Psalm 2'),
                Tab(text: 'Lecture'),
                Tab(text: 'Cantique de Syméon'),
                Tab(text: 'Oraison'),
                Tab(text: 'Hymne mariale'),
              ],
            )
          ] else ...[
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Commentaire'),
                Tab(text: 'Hymnes'),
                Tab(text: 'Psalm 1'),
                Tab(text: 'Lecture'),
                Tab(text: 'Cantique de Syméon'),
                Tab(text: 'Oraison'),
                Tab(text: 'Hymne mariale'),
              ],
            )
          ],
          Expanded(
            child: TabBarView(
              children: [
                // Commentary Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Commentary: ${compline.complineCommentary ?? "-"}'),
                    Text(
                        'Celebration Type: ${compline.celebrationType ?? "-"}'),
                  ],
                ),
                // Hymns Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (compline.complineHymns != null &&
                        compline.complineHymns!.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final hymns = compline.complineHymns!;
                          final TabController tabController = TabController(
                            length: hymns.length,
                            vsync: Scaffold.of(context),
                          );
                          return Column(
                            children: [
                              TabBar.secondary(
                                controller: tabController,
                                tabs: [
                                  for (int i = 0; i < hymns.length; i++)
                                    Tab(text: 'Hymn ${i + 1}'),
                                ],
                              ),
                              SizedBox(
                                height: 200,
                                child: TabBarView(
                                  controller: tabController,
                                  children: [
                                    for (final hymn in hymns)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(hymn),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    else
                      Text('No Hymns'),
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
                    Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Antienne 1 : ',
                                style: psalmAntiphonTitleStyle,
                              ),
                              TextSpan(
                                text: '${compline.complinePsalm1Antiphon}',
                                style: psalmAntiphonStyle,
                              ),
                            ],
                          ),
                        ),
                        if (compline.complinePsalm1Antiphon2 != "")
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Antienne 2 : ',
                                  style: psalmAntiphonTitleStyle,
                                ),
                                TextSpan(
                                  text: '${compline.complinePsalm1Antiphon2}',
                                  style: psalmAntiphonStyle,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Html(
                        data: correctAelfHTML(
                            psalms[compline.complinePsalm1]!.getContent)),
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
                      Column(
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Antienne 1 : ',
                                  style: psalmAntiphonTitleStyle,
                                ),
                                TextSpan(
                                  text: '${compline.complinePsalm2Antiphon}',
                                  style: psalmAntiphonStyle,
                                ),
                              ],
                            ),
                          ),
                          if (compline.complinePsalm2Antiphon2 != "")
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Antienne 2 : ',
                                    style: psalmAntiphonTitleStyle,
                                  ),
                                  TextSpan(
                                    text: '${compline.complinePsalm2Antiphon2}',
                                    style: psalmAntiphonStyle,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Html(
                          data: correctAelfHTML(
                              psalms[compline.complinePsalm2]!.getContent)),
                    ],
                  )
                ],
                // Reading Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Parole de Dieu : ${compline.complineReadingRef}',
                        style: psalmTitleStyle),
                    SizedBox(height: spaceBetweenElements),
                    Text('${compline.complineReading}',
                        style: psalmContentStyle),
                    SizedBox(height: spaceBetweenElements),
                    Html(data: correctAelfHTML(compline.complineResponsory!)),
                    SizedBox(height: spaceBetweenElements),
                  ],
                ),
                ListView(padding: const EdgeInsets.all(16), children: [
                  Text('Cantique de Syméon : NT3', style: psalmTitleStyle),
                  SizedBox(height: spaceBetweenElements),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Antienne : ',
                          style: psalmAntiphonTitleStyle,
                        ),
                        TextSpan(
                          text: '${compline.complineEvangelicAntiphon}',
                          style: psalmAntiphonStyle,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spaceBetweenElements),
                  Html(data: correctAelfHTML(psalms['NT_3']!.getContent)),
                ]),

                // Oration Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('${compline.complineOration?.join("\n")}',
                        style: psalmContentStyle),
                  ],
                ),

                // Marial Hymn Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (compline.marialHymnRef != null &&
                        compline.marialHymnRef!.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final marialHymns = compline.marialHymnRef!;
                          final TabController tabController = TabController(
                              length: marialHymns.length,
                              vsync: Scaffold.of(context));
                          return Column(
                            children: [
                              TabBar.secondary(
                                controller: tabController,
                                tabs: [
                                  for (int i = 0; i < marialHymns.length; i++)
                                    Tab(text: 'Hymn ${i + 1}'),
                                ],
                              ),
                              SizedBox(
                                height: 200,
                                child: TabBarView(
                                  controller: tabController,
                                  children: [
                                    for (final hymn in marialHymns)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(hymn),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    else
                      Text('No Marial Hymns'),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
