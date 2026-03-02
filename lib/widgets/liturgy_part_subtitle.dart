import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LiturgyPartSubtitle extends StatelessWidget {
  final String? content;
  final Widget Function(double zoom)? trailing;

  const LiturgyPartSubtitle(this.content, {Key? key, this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return LiturgyRow(
        hideVerseIdPlaceholder: true,
        builder: (context, zoom) {
          final htmlWidget = Html(
            data: content,
            style: {
              "html": Style.fromTextStyle(TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16 * (zoom ?? 100) / 100,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium!.color)),
              ".red-text": Style.fromTextStyle(TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14 * (zoom ?? 100) / 100)),
              "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
            },
          );

          final trailingWidget =
              trailing != null ? trailing!(zoom ?? 100) : null;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (trailingWidget != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(child: htmlWidget),
                    trailingWidget,
                  ],
                )
              else
                htmlWidget,
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 0, right: 15),
              ),
            ],
          );
        },
      );
    }
  }
}
