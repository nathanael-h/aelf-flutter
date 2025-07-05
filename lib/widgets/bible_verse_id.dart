import 'package:flutter/material.dart';

// Internals
// The verseId fontsize is 0,625 times the verse fontSize
const double verseIdFontSizeFactor = 10.0 / 16.0; //0,625

class BibleVerseId extends StatelessWidget {
  // Parameters
  final String id;
  final double fontSize;

  // Constructor
  const BibleVerseId({required this.id, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    var verseIdStyle = TextStyle(
      color: Theme.of(context).colorScheme.secondary,
      fontSize: fontSize * verseIdFontSizeFactor,
      height: 1.0 / verseIdFontSizeFactor,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: SizedBox(
        child: SelectionContainer.disabled(
          child: Text(
            id,
            textAlign: TextAlign.right,
            style: verseIdStyle,
          ),
        ),
        width: fontSize + 1,
      ),
    );
  }
}
