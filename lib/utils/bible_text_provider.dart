import 'package:aelf_flutter/utils/bibleDbProvider.dart';
import 'package:aelf_flutter/utils/bible_language.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

/// [BibleTextProvider] backed by one of the app's Bible databases
/// (assets/bible.db, bible_grc.db or bible_heb.db), so that offline offices
/// and the Mass can store biblical readings by reference only.
///
/// Verses are read in row order (not by numeric verse), which keeps the
/// lettered sub-verses ('1a', '17k'...) right after their verse. Rows without
/// a verse number (speaker labels, headings) keep an empty label.
class AppBibleTextProvider implements BibleTextProvider {
  final BibleDbSqfProvider _dbProvider;

  AppBibleTextProvider._(this._dbProvider);

  /// Shared instance reading the French database — kept for the many
  /// existing call sites that always meant French (office hydration, which
  /// only ever resolves the French content up front; Greek/Hebrew are
  /// resolved on demand, at display time — see [forLanguage]).
  static final BibleTextProvider instance =
      CachedBibleTextProvider(AppBibleTextProvider._(BibleDbSqfProvider.french));

  static final BibleTextProvider _greek =
      CachedBibleTextProvider(AppBibleTextProvider._(BibleDbSqfProvider.greek));
  static final BibleTextProvider _hebrew = CachedBibleTextProvider(
      AppBibleTextProvider._(BibleDbSqfProvider.hebrew));

  static BibleTextProvider forLanguage(BibleLanguage language) =>
      switch (language) {
        BibleLanguage.french => instance,
        BibleLanguage.greek => _greek,
        BibleLanguage.hebrew => _hebrew,
      };

  @override
  Future<List<BibleVerse>?> chapter(String book, String chapter) async {
    await _dbProvider.ensureDatabase();
    final db = _dbProvider.db;
    if (db == null) return null;
    final rows = await db.rawQuery(
        'SELECT verse, text FROM verses WHERE book = ? AND chapter = ? '
        'ORDER BY rowid',
        [book, chapter]);
    if (rows.isEmpty) return null;
    return [
      for (final r in rows)
        BibleVerse(r['verse']?.toString() ?? '', (r['text'] as String?) ?? ''),
    ];
  }
}
