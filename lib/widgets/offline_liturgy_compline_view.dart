import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/classes/compline_class.dart';

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
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.red,
    fontStyle: FontStyle.italic,
  );
  final TextStyle psalmAntiphonStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
  );

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Commentary'),
              Tab(text: 'Hymns'),
              Tab(text: 'Psalm 1'),
              Tab(text: 'Psalm 2'),
              Tab(text: 'Reading'),
              Tab(text: 'Evangelic Antiphon'),
              Tab(text: 'Oration'),
              Tab(text: 'Marial Hymns'),
            ],
          ),
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
                    if (psalms[compline.complinePsalm1]?.getSubtitle != null)
                      Text(
                          '${psalms[compline.complinePsalm1]?.getSubtitle ?? ""}',
                          style: psalmSubtitleStyle),
                    if (psalms[compline.complinePsalm1]?.getCommentary != null)
                      Text(
                          '${psalms[compline.complinePsalm1]?.getCommentary ?? ""}',
                          style: psalmCommentaryStyle),
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
                        if (compline.complinePsalm1Antiphon2 != null)
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
                    Text(
                        '${psalms[compline.complinePsalm1]?.getBiblicalReference ?? ""}'),
                    Html(
                        data:
                            '${psalms[compline.complinePsalm1]?.getContent ?? "-"}'),
                  ],
                ),

                // Psalm 2 Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                        'Psalm 2 Antiphon: ${compline.complinePsalm2Antiphon ?? "-"}'),
                    Text(
                        'Psalm 2 Antiphon 2: ${compline.complinePsalm2Antiphon2 ?? "-"}'),
                    Text(
                        'Psalm 2 title: ${psalms[compline.complinePsalm2]?.getTitle ?? "-"}'),
                    Text(
                        'Psalm 2 subtitle: ${psalms[compline.complinePsalm2]?.getSubtitle ?? "-"}'),
                    Text(
                        'Psalm 2 commentary: ${psalms[compline.complinePsalm2]?.getCommentary ?? "-"}'),
                    Text(
                        'Psalm 2 biblical reference: ${psalms[compline.complinePsalm2]?.getBiblicalReference ?? "-"}'),
                    Html(
                        data:
                            'Psalm 2: ${psalms[compline.complinePsalm2]?.getContent ?? "-"}'),
                  ],
                ),
                // Reading Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                        'Reading Reference: ${compline.complineReadingRef ?? "-"}'),
                    Text('Reading: ${compline.complineReading ?? "-"}'),
                    Text('Responsory: ${compline.complineResponsory ?? "-"}'),
                    Text(
                        'Evangelic Antiphon: ${compline.complineEvangelicAntiphon ?? "-"}'),
                  ],
                ),
                // Oration Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                        'Oration: ${compline.complineOration?.join("\n") ?? "-"}'),
                  ],
                ),
                // Evangelic Antiphon Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                        'Evangelic Antiphon: ${compline.complineEvangelicAntiphon ?? "-"}'),
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
