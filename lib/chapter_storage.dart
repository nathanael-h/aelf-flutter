import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

//https://flutter.dev/docs/cookbook/persistence/reading-writing-files
class ChapterStorage {
  final String path;

  ChapterStorage(this.path);
  
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localChapter async {
    final path = await _localPath;
    return File('$path/assets/chapter.txt');
  }

  Future<String> readChapter() async {
    try {
      final file = await _localChapter;

      // Read the chapter
      String contents = await Future.value(file.readAsStringSync());
      return contents;
    } catch (e) {
      // If error, return a message
      return 'error while reading text file';
    }
  }
// Load Assets https://flutter.dev/docs/development/ui/assets-and-images
  Future<String> loadAsset() async {
    // print('\$path = ''$path');
    try {
      return await rootBundle.loadString('$path');
    } catch (e) {
      return ('Erreur pour ouvrir le chemin : $path');
    }
  }

}