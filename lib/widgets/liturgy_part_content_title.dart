import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LiturgyPartContentTitle extends StatelessWidget {
  final String? content;

  const LiturgyPartContentTitle(this.content, {super.key});
  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 5),
        child: LiturgyRow(
          builder: (context, zoom) => Html(
            data: content,
            style: {
              "html": Style.fromTextStyle(TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 20 * (zoom ?? 100) / 100)),
              "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
            },
          ),
        ),
      );
    }
  }
}
