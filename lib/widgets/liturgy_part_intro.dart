import 'package:aelf_flutter/utils/text_management.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LiturgyPartIntro extends StatelessWidget {
  final String? content;

  const LiturgyPartIntro(this.content, {super.key});

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Row();
    } else {
      return LiturgyRow(
        padding: const EdgeInsets.only(left: 45),
        builder: (context, zoom) => Html(
          data: correctAelfHTML(content!),
          style: {
            "html": Style.fromTextStyle(TextStyle(
                color: Theme.of(context).textTheme.bodyMedium!.color,
                fontSize: 14 * (zoom ?? 100) / 100)),
            ".verse_number": Style.fromTextStyle(TextStyle(
                height: 1.2,
                fontSize: 12 * (zoom ?? 100) / 100,
                color: Theme.of(context).colorScheme.secondary)),
            ".repons": Style.fromTextStyle(TextStyle(
                height: 5,
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 12 * (zoom ?? 100) / 100)),
            ".red-text": Style.fromTextStyle(
                TextStyle(color: Theme.of(context).colorScheme.secondary)),
            ".spacer": Style.fromTextStyle(TextStyle(
                fontSize: 12 * (zoom ?? 100) / 100,
                height: 0.3 * (zoom ?? 100) / 100)),
            "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
          },
        ),
      );
    }
  }
}
