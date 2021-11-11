import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

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
      // print("Opening existing database");
    }
    // print('Using sqlite3 ${sqlite3.version}');
    print("SQL request = $sql");
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
  
  // get long book name
  Future<String> getBookNameLong(String bookNameshort) async {
    final ResultSet resultSet = 
      await queryDatabase(
        'SELECT book_title FROM VERSES WHERE book = ? LIMIT 1;',
        [bookNameshort]);
    String bookNameLong = resultSet.rows[0][0].toString();
    return bookNameLong;
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
  Future<List<Verse>> searchVerses(String keywords, int order) async {
    log('Called searchVerses');
    if (keywords == "" || keywords.length < 3 || keywords == null ) {
      return null;
      } else {
    Map<int, String> orders = {
      -1: "CAST(book_id as INTEGER),CAST(chapter AS INTEGER)",
       1: "rank"
    };
    // Add a wildcard to the last word if the query is long enough and does not already end with a wildcard
    // https://github.com/HackMyChurch/aelf-dailyreadings/blob/841e3d72f7bc6de3d0f4867d42131392e67b42df/app/src/main/java/co/epitre/aelf_lectures/bible/BibleSearchFragment.java#L143
    if (keywords.length >= 3 && !keywords.endsWith("*")) {
      keywords = keywords + "*";
    }
    List<String> tokens = [];
    for(String keyword in keywords.split(RegExp(r"(\s+)"))) {
      if (shouldIgnore(keyword)){
        continue;
        }
      tokens.add(keyword);
    }
    if (tokens == [] ) {return null;} else {
      //fts5 parameters
      String param1 = '"';
      String param2 = "";
      String param3 = "";
      String paramAll = "";
      //param1
      tokens.forEach((element) {
        param1 = param1 + element + " ";
      });
      //param2
      param2 ='(';
      tokens.forEach((element) {
        param2 = param2 + '"'+ element + '"' + " ";
      });
      param2 = param2 + '_';
      param2 = param2.split('" _')[0];
      param2 = param2 + '*", 4)';
      //param3
      param3 ='';
      tokens.forEach((element) {
        param3 = param3 + element + ' ';
      });
      param3 = param3 + '_';
      param3 = param3.split(' _')[0];

      paramAll = "'" + param1 + '" OR NEAR' + param2 + " OR "+ param3 + "'";
      //print("parameters = " + paramAll);
      
      ResultSet resultSet = await queryDatabase(
          """SELECT book, chapter, title, rank, '' AS skipped, snippet(search, -1, '<b>', '</b>', '...', 32) AS snippet
          FROM search 
          WHERE text MATCH $paramAll 
          ORDER BY ${orders[order]}
          LIMIT 50;""",
          []);

          //"SELECT * FROM verses WHERE book LIKE ? ",
          //[keyword]);

      List<Verse> output = [];

      resultSet.rows.forEach((element) {
          //print('sq3_result:  $element');
          output.add(Verse(
            book: element[0],
            bookTitle: element[2],
            chapter: element[1],
            text: element[5],
          ));
        });

        return output;
      }
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

// Source: https://github.com/HackMyChurch/aelf-dailyreadings/blob/841e3d72f7bc6de3d0f4867d42131392e67b42df/app/src/main/java/co/epitre/aelf_lectures/bible/data/BibleController.java#L78
shouldIgnore(String token) {
  token = token.toLowerCase();
  token = unorm.nfd(token).replaceAll(RegExp("[^a-z0-9* ]"), "");

  if (token.length <= 1) {
    return true;
  }

  // Ignore too common words
  if (tokenIgnore.contains(token)) {
      return true;
  }

  return false;
}

final List<String> tokenIgnore = [
  // Conjonctions de coordinations
  "mais", "ou", "et", "donc", "or", "ni", "car",

  // Conjonctions de subordination (shortest/most frequent only)
  "qu", "que", "si", "alors", "tandis",

  // Déterminants
  "le", "la", "les", "un", "une", "du", "de", "la",
  "ce", "cet", "cette", "ces",
  "ma", "ta", "sa",
  "mon", "ton", "son", "notre", "votre", "leur",
  "nos", "tes", "ses", "nos", "vos", "leurs",

  // Interrogatifs
  "quel", "quelle", "quelles", "quoi"
];
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