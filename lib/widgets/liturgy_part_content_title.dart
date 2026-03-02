import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LiturgyPartContentTitle extends StatelessWidget {
  final String? content;
  final Widget Function(double zoom)? trailing;

  const LiturgyPartContentTitle(this.content,
      {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: LiturgyRow(
          hideVerseIdPlaceholder: true,
          builder: (context, zoom) {
            final titleHtml = Html(
              data: content,
              style: {
                "html": Style.fromTextStyle(TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 20 * (zoom ?? 100) / 100)),
                "body":
                    Style(margin: Margins.zero, padding: HtmlPaddings.zero),
              },
            );
            final trailingWidget =
                trailing != null ? trailing!(zoom ?? 100) : null;

            if (trailingWidget == null) return titleHtml;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: titleHtml),
                trailingWidget,
              ],
            );
          },
        ),
      );
    }
  }
}
