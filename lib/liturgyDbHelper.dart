import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class LiturgyDbHelper {
  // define all db parameters
  static final _databaseName = "liturgy.db";
  static final _databaseVersion = 4;

  static final table = 'liturgy';

  static final columnType = 'type';
  static final columnDate = 'date';
  static final columnContent = 'content';
  static final columnRegion = 'region';

  // make this a singleton class
  LiturgyDbHelper._privateConstructor();
  static final LiturgyDbHelper instance = LiturgyDbHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) {
        _updateTableLiturgyV1toV2(db, oldVersion);
        _updateTableLiturgyV2toV3(db, oldVersion);
        _updateTableLiturgyV3toV4(db, oldVersion);
      },
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    print("create table $table .....");
    await db.execute('''
          CREATE TABLE IF NOT EXISTS $table (
            $columnDate NUMERIC NOT NULL,
            $columnType TEXT NOT NULL,
            $columnContent INTEGER NOT NULL,
            $columnRegion TEXT NOT NULL,
            PRIMARY KEY ($columnDate, $columnType, $columnRegion)
          )
          ''');
  }

  // Migration from v1 to v2 database
  // We just have to drop tables, and add the *region* column
  Future _updateTableLiturgyV1toV2(Database db, int oldVersion) async {
    if (oldVersion == 1) {
      print('migrate $table from v1 to v2');
      await db.execute('DROP TABLE IF EXISTS $table');
      _onCreate(db, 2);
    }
  }

  // Migration from v2 to v3 database
  // We just have to drop tables, because we save the Json content with one upper level
  Future _updateTableLiturgyV2toV3(Database db, int oldVersion) async {
    if (oldVersion == 2) {
      print('migrate $table from v2 to v3');
      await db.execute('DROP TABLE IF EXISTS $table');
      _onCreate(db, 3);
    }
  }

  // Migration from v3 to v4 database
  // We changed the API used to retrieve liturgy's information
  // so we need to remove cached 'information' data
  Future _updateTableLiturgyV3toV4(Database db, int oldVersion) async {
    if (oldVersion == 3) {
      print('migrate $table from v3 to v4');
      await db.execute("DELETE FROM $table WHERE type = 'informations'");
      _onCreate(db, 4);
    }
  }

  // Helper methods

  // inserted row.
  Future<int?> insert(Liturgy row) async {
    Database db = (await instance.database)!;
    try {
      return await db.insert(table, row.toMap());
    } catch (e) {
      log("error in liturgy saver: ", error: e);
    }
    return null;
  }

  // display All of the rows are returned as a list of maps, where each map is (used for debug)
  void getAllLiturgy() async {
    Database db = (await instance.database)!;
    List<dynamic> allRows = await db.query(table);
    print('query all rows:');
    allRows.forEach((row) => print("db : " + row["date"] + " " + row["type"]));
  }

  // get row by date and type and region
  Future<Liturgy?> getRow(String date, String? type, String region) async {
    Database db = (await instance.database)!;
    dynamic results = await db.rawQuery(
        'SELECT * FROM $table WHERE date = ? AND type = ? AND region = ? LIMIT 1',
        [date, type, region]);

    if (results.length > 0) {
      return new Liturgy.fromMap(results.first);
    }
    return null;
  }

  // check if element existing in db
  Future<bool> checkIfExist(String date, String type, String region) async {
    Database db = (await instance.database)!;
    dynamic results = await db.rawQuery(
        'SELECT * FROM $table WHERE date = ? AND type = ? AND region = ? LIMIT 1',
        [date, type, region]);

    if (results.length > 0) {
      return true;
    }
    return false;
  }

  // return count od element (not used)
  Future<int?> queryRowCount() async {
    Database db = (await instance.database)!;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  // Deletes all row before this date
  Future<int> deleteBibleDbBeforeDays(String date) async {
    Database db = (await instance.database)!;
    return await db.delete(table, where: '$columnDate < ?', whereArgs: [date]);
  }
}

class Liturgy {
  Liturgy({
    this.date,
    this.type,
    this.content,
    this.region,
  });

  factory Liturgy.fromMap(Map<String, dynamic> data) => new Liturgy(
        date: data["date"],
        type: data["type"],
        content: data["content"],
        region: data["region"],
      );

  String? content;
  String? date;
  String? type;
  String? region;

  Map<String, dynamic> toMap() => {
        "date": date,
        "type": type,
        "content": content,
        "region": region,
      };
}
// call example
// init db controller
//final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
/*liturgyDbHelper.getRow('2020-03-29', 'messe', 'canada').then((final Liturgy rep){
  print(rep.content+' '+rep.date.toString() + rep.region);
});*/
