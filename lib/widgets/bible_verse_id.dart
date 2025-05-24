import 'package:flutter/material.dart';

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
        width: fontSize,
      ),
    );
  }
}
