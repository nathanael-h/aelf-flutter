import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class BibleDbHelper {
  // define all db parameters
  static final _databaseName = "bible.db";

  // make this a singleton class
  BibleDbHelper._privateConstructor();
  static final BibleDbHelper instance = BibleDbHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, _databaseName);
    //await deleteDatabase(path);
    // Check if the database exists
    var exists = await databaseExists(path);
    if (!exists) {
      // Should happen only the first time you launch your application
      print("Creating new copy from asset");
      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", _databaseName));
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      print("Opening existing database");
    }
    // open the database
    return await openDatabase(path, readOnly: true);
  }

  // Helper methods

  // get chapter
  Future<Chapter> getChapter(String book, String chapter) async {
    Database db = await instance.database;
    dynamic results = await db.rawQuery(
        'SELECT * FROM chapters WHERE book=? AND chapter=? LIMIT 1',
        [book, chapter]);

    if (results.length > 0) {
      return new Chapter.fromMap(results.first);
    }
    return null;
  }

  Future<List<Verse>> getChapterVerses(String book, String chapter) async {
    Database db = await instance.database;
    dynamic results = await db.rawQuery(
        'SELECT * FROM verses WHERE book=? AND chapter=?',
        [book, chapter]);

    List<Verse> output = [];
    for(var db_verse in results) {
      output.add(new Verse.fromMap(db_verse));
    }
    return output;
  }

  // get chapter
  Future<Verse> getVerse(String book, String chapter, String verse) async {
    Database db = await instance.database;
    dynamic results = await db.rawQuery(
        'SELECT * FROM verses WHERE book=? AND chapter=? AND verse=? LIMIT 1',
        [book, chapter, verse]);

    if (results.length > 0) {
      return new Verse.fromMap(results.first);
    }
    return null;
  }

}
/* call examples
import 'package:aelf_flutter/bibleDbHelper.dart';
BibleDbHelper bibleDbHelper = BibleDbHelper.instance;
bibleDbHelper.getChapter("Gn", "1").then((Chapter chapter){
  print(chapter.text);
});
bibleDbHelper.getVerse("Jn", "8", "32").then((Verse verse){
  print(verse.text);
});*/

class Chapter {
  Chapter({
    this.book,
    this.bookId,
    this.chapter,
    this.chapterId,
    this.title,
    this.text,
  });

  factory Chapter.fromMap(Map<String, dynamic> data) => new Chapter(
    book: data["book"],
    bookId: data["book_id"],
    chapter: data["chapter"],
    chapterId: data["chapter_id"],
    title: data["title"],
    text: data["text"],
  );

  String book;
  int bookId;
  String chapter;
  int chapterId;
  String title;
  String text;

  Map<String, dynamic> toMap() => {
    "book": book,
    "book_id": bookId,
    "chapter": chapter,
    "chapter_id": chapterId,
    "title": title,
    "text": text,
  };
}

class Verse {
  Verse({
    this.book,
    this.bookId,
    this.bookTitle,
    this.chapter,
    this.chapterId,
    this.verse,
    this.text,
  });

  factory Verse.fromMap(Map<String, dynamic> data) => new Verse(
    book: data["book"],
    bookId: data["book_id"],
    bookTitle: data["book_title"],
    chapter: data["chapter"],
    chapterId: data["chapter_id"],
    verse: data["verse"],
    text: data["text"],
  );

  String book;
  int bookId;
  String bookTitle;
  String chapter;
  int chapterId;
  int verse;
  String text;

  Map<String, dynamic> toMap() => {
    "book": book,
    "book_id": bookId,
    "book_title": bookTitle,
    "chapter": chapter,
    "chapter_id": chapterId,
    "verse": verse,
    "text": text,
  };
}