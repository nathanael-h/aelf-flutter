import 'package:flutter/material.dart';

// Internals
// The verseId fontsize is 0,625 times the verse fontSize
const double verseIdFontSizeFactor = 10.0 / 16.0; //0,625

/// A verse number, right-aligned in a column of fixed width (`fontSize + 5`
/// plus a 5 px gap) so that verse texts line up.
///
/// The number always stays on one line: a number too wide for the column,
/// such as `11.17` in the canticles that span two chapters, is shrunk just
/// enough to fit, instead of wrapping and pushing its verse down. The column
/// keeps the height of an unshrunk number, so a shrunk one stays vertically
/// centred on its line.
class BibleVerseId extends StatelessWidget {
  // Parameters
  final String id;
  final double fontSize;

  // Constructor
  const BibleVerseId({super.key, required this.id, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    var verseIdStyle = TextStyle(
      color: Theme.of(context).colorScheme.secondary,
      fontSize: fontSize * verseIdFontSizeFactor,
      height: 1.0 / verseIdFontSizeFactor,
    );

    // The height of one line of the number, as the Text below lays it out.
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(verseIdStyle.fontSize!) *
            verseIdStyle.height!;

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: SizedBox(
        width: fontSize + 5,
        height: lineHeight,
        child: SelectionContainer.disabled(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              id,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.right,
              style: verseIdStyle,
            ),
          ),
        ),
      ),
    );
  }
}
