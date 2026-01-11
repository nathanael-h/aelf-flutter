import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LiturgyPartAntiphon extends StatelessWidget {
  final String? content;

  const LiturgyPartAntiphon(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return LiturgyRow(
        builder: (context, zoom) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Html(
              data: content,
              style: {
                "html": Style.fromTextStyle(TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14 * (zoom ?? 100) / 100,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium!.color)),
                ".red-text": Style.fromTextStyle(TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 14 * (zoom ?? 100) / 100)),
                "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
              },
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 0, right: 15),
            ),
          ],
        ),
      );
    }
  }
}
