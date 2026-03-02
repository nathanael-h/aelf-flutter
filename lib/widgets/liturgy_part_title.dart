import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LiturgyPartTitle extends StatelessWidget {
  final String? content;
  final Widget Function(double zoom)? trailing;

  const LiturgyPartTitle(this.content, {Key? key, this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retour anticipé si pas de contenu
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LiturgyRow(
      hideVerseIdPlaceholder: true,
      builder: (context, zoom) {
        final titleHtml = Html(
          data: content,
          style: {
            "html": Style.fromTextStyle(TextStyle(
              fontSize: 20 * (zoom ?? 100) / 100,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            )),
            "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
          },
        );

        final trailingWidget = trailing != null ? trailing!(zoom ?? 100) : null;
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
