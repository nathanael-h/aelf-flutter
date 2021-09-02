import 'dart:io';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BibleDbHelper {
  // define all db parameters
  static final _databaseName = "bible.db";

  // make this a singleton class
  BibleDbHelper._privateConstructor();
  static final BibleDbHelper instance = BibleDbHelper._privateConstructor();

  Future queryDatabase(String sql, List<Object> parameters) async {
    var databasesPath = await getApplicationDocumentsDirectory();
    var path = join(databasesPath.path, _databaseName);
    // Check if the database exists
    bool exists = File(path).existsSync();
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
    print('Using sqlite3 ${sqlite3.version}');
    final db = sqlite3.open(path);
    final ResultSet resultSet =
      //db.select('SELECT * FROM verses WHERE text LIKE ?', ['%boire%']);
      db.select(sql, parameters);

    db.dispose();
    
    return resultSet;
  }
  
  // Helper methods

  // get number of chapter in a book
  Future<int> getChapterNumber(String book) async {
    final ResultSet resultSet = 
      await queryDatabase(
        'SELECT COUNT (*) FROM chapters WHERE book=?;',
        [book]);
    int count = int.parse(resultSet.rows[0][0].toString());
    return count;
  }
  // get chapter verses
  Future<List<Verse>> getChapterVerses(String book, String chapter) async {
    ResultSet resultSet = await queryDatabase(
      'SELECT * FROM verses WHERE book=? AND chapter=?',
      [book, chapter]);

    List<Verse> output = [];

    resultSet.rows.forEach((element) {
        print('sq3_result:  $element');
        output.add(Verse(
          book: element[0],
          bookId: element[1],
          bookTitle: element[2],
          chapter: element[3],
          chapterId: element[4],
          text: element[7],
          verse: element[6]
        ));
      });

    return output;
  }

  // search verses with keyword
  Future<List<Verse>> searchVerses(String keywork) async {
    if (keywork == "") {return null;} else {
    ResultSet resultSet = await queryDatabase(
        'SELECT * FROM verses WHERE text LIKE ?',
        ['%$keywork%']);
        //"SELECT * FROM verses WHERE book LIKE ? ",
        //[keyword]);

    List<Verse> output = [];

    resultSet.rows.forEach((element) {
        print('sq3_result:  $element');
        output.add(Verse(
          book: element[0],
          bookId: element[1],
          bookTitle: element[2],
          chapter: element[3],
          chapterId: element[4],
          text: element[7],
          verse: element[6]
        ));
      });

      return output;
    }
  }
}

/* call example
import 'package:aelf_flutter/bibleDbHelper.dart';
    BibleDbHelper.instance
      .getChapterNumber(string)
      .then((value) {
        setState(() {
          this.chNbr = value;
          print('chNbr = ' + this.chNbr.toString());
        });
      });  
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