import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiturgyPartRef extends StatelessWidget {
  final String? content;

  LiturgyPartRef(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == "" || content == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: 20),
      );
    } else {
      return Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) => Padding(
            padding: EdgeInsets.only(right: 15, bottom: 20),
            child: Align(
              alignment: Alignment.topRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: context.read<ThemeNotifier>().darkTheme!
                        ? Color.fromARGB(255, 38, 41, 49)
                        : Color.fromARGB(255, 240, 229, 210)),
                onPressed: () => refButtonPressed(content ?? "", context),
                child: Text((content != "" ? "- $content" : ""),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16 * currentZoom.value! / 100,
                        color: Theme.of(context).textTheme.bodyMedium!.color)),
              ),
            )),
      );
    }
  }
}
