import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/bible_language.dart';
import 'package:aelf_flutter/utils/bible_text_provider.dart';

// Module-level: survives navigating away and back, shared by every
// BibleTextVariant instance (Office of Readings, Mass reading/psalm/Gospel).
final _bibleVersesCache = <String, Future<List<BibleVerse>?>>{};

/// A Mass/Office psalm reference such as "Ps 79 (80), 2ac.3bc, 15-16a,
/// 18-19": the number before the parenthesis is the Vulgate/Septuagint
/// numbering (matching bible.db's own chapters, and what bible_grc.db
/// would use for a Septuagint it doesn't have yet); the parenthesized one
/// is the Hebrew/Masoretic numbering bible_heb.db actually uses. The two
/// name different psalms — confirmed directly: bible.db's chapter 79 is
/// the Vulgate's "Berger d'Israël, écoute" (Hebrew Psalm 80), while
/// bible_heb.db's own chapter 79 is Hebrew's unrelated "O God, the
/// nations have come into your inheritance".
final _dualPsalmNumbering = RegExp(r'^(\S+\s+)(\d+)\s*\((\d+)\)(.*)$');

/// [reference] rewritten to the chapter number [language]'s database
/// actually uses, when it carries a Vulgate/Hebrew dual numbering — a
/// plain reference (no parenthesized alias) is returned unchanged.
String _referenceForLanguage(String reference, BibleLanguage language) {
  final match = _dualPsalmNumbering.firstMatch(reference);
  if (match == null) return reference;
  final chapter = language == BibleLanguage.hebrew
      ? match.group(3)! // the Hebrew/Masoretic number in parentheses
      : match.group(2)!; // Vulgate/Septuagint, before the parenthesis
  return '${match.group(1)}$chapter${match.group(4)}';
}

/// A multi-letter verse locator ("2ac", "3bc": verse 2/3, specific clauses
/// within it) — a finer grain than any database row; collapsed to its
/// plain verse number, citing the whole verse. A single trailing letter
/// ("16a") is left alone: the package's own _slice already falls back to
/// the whole verse for that case.
final _compoundVerseLetters = RegExp(r'(\d+)[a-z]{2,}');

/// Missal psalm citations list their (possibly non-contiguous) verses
/// comma-separated within one chapter, e.g. "80, 2ac.3bc, 15-16a, 18-19" —
/// a different convention from parseBibleReference's own, built for the
/// Office of Readings' citations, which separates same-chapter ranges
/// with '.' and reserves ',' for the chapter prefix alone ("1-15.21-28").
/// Rewritten into that convention (the chapter-separating comma kept,
/// every other comma turned into a dot) and its compound verse locators
/// collapsed, this is a plain reference parseBibleReference already
/// resolves correctly.
String _normalizedVerseList(String reference) {
  final chapterComma = reference.indexOf(',');
  if (chapterComma < 0) return reference;
  final head = reference.substring(0, chapterComma + 1);
  final rest = reference
      .substring(chapterComma + 1)
      .replaceAll(',', '.')
      .replaceAllMapped(_compoundVerseLetters, (m) => m.group(1)!);
  return '$head$rest';
}

/// [reference]'s verses in [language], resolved via the package's
/// [bibleVerses], cached, and never throwing: [bibleVerses] itself can
/// raise a [FormatException] on a malformed or unresolvable reference, and
/// only the package's own private helper catches that for [bibleText] —
/// this app has no access to it, so the catch happens here instead.
Future<List<BibleVerse>?> cachedBibleVerses(
        String reference, BibleLanguage language) =>
    _bibleVersesCache['$reference#${language.name}'] ??= bibleVerses(
            _normalizedVerseList(_referenceForLanguage(reference, language)),
            AppBibleTextProvider.forLanguage(language))
        .catchError((_) => null);

/// The book code at the start of [reference] ('Mt', 'Gn'...), or null if it
/// doesn't resolve to one — used to gate [BibleLanguageButton] (a bare
/// verse locator, such as a Mass psalm's refAbbr "36, 5", has none).
String? referenceBook(String? reference) {
  if (reference == null || reference.isEmpty) return null;
  try {
    return parseBibleReference(reference).first.book;
  } catch (_) {
    return null;
  }
}

/// Resolves the text to actually show for [reference]/[frenchContent]
/// under the shared [LiturgyState.bibleTextLanguage] preference, then hands
/// it to [builder]: when the preference is French, or [reference] is null
/// or empty, or the other language has nothing for [reference] (a
/// chapter/verse missing in that language within an otherwise available
/// book, e.g. a Psalm numbered differently in Hebrew), [builder] gets
/// [frenchContent] with [language] forced back to French — silently, no
/// message, no change to the toggle. Otherwise it gets the resolved verses
/// for the requested language.
///
/// Exactly one of `frenchText`/`verses` is non-null in any call to
/// [builder] (both null only when there is nothing to show at all).
class BibleTextVariant extends StatelessWidget {
  final String? reference;
  final String? frenchContent;
  final Widget Function(BuildContext context, BibleLanguage language,
      String? frenchText, List<BibleVerse>? verses) builder;

  const BibleTextVariant({
    super.key,
    this.reference,
    this.frenchContent,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LiturgyState>().bibleTextLanguage;
    final reference = this.reference;
    if (language == BibleLanguage.french ||
        reference == null ||
        reference.isEmpty) {
      return builder(context, BibleLanguage.french, frenchContent, null);
    }
    return FutureBuilder<List<BibleVerse>?>(
      future: cachedBibleVerses(reference, language),
      builder: (context, snapshot) {
        final verses = snapshot.data;
        if (verses != null) {
          return builder(context, language, frenchContent, verses);
        }
        return builder(context, BibleLanguage.french, frenchContent, null);
      },
    );
  }
}
