import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class LiturgyDbHelper {
  // define all db parameters
  static final _databaseName = "liturgy.db";
  static final _databaseVersion = 1;

  static final table = 'liturgy';

  static final columnType = 'type';
  static final columnDate = 'date';
  static final columnContent = 'content';

  // make this a singleton class
  LiturgyDbHelper._privateConstructor();
  static final LiturgyDbHelper instance = LiturgyDbHelper._privateConstructor();

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
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    print("create table $table .....");
    await db.execute('''
          CREATE TABLE IF NOT EXISTS $table (
            $columnDate NUMERIC NOT NULL,
            $columnType TEXT NOT NULL,
            $columnContent INTEGER NOT NULL,
            PRIMARY KEY ($columnDate, $columnType)
          )
          ''');
  }

  // Helper methods

  // inserted row.
  Future<int> insert(Liturgy row) async {
    Database db = await instance.database;
    return await db.insert(table, row.toMap());
  }

  // display All of the rows are returned as a list of maps, where each map is (used for debug)
  void getAllLiturgy() async {
    Database db = await instance.database;
    List<dynamic> allRows = await db.query(table);
    print('query all rows:');
    allRows.forEach((row) => print("db : " + row["date"] + " " + row["type"]));
  }

  // get row by date and type
  Future<Liturgy> getRow(String date, String type) async {
    Database db = await instance.database;
    dynamic results = await db.rawQuery(
        'SELECT * FROM $table WHERE date = ? AND type = ? LIMIT 1',
        [date, type]);

    if (results.length > 0) {
      return new Liturgy.fromMap(results.first);
    }
    return null;
  }

  // check if element existing in db
  Future<bool> checkIfExist(String date, String type) async {
    Database db = await instance.database;
    dynamic results = await db.rawQuery(
        'SELECT * FROM $table WHERE date = ? AND type = ? LIMIT 1',
        [date, type]);

    if (results.length > 0) {
      return true;
    }
    return false;
  }

  // return count od element (not used)
  Future<int> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  // Deletes all row before this date
  Future<int> deleteBibleDbBeforeDays(String date) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnDate < ?', whereArgs: [date]);
  }
}

class Liturgy {
  Liturgy({
    this.date,
    this.type,
    this.content,
  });

  factory Liturgy.fromMap(Map<String, dynamic> data) => new Liturgy(
        date: data["date"],
        type: data["type"],
        content: data["content"],
      );

  String content;
  String date;
  String type;

  Map<String, dynamic> toMap() => {
        "date": date,
        "type": type,
        "content": content,
      };
}
// call example
// init db controller
//final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
/*liturgyDbHelper.getRow('2020-03-29', 'messe').then((final Liturgy rep){
  print(rep.content+' '+rep.date.toString());
});*/