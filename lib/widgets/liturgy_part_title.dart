import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LiturgyPartTitle extends StatelessWidget {
  final String? content;

  const LiturgyPartTitle(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retour anticipé si pas de contenu
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return LiturgyRow(
      builder: (context, zoom) => Html(
        data: content,
        style: {
          "html": Style.fromTextStyle(TextStyle(
            fontSize: 20 * (zoom ?? 100) / 100,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.secondary,
          )),
          "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
        },
      ),
    );
  }
}
