import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:aelf_flutter/widgets/fr-fr_aelf.json.dart';

class BiblePositionState extends ChangeNotifier {
  String? lastBook;
  String? lastChapter;

  SharedPreferences? _pref;

  BiblePositionState() {
    _loadFromPrefs();
  }

  Future<void> _initPrefs() async {
    _pref ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    lastBook = _pref!.getString(keyLastBibleBook);
    lastChapter = _pref!.getString(keyLastBibleChapter);
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    await _initPrefs();
    if (lastBook != null) {
      _pref!.setString(keyLastBibleBook, lastBook!);
    }
    if (lastChapter != null) {
      _pref!.setString(keyLastBibleChapter, lastChapter!);
    }
  }

  Future<void> updatePosition(String book, String chapter) async {
    lastBook = book;
    lastChapter = chapter;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> clearPosition() async {
    lastBook = null;
    lastChapter = null;
    await _initPrefs();
    await _pref!.remove(keyLastBibleBook);
    await _pref!.remove(keyLastBibleChapter);
    notifyListeners();
  }

  String? getFormattedBookName() {
    if (lastBook == null) return null;

    // Special case for Psalms
    if (lastBook == 'Ps') {
      return 'Psaume $lastChapter';
    }

    // Get book name from bible index
    Map<String, dynamic> bibleIndex = bibleIndexMap;
    if (bibleIndex.containsKey(lastBook)) {
      return bibleIndex[lastBook]['name'];
    }

    return lastBook;
  }

  bool get hasPosition => lastBook != null && lastChapter != null;
}
