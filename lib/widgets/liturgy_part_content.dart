import 'package:aelf_flutter/utils/text_management.dart';
import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/bible_verse_id.dart';
import 'package:aelf_flutter/widgets/liturgy_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

class LiturgyPartContent extends StatelessWidget {
  final String? content;
  static const double bottomMarginFactor = 3.0;

  const LiturgyPartContent(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) {
          final zoomValue = currentZoom.value ?? 100.0;
          return Row(children: [
            Expanded(
              child: Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10, left: 0, right: 15),
                  child: Column(
                    children: extractVerses(correctAelfHTML(content!))
                        .entries
                        .map((entry) {
                      return Container(
                        child: Row(
                          children: [
                            BibleVerseId(
                                id: entry.key,
                                fontSize: verseFontSize * zoomValue / 100),
                            // BibleVerseId width is 5+ 5 + (16 * currentZoom)
                            // 5 for padding on the right
                            // 5 to give more space
                            // 16 is the verseFontSize, definied below
                            Expanded(
                              child: Html(
                                data: entry.value,
                                style: {
                                  "html": Style.fromTextStyle(TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color,
                                    fontSize: 16 * zoomValue / 100,
                                  )),
                                  ".verse_number": Style.fromTextStyle(
                                      TextStyle(
                                          height: 1.2,
                                          fontSize: verseFontSize *
                                              verseIdFontSizeFactor *
                                              zoomValue /
                                              100,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary)),
                                  ".repons": Style.fromTextStyle(TextStyle(
                                      height: 5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontSize: 14 * zoomValue / 100)),
                                  ".red-text": Style.fromTextStyle(TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontSize: 14 * zoomValue / 100)),
                                  "body": Style(
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero),
                                },
                              ),
                            ),
                          ],
                          // Align content (verse id & verse text) to the top
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                        ),
                      );
                    }).toList(),
                  )),
            ),
          ]);
        },
      );
    }
  }
}
