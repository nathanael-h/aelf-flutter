import 'dart:convert';

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
      required this.keys, 
      required this.reference})
      : super(key: key);

  final List<Verse> verses;
  final List<String> keywords;
  final List<GlobalKey> keys;
  final String reference;

  @override
  State<BuildPage> createState() => _BuildPageState();
}

class BibleVerseId extends StatelessWidget {
  // Parameters
  final String id;
  final double fontSize;

  // Internals
  static const double verseIdFontSizeFactor = 10.0 / 16.0;

  // Constructor
  const BibleVerseId({required this.id, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    var verseIdStyle = TextStyle(
      color: Theme.of(context).colorScheme.secondary,
      fontSize: this.fontSize * verseIdFontSizeFactor,
      height: 1.0 / verseIdFontSizeFactor,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: SizedBox(
        child: SelectionContainer.disabled(
          child: Text(
            this.id,
            textAlign: TextAlign.right,
            style: verseIdStyle,
          ),
        ),
        width: fontSize,
      ),
    );
  }
}

class BibleVerseText extends StatelessWidget {
  // Parameters
  final String text;
  final double fontSize;
  final bool highlight;

  // Internals
  static const double lineHeight = 1.2;
  static const Color highlightColor = Color.fromARGB(131, 223, 118, 118); // FIXME: move to theme

  // Constructor
  const BibleVerseText({required this.text, required this.fontSize, required this.highlight});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = this.highlight? highlightColor : Colors.transparent;

    var textStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyMedium!.color,
      fontSize: this.fontSize,
      height: lineHeight,
      backgroundColor: backgroundColor,
    );

    return Expanded(child: Text(this.text+" ", style: textStyle));
  }
}

class BibleVerse extends StatelessWidget {
  // Parameters
  final String id;
  final String text;
  final double fontSize;
  final bool highlight;

  // Internals
  static const double lineHeight = 1.2;
  static const double bottomMarginFactor = 3.0;

  // Constructor
  const BibleVerse({
    Key? key,
    required this.id,
    required this.text,
    required this.fontSize,
    required this.highlight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          // Verse number, non selectable
          BibleVerseId(id: this.id, fontSize: this.fontSize),

          // Verse text, selectable
          BibleVerseText(text: this.text, fontSize: this.fontSize, highlight: this.highlight),
        ],

        // Align content (verse id & verse text) to the top
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),

      // Mark verse delimitation
      margin: EdgeInsets.only(
        bottom: this.fontSize / bottomMarginFactor,
      ),
    );
  }

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
          var rows = <Widget>[];
          var fontSize = 16.0 * currentZoom.value! / 100;
          var matchId = 0;

          for (Verse v in widget.verses) {
            bool isMatch = this._isSearchMatch(v.text ?? "") || this._isReferenceMatch(v.chapter ?? "", v.verse ?? "");

            rows.add(
              BibleVerse(
                key: isMatch?widget.keys[matchId++]:null,
                id: v.verse ?? "",
                text: v.text ?? "",
                fontSize: fontSize,
                highlight: isMatch,
              )
            );
          }

          return Container(
              padding: EdgeInsets.fromLTRB(5, 10, 20, 25),
              child: SelectionArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: rows,
                ),
              )
            );
        },
      ),
    );
  }

  bool _isReferenceMatch(String chapter, String verse_number) {
    // if chapter is in range and 
    // if verse is in range
    // return true else
    print("reference = " + widget.reference);
    if (widget.reference =="") {return false;}
    print((jsonDecode(widget.reference)[0]["chapter_start"]).toString());
    var jsonReference = jsonDecode(widget.reference);
    for (Map map in jsonReference) {
      print("Map = $map");
      if (
        map["chapter_start"] == int.parse(chapter) 
        || map["chapter_end"] == int.parse(chapter) 
        || (map["chapter_start"] < int.parse(chapter) && int.parse(chapter) < map["chapter_end"])
        || (
          (map["chapter_start"].toString().compareTo(chapter) < 0) && (map["chapter_end"].toString().compareTo(chapter) > 0)
        )
        // Here I might switch isong string.compareTo(otherString)
      ) {
        return true;
      }
    }
    return false;
  }

  bool _isSearchMatch(String text) {
    text = cleanString(text);

    for (String keyword in widget.keywords) {
      if (shouldIgnore(keyword)) {
        continue;
      }

      if (text.contains(cleanString(keyword))) {
        return true;
      }
    }

    return false;
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
