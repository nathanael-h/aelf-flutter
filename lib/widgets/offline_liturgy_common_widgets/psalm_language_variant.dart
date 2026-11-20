import 'package:flutter/material.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';

/// The language a psalm or Old/New Testament canticle (not an evangelic
/// canticle — see `CanticleLanguage`) ends up displayed in. Resolved once
/// per text via [resolvePsalmLanguage] and then used for its content, its
/// font and its text direction alike, so the three can never disagree.
enum PsalmLanguage { french, hebrew, greek }

/// The language [psalm] is actually shown in when the shared "original
/// language" preference is [useOriginalLanguage]: off always means French;
/// on means this specific text's own original language — Hebrew for a
/// psalm or proto-canonical OT canticle, Greek for an NT canticle,
/// whichever it has (never both) — falling back to French only when
/// neither variant exists for it yet. Each psalm/canticle resolves its own
/// language independently, so one text's lack of a Hebrew variant never
/// leaks a stale Hebrew font/direction onto the next text, which only has
/// Greek (or vice versa).
PsalmLanguage resolvePsalmLanguage(Psalm psalm, bool useOriginalLanguage) {
  if (!useOriginalLanguage) return PsalmLanguage.french;
  if (psalm.hebrew != null) return PsalmLanguage.hebrew;
  if (psalm.greek != null) return PsalmLanguage.greek;
  return PsalmLanguage.french;
}

/// The psalm content to actually display for [language], as resolved by
/// [resolvePsalmLanguage].
Psalm displayPsalmFor(Psalm psalm, PsalmLanguage language) {
  switch (language) {
    case PsalmLanguage.hebrew:
      return psalm.hebrew ?? psalm;
    case PsalmLanguage.greek:
      return psalm.greek ?? psalm;
    case PsalmLanguage.french:
      return psalm;
  }
}

/// Hebrew and Greek need their own font (Hebrew also needs right-to-left
/// layout — see [textDirectionFor]); French/Latin psalms use the parser's
/// defaults.
TextStyle? verseStyleFor(PsalmLanguage language, double zoom) {
  final String? fontFamily = switch (language) {
    PsalmLanguage.hebrew => 'EzraSIL',
    PsalmLanguage.greek => 'Alegreya',
    PsalmLanguage.french => null,
  };
  if (fontFamily == null) return null;
  // Ezra SIL reads a touch large next to the other languages at the same
  // nominal size; two points smaller matches better. Its niqqud/te'amim
  // also need a bit more breathing room between lines than the default.
  final fontSize = language == PsalmLanguage.hebrew
      ? PsalmConfig.textSize - 2
      : PsalmConfig.textSize;
  final lineHeight = language == PsalmLanguage.hebrew
      ? PsalmConfig.lineSpacing + 0.3
      : PsalmConfig.lineSpacing;
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize * zoom / 100,
    height: lineHeight,
  );
}

/// Hebrew reads right-to-left; French and Greek don't.
TextDirection? textDirectionFor(PsalmLanguage language) =>
    language == PsalmLanguage.hebrew ? TextDirection.rtl : null;
