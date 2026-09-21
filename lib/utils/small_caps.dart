import 'package:flutter/material.dart';

/// Ratio of a synthesized small capital's size to a full capital's, measured
/// on the native app at a 34dp font size (24.3dp capitals / 19.3dp small
/// capitals). Requested through a font's `smcp` feature there, but only
/// Android's system font ships an `smcp` table — everywhere else (Linux,
/// iOS, web) the text would silently fall back to plain lower case, so this
/// synthesizes the effect instead: uppercase, at a smaller size.
const double smallCapsRatio = 19.3 / 24.3;

/// Rebuilds [text] as small capitals: lower-case letters become capitals at
/// [ratio] of [style]'s font size, everything else is left as-is.
TextSpan smallCapsSpan(String text, TextStyle style,
    {double ratio = smallCapsRatio}) {
  final TextStyle smallStyle = style.copyWith(
    fontSize: (style.fontSize ?? 14) * ratio,
  );
  final List<TextSpan> spans = <TextSpan>[];
  final StringBuffer run = StringBuffer();
  bool? runIsLowerCase;

  void flushRun() {
    if (run.isEmpty) return;
    final bool isLowerCase = runIsLowerCase!;
    spans.add(TextSpan(
      text: isLowerCase ? run.toString().toUpperCase() : run.toString(),
      style: isLowerCase ? smallStyle : null,
    ));
    run.clear();
  }

  for (final String char in text.split('')) {
    final bool isLowerCase =
        char != char.toUpperCase() && char == char.toLowerCase();
    if (runIsLowerCase != null && isLowerCase != runIsLowerCase) flushRun();
    runIsLowerCase = isLowerCase;
    run.write(char);
  }
  flushRun();

  return TextSpan(style: style, children: spans);
}
