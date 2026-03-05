import 'dart:convert';
import 'package:aelf_flutter/utils/bibleDbHelper.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/bible_verse_id.dart';
import 'package:after_layout/after_layout.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BuildPage extends StatefulWidget {
  const BuildPage({
    Key? key,
    required this.verses,
    required this.keywords,
    required this.keys,
    required this.reference,
  }) : super(key: key);

  final List<Verse> verses;
  final List<String> keywords;
  final List<GlobalKey> keys;
  final String reference;

  @override
  State<BuildPage> createState() => _BuildPageState();
}

class _BuildPageState extends State<BuildPage>
    with AfterLayoutMixin<BuildPage> {
  // Optimization: Store processed data to avoid heavy re-calculating in build()
  List<dynamic> _parsedReference = [];
  List<String> _cleanedKeywords = [];

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  /// Prepare search keywords and reference JSON once at startup
  void _prepareData() {
    // 1. Pre-decode reference JSON safely
    if (widget.reference.isNotEmpty) {
      try {
        _parsedReference = jsonDecode(widget.reference);
      } catch (e) {
        debugPrint("Error decoding reference JSON: $e");
      }
    }

    // 2. Pre-clean keywords (strip accents, lowercase)
    _cleanedKeywords = widget.keywords
        .map((k) => cleanString(k))
        .where((k) => k.isNotEmpty)
        .toList();
  }

  @override
  void afterFirstLayout(BuildContext context) => scrollToResult();

  @override
  Widget build(BuildContext context) {
    // Disable system text scaling to use our custom zoom instead
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SafeArea(
        child: Consumer<CurrentZoom>(
          builder: (context, currentZoom, child) {
            final double fontSize = 16.0 * (currentZoom.value / 100);
            int matchId = 0;

            return SelectionArea(
              child: ListView.builder(
                // IMPORTANT: shrinkWrap allows the list to be used inside scrolling parents
                shrinkWrap: true,
                // If this page is already inside a scrollable view, use NeverScrollableScrollPhysics
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(5, 10, 20, 25),
                itemCount: widget.verses.length,
                itemBuilder: (context, index) {
                  final Verse v = widget.verses[index];
                  final String vText = v.text ?? "";
                  final String vNum = v.verse ?? "";
                  final String vChap = v.chapter ?? "";

                  // Optimization: Logic checks are now faster with pre-processed data
                  final bool isMatch =
                      _isSearchMatch(vText) || _isReferenceMatch(vChap, vNum);

                  return BibleVerse(
                    key: isMatch ? widget.keys[matchId++] : null,
                    id: vNum,
                    text: vText,
                    fontSize: fontSize,
                    highlight: isMatch,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Logic to check if a verse is highlighted via a reference range
  bool _isReferenceMatch(String chapterStr, String verseStr) {
    if (_parsedReference.isEmpty) return false;

    final int currentChapter = int.tryParse(chapterStr) ?? 0;
    final int currentVerse = int.tryParse(verseStr) ?? 0;

    for (var range in _parsedReference) {
      final int startCh = range["chapter_start"] ?? -1;
      final int endCh = range["chapter_end"] ?? -1;
      final int startVs = range["verse_start"] ?? -1;
      final int endVs = range["verse_end"] ?? -1;

      if (currentChapter >= startCh && currentChapter <= endCh) {
        if (currentVerse >= startVs && currentVerse <= endVs) {
          return true;
        }
      }
    }
    return false;
  }

  /// Logic to check if a verse contains search keywords
  bool _isSearchMatch(String text) {
    if (_cleanedKeywords.isEmpty) return false;

    final String cleanedVerse = cleanString(text);
    for (String keyword in _cleanedKeywords) {
      if (cleanedVerse.contains(keyword)) return true;
    }
    return false;
  }

  /// Auto-scroll to the first highlighted result
  void scrollToResult() {
    if (widget.keys.isNotEmpty && widget.keys[0].currentContext != null) {
      try {
        Scrollable.ensureVisible(
          widget.keys[0].currentContext!,
          alignment: 0.2,
          duration: const Duration(milliseconds: 300),
        );
      } catch (e) {
        debugPrint("Scroll error: $e");
      }
    }
  }
}

// --- UI COMPONENTS ---

class BibleVerse extends StatelessWidget {
  final String id;
  final String text;
  final double fontSize;
  final bool highlight;

  const BibleVerse({
    Key? key,
    required this.id,
    required this.text,
    required this.fontSize,
    required this.highlight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: fontSize / 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BibleVerseId(id: id, fontSize: fontSize),
          BibleVerseText(text: text, fontSize: fontSize, highlight: highlight),
        ],
      ),
    );
  }
}

class BibleVerseText extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool highlight;

  static const double lineHeight = 1.2;
  static const Color highlightColor = Color.fromARGB(130, 223, 118, 118);

  const BibleVerseText({
    Key? key,
    required this.text,
    required this.fontSize,
    required this.highlight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        "$text ",
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: fontSize,
          height: lineHeight,
          backgroundColor: highlight ? highlightColor : Colors.transparent,
        ),
      ),
    );
  }
}

/// Helper function to normalize strings for search (accents, case)
String cleanString(String string) {
  if (string.isEmpty) return "";
  string = removeDiacritics(string).toLowerCase();
  return string.replaceAll(RegExp(r'[^\p{L}\p{M} ]+', unicode: true), '');
}
