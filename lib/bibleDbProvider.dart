import 'dart:io';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BibleDbProvider {
  static final _databaseName = "bible.db";

  // make this a singleton class
  BibleDbProvider._privateConstructor();
  static final BibleDbProvider instance = BibleDbProvider._privateConstructor();

  Future<Database> getBibleDb() async {
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
    }
    print('SQLite3.open Bible db');
    final db = sqlite3.open(path);  
    return db;
  }
}