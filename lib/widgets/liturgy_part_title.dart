import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

class LiturgyPartTitle extends StatelessWidget {
  final String? content;

  const LiturgyPartTitle(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retour anticipé si pas de contenu
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final fontSize = 20 * (currentZoom.value ?? 100) / 100;

        return Row(
          children: [
            verseIdPlaceholder(),
            Html(
              data: content,
              style: {
                "html": Style.fromTextStyle(
                  TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
              },
            ),
          ],
        );
      },
    );
  }
}
