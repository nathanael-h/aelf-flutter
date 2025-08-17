import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// This widget is used when no verse ID is expected, to shift the following
// widget(s) and to have it aligned with the content of verses.
class verseIdPlaceholder extends StatelessWidget {
  const verseIdPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(builder: (context, currentZoom, child) {
      double verseIdPlaceholderWidth =
          5 + 5 + (verseFontSize * currentZoom.value! / 100);

      return Container(width: verseIdPlaceholderWidth);
    });
  }
}
