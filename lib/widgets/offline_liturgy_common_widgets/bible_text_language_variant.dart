import 'package:flutter/material.dart';
import 'package:aelf_flutter/utils/bible_language.dart';

/// Hebrew and Greek Bible text need their own font (Hebrew also needs
/// right-to-left layout — see [bibleTextDirectionFor]); French uses the
/// caller's own default style. Generic counterpart of
/// `psalm_language_variant.dart`'s `verseStyleFor`, for plain Bible text
/// rather than a [Psalm].
TextStyle? bibleVerseStyleFor(BibleLanguage language, double zoom) {
  final String? fontFamily = switch (language) {
    BibleLanguage.hebrew => 'EzraSIL',
    BibleLanguage.greek => 'Alegreya',
    BibleLanguage.french => null,
  };
  if (fontFamily == null) return null;
  // Ezra SIL reads a touch large next to French at the same nominal size;
  // two points smaller matches better, with extra line spacing for its
  // niqqud/te'amim — same rationale as the psalms' own verseStyleFor.
  final fontSize = language == BibleLanguage.hebrew ? 14.0 : 16.0;
  final lineHeight = language == BibleLanguage.hebrew ? 1.5 : 1.2;
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize * zoom / 100,
    height: lineHeight,
  );
}

/// Hebrew reads right-to-left; French and Greek don't.
TextDirection? bibleTextDirectionFor(BibleLanguage language) =>
    language == BibleLanguage.hebrew ? TextDirection.rtl : null;
