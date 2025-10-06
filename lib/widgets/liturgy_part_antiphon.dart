import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

class LiturgyPartAntiphon extends StatelessWidget {
  final String? content;

  const LiturgyPartAntiphon(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Row(children: [
          Expanded(
            child: Row(
              children: [
                verseIdPlaceholder(),
                Expanded(
                  child: Html(
                    data: content,
                    style: {
                      "html": Style.fromTextStyle(
                        TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 14 * currentZoom.value! / 100,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color),
                      ),
                      ".red-text": Style.fromTextStyle(TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 14 * currentZoom.value! / 100)),
                      "body": Style(
                          margin: Margins.zero, padding: HtmlPaddings.zero),
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10, left: 0, right: 15),
                )
              ],
            ),
          ),
        ]),
      );
    }
  }
}
