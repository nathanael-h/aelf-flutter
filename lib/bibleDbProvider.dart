import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BibleDbSqfProvider {
  static final _databaseName = "bible.db";

  // make this a singleton class
  BibleDbSqfProvider._privateConstructor();
  static final BibleDbSqfProvider instance = BibleDbSqfProvider._privateConstructor();

  Database db;

  Future<void> ensureDatabase() async {
    if (db == null) {
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
      } else {}
      print('SQLite3.open Bible db');
      this.db = await databaseFactory.openDatabase(path);
      print('Bible db = ${this.db.hashCode}');
    }
  }

  Database getDatabase() {
    assert(this.db != null);
    return db;
  }
}