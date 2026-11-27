import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aelf_flutter/utils/bible_language.dart';

class BibleDbSqfProvider {
  final String _databaseName;

  BibleDbSqfProvider._(this._databaseName);

  static final BibleDbSqfProvider french = BibleDbSqfProvider._('bible.db');
  static final BibleDbSqfProvider greek =
      BibleDbSqfProvider._('bible_grc.db');
  static final BibleDbSqfProvider hebrew =
      BibleDbSqfProvider._('bible_heb.db');

  // Kept for the many existing call sites that always meant the French
  // database.
  static final BibleDbSqfProvider instance = french;

  static BibleDbSqfProvider forLanguage(BibleLanguage language) =>
      switch (language) {
        BibleLanguage.french => french,
        BibleLanguage.greek => greek,
        BibleLanguage.hebrew => hebrew,
      };

  Database? db;

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
        // The parameter passed to the load function should exactly
        // represent the path provided in the pubspec.yaml file
        // (seems like the join function twists the /to a \ on windows)
        // https://stackoverflow.com/a/76582397
        ByteData data = await rootBundle.load("assets/$_databaseName");
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        // Write and flush the bytes written
        await File(path).writeAsBytes(bytes, flush: true);
      } else {}
      print('SQLite3.open Bible db');
      db = await databaseFactory.openDatabase(path);
      print('Bible db = ${db.hashCode}');
    }
  }

  Database? getDatabase() {
    assert(db != null);
    return db;
  }
}
