import 'package:aelf_flutter/utils/bibleDbProvider.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

/// [BibleTextProvider] backed by the app's Bible database (assets/bible.db),
/// so that offline offices can store biblical readings by reference only.
///
/// Verses are read in row order (not by numeric verse), which keeps the
/// lettered sub-verses ('1a', '17k'...) right after their verse. Rows without
/// a verse number (speaker labels, headings) keep an empty label.
class AppBibleTextProvider implements BibleTextProvider {
  AppBibleTextProvider._();

  /// Shared instance, reading each chapter only once.
  static final BibleTextProvider instance =
      CachedBibleTextProvider(AppBibleTextProvider._());

  @override
  Future<List<BibleVerse>?> chapter(String book, String chapter) async {
    final db = BibleDbSqfProvider.instance.db;
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
