import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/bible_language.dart';
import 'package:aelf_flutter/utils/bible_text_provider.dart';

// Module-level: survives navigating away and back, shared by every
// BibleTextVariant instance (Office of Readings, Mass reading/psalm/Gospel).
final _bibleVersesCache = <String, Future<List<BibleVerse>?>>{};

/// [reference]'s verses in [language], resolved via the package's
/// [bibleVerses], cached, and never throwing: [bibleVerses] itself can
/// raise a [FormatException] on a malformed or unresolvable reference, and
/// only the package's own private helper catches that for [bibleText] —
/// this app has no access to it, so the catch happens here instead.
Future<List<BibleVerse>?> cachedBibleVerses(
        String reference, BibleLanguage language) =>
    _bibleVersesCache['$reference#${language.name}'] ??= bibleVerses(
            reference, AppBibleTextProvider.forLanguage(language))
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
