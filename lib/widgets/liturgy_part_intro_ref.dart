import 'package:aelf_flutter/utils/bible_reference_fetcher.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiturgyPartIntroRef extends StatelessWidget {
  final String? content;

  LiturgyPartIntroRef(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: 20),
      );
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Padding(
            padding: EdgeInsets.only(right: 25, bottom: 20),
            child: Align(
              alignment: Alignment.topRight,
              child: ElevatedButton(
                onPressed: () => refButtonPressed(content ?? "", context),
                child: Text((content != "" ? "- $content" : ""),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14 * currentZoom.value! / 100)),
              ),
            )),
      );
    }
  }
}
