import 'package:aelf_flutter/bibleDbProvider.dart';
import 'package:sqflite/sqflite.dart' as sqf;
import 'package:unorm_dart/unorm_dart.dart' as unorm;
import 'package:diacritic/diacritic.dart';

class BibleDbHelper {


  // make this a singleton class
  BibleDbHelper._privateConstructor();
  static final BibleDbHelper instance = BibleDbHelper._privateConstructor();

  Future queryDatabaseSqf(String sql, List<Object?> parameters) async {
    sqf.Database dbSqf = BibleDbSqfProvider.instance.getDatabase()!;

    //print("SQL request = $sql");
    final  result =
      //db.select('SELECT * FROM verses WHERE text LIKE ?', ['%boire%']);
      dbSqf.rawQuery(sql, parameters);

    //db.dispose();
    
    return result;
  }
  
  // Helper methods

  // get number of chapter in a book
  Future<int> getChapterNumber(String? book) async {
    final List<Map> result = 
      await (queryDatabaseSqf(
        'SELECT COUNT (*) FROM chapters WHERE book=?;',
        [book]) as FutureOr<List<Map<dynamic, dynamic>>>);
    int count = int.parse(result[0]["COUNT (*)"].toString());
    return count;
  }  
  
  // get long book name
  Future<String> getBookNameLong(String? bookNameshort) async {
    final List<Map> result = 
      await (queryDatabaseSqf(
        'SELECT book_title FROM VERSES WHERE book = ? LIMIT 1;',
        [bookNameshort]) as FutureOr<List<Map<dynamic, dynamic>>>);
    String bookNameLong = result[0]["book_title"].toString();
    return bookNameLong;
  }
  // get chapter verses
  Future<List<Verse>> getChapterVerses(String? book, String? chapter) async {
    List<Map> result = await (queryDatabaseSqf(
      'SELECT * FROM verses WHERE book=? AND chapter=?',
      [book, chapter]) as FutureOr<List<Map<dynamic, dynamic>>>);

    List<Verse> output = [];

    result.forEach((element) {
        //print('sqf_result:  $element');
        output.add(Verse(
          book: element["book"],
          bookId: element["book_id"],
          bookTitle: element["book_title"],
          chapter: element["chapter"],
          chapterId: element["chapter_id"],
          text: element["text"],
          verse: element["verse"].toString()
        ));
      });

    return output;
  }

  // search verses with keyword
  Future<List<Verse>?> searchVerses(String keywords, int order) async {
    final stopwatch = Stopwatch()..start();
    print('Called searchVerses');
    print('keywords : ' + keywords.toString());
    print('order : ' + order.toString());
    keywords = removeDiacritics(keywords);
    print('keywords, normalized : ' + keywords.toString());
    keywords = keywords.replaceAll(RegExp(r'[^\p{L}\p{M} ]+',unicode: true), '');
    print('keywords, sanitized : ' + keywords.toString());
    sqf.Database? dbSqf = BibleDbSqfProvider.instance.getDatabase();
    if (keywords == "" || keywords.length < 3 ) {
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
      print("parameters = " + paramAll);

      print("Raw query:");
      print("""SELECT book, chapter, title, rank, '' AS skipped, snippet(search, -1, '<b>', '</b>', '...', 32) AS snippet
          FROM search 
          WHERE text MATCH $paramAll 
          ORDER BY ${orders[order]}
          LIMIT 50;""");

      print("Time since searchVerse() start: ${stopwatch.elapsedMicroseconds}");
      print("Execute query...");
      List<Map> resultSet = await dbSqf!.rawQuery (
          """SELECT book, chapter, title, rank, '' AS skipped, snippet(search, -1, '<b>', '</b>', '...', 32) AS snippet
          FROM search 
          WHERE text MATCH $paramAll 
          ORDER BY ${orders[order]}
          LIMIT 50;""",
          []);
      print("Time since searchVerse() start: ${stopwatch.elapsedMicroseconds}");
      print("Process results");

          //"SELECT * FROM verses WHERE book LIKE ? ",
          //[keyword]);

      List<Verse> output = [];

      resultSet.forEach((element) {   
          output.add(Verse(
            book: element["book"],
            bookTitle: element["title"],
            chapter: element["chapter"],
            text: element["snippet"],
          ));
        });

      print("Time since searchVerse() start: ${stopwatch.elapsedMicroseconds}");
      print("Return results");
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

  String? book;
  int? bookId;
  String? chapter;
  int? chapterId;
  String? title;
  String? text;

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

  String? book;
  int? bookId;
  String? bookTitle;
  String? chapter;
  int? chapterId;
  String? verse; //This should be a String because verse could be "17a", like in Esther, 4. 
  String? text;

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