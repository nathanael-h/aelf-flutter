import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

class LiturgyPartIntro extends StatelessWidget {
  final String? content;

  const LiturgyPartIntro(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Row(children: [
          verseIdPlaceholder(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 45),
              child: Html(data: correctAelfHTML(content!), style: {
                "html": Style.fromTextStyle(TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                    fontSize: 14 * currentZoom.value! / 100)),
                ".verse_number": Style.fromTextStyle(TextStyle(
                    height: 1.2,
                    fontSize: 12 * currentZoom.value! / 100,
                    color: Theme.of(context).colorScheme.secondary)),
                ".repons": Style.fromTextStyle(TextStyle(
                    height: 5,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 12 * currentZoom.value! / 100)),
                ".red-text": Style.fromTextStyle(
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
                ".spacer": Style.fromTextStyle(TextStyle(
                    fontSize: 12 * currentZoom.value! / 100,
                    height: 0.3 * currentZoom.value! / 100)),
                "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
              }),
            ),
          ),
        ]),
      );
    }
  }
}
