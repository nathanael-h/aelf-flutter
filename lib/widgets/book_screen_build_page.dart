import 'package:aelf_flutter/bibleDbHelper.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:after_layout/after_layout.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BuildPage extends StatefulWidget {
  const BuildPage(
      {Key? key,
      required this.verses,
      required this.keywords,
      required this.keys})
      : super(key: key);

  final List<Verse> verses;
  final List<String> keywords;
  final List<GlobalKey> keys;

  @override
  State<BuildPage> createState() => _BuildPageState();
}

class _BuildPageState extends State<BuildPage>
    with AfterLayoutMixin<BuildPage> {
  @override
  void afterFirstLayout(BuildContext context) => scrollToResult();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<CurrentZoom>(
        builder: (context, currentZoom, child) {
          var spans = <InlineSpan>[];

          var lineHeight = 1.2;
          var fontSize = 16.0 * currentZoom.value! / 100;
          var verseIdFontSize = 10.0 * currentZoom.value! / 100;
          var verseIdStyle = TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: verseIdFontSize,
              height: lineHeight);
          var textStyle = TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color,
              fontSize: fontSize,
              height: lineHeight);
          var textStyleHighlight = TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color,
              fontSize: fontSize,
              height: lineHeight,
              backgroundColor: Color.fromARGB(131, 223, 118, 118));
          var verseTextStyle = textStyle;

          int i = 0;
          for (Verse v in widget.verses) {
            // Add the verse number in small and red
            spans.add(
              TextSpan(text: '${v.verse} ', style: verseIdStyle),
            );
              for (String keyword in widget.keywords) {
                if (shouldIgnore(keyword)) {
                  continue;
                }
                if (cleanString(v.text!).contains(cleanString(keyword))) {
                  verseTextStyle = textStyleHighlight;
                  spans.add(WidgetSpan(
                      child: SizedBox(
                    key: widget.keys[i],
                    height: 0,
                    width: 0,
                    child: Container(
                      color: Colors.deepOrange,
                    ),
                  )));
                  i++;
                  break;
                } else {
                  verseTextStyle = textStyle;
                }
              }
              // Add an highlighted verse, because it contains a keyword
              spans.add(TextSpan(
                  text: v.text!.replaceAll('\n', ' '), style: verseTextStyle));
            // Keyword list is empty, add normal verse.
            spans.add(TextSpan(text: '\n', style: textStyle));
          }
          return Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 25),
              child: SelectableText.rich(TextSpan(children: spans)));
        },
      ),
    );
  }

  // https://stackoverflow.com/questions/72304516/how-to-use-focus-on-richtext-in-flutter
  void scrollToResult() {
    try {
      Scrollable.ensureVisible(
        widget.keys[0].currentContext!,
        alignment: 0.2,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      print("scrollToResult error: " + e.toString());
    }
  }
}

cleanString(String string) {
  string = removeDiacritics(string);
  string = string.toLowerCase();
  string = string.replaceAll(RegExp(r'[^\p{L}\p{M} ]+', unicode: true), '');
  return string;
}
