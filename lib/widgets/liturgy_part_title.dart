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
    if (content == "" || content == null) {
      return Row();
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Row(children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 25, bottom: 5),
              child: Row(
                children: [
                  verseIdPlaceholder(),
                  Expanded(
                    child: Html(
                      data: content,
                      style: {
                        "html": Style.fromTextStyle(
                          TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                              fontWeight: FontWeight.w900,
                              fontSize: 20 * currentZoom.value! / 100),
                        ),
                        "body": Style(
                            margin: Margins.zero, padding: HtmlPaddings.zero),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      );
    }
  }
}
