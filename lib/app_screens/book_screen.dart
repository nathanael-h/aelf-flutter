import 'dart:developer' as dev;
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/biblePositionState.dart';
import 'package:aelf_flutter/widgets/book_screen_build_page.dart';
import 'package:aelf_flutter/widgets/fr-fr_aelf.json.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/utils/bibleDbHelper.dart';
import 'package:provider/provider.dart';

// Book widget
// ignore: must_be_immutable
class ExtractArgumentsScreen extends StatefulWidget {
  static const routeName = '/extractArguments';

  final String? bookNameShort;
  final String? bookChToOpen;
  List<String>? keywords = [""];
  String? reference;

  ExtractArgumentsScreen(
      {Key? key,
      required this.bookNameShort,
      required this.bookChToOpen,
      this.keywords,
      this.reference})
      : super(key: key);

  @override
  ExtractArgumentsScreenState createState() => ExtractArgumentsScreenState();
}

class ExtractArgumentsScreenState extends State<ExtractArgumentsScreen> {
  PageController? _pageController;
  int? chNbr;
  Map<String, dynamic> bibleIndex = bibleIndexMap;
  List<dynamic>? bookListChapters = <List<dynamic>?>[];
  int bibleChapterId = 0;
  String bookNameLong = "";

  // Source : https://github.com/HackMyChurch/aelf-dailyreadings/blob/841e3d72f7bc6de3d0f4867d42131392e67b42df/app/src/main/java/co/epitre/aelf_lectures/bible/BibleBookFragment.java#L56
  // FIXME: this is *very* ineficient
  // Locate chapter
  int locateChapter(String? bookChToOpen) {
    bool found = false;

    for (String bibleBookChapter in bibleIndex[widget.bookNameShort]
        ['chapters']) {
      if (bibleBookChapter == bookChToOpen) {
        found = true;
        break;
      }
      bibleChapterId++;
    }
    // Not found
    if (!found) {
      bibleChapterId = 0;
    }
    print('bibleChapterId = $bibleChapterId');
    return bibleChapterId;
  }

  void loadChNbr(String? string) {
    BibleDbHelper.instance.getChapterNumber(string).then((value) {
      setState(() {
        chNbr = value;
        print('chNbr = $chNbr');
      });
    });
  }

  void loadBookNameLong(String? string) {
    BibleDbHelper.instance.getBookNameLong(string).then((value) {
      setState(() {
        bookNameLong = value;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    bookListChapters = bibleIndex[widget.bookNameShort]['chapters'];
    loadChNbr(widget.bookNameShort);
    _pageController =
        PageController(initialPage: locateChapter(widget.bookChToOpen));

    // Add listener for PageView swiping
    _pageController!.addListener(() {
      if (_pageController!.page!.round() != _pageController!.page) {
        // Save position on page swipe
        final currentPage = _pageController!.page!.round();
        if (currentPage >= 0 && currentPage < (bookListChapters?.length ?? 0)) {
          final chapterToSave = bookListChapters![currentPage];
          context
              .read<BiblePositionState>()
              .updatePosition(widget.bookNameShort!, chapterToSave);
        }
      }
    });

    loadBookNameLong(widget.bookNameShort);

    // Save position on book open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chapterToSave = bibleIndex[widget.bookNameShort]['chapters']
          [locateChapter(widget.bookChToOpen)];
      context
          .read<BiblePositionState>()
          .updatePosition(widget.bookNameShort!, chapterToSave);
    });
  }

  @override
  void dispose() {
    _pageController!.dispose();
    super.dispose();
  }

  void goToPage(int i) {
    _pageController!.jumpToPage(i);
    // Save position on chapter navigation
    final chapterToSave = bookListChapters![i];
    context
        .read<BiblePositionState>()
        .updatePosition(widget.bookNameShort!, chapterToSave);
  }

  @override
  Widget build(BuildContext context) {
    // Extract the arguments from the current ModalRoute settings and cast
    // them as ScreenArguments.
    //final ScreenArguments args = ModalRoute.of(context).settings.arguments;

    // Book screen
    double? zoomBeforePinch = context.read<CurrentZoom>().value;
    return Scaffold(
      appBar: AppBar(
        title: Text(bookNameLong),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: chNbr,
        itemBuilder: (context, index) {
          final bookNameShort = widget.bookNameShort;
          final indexString = bookListChapters![index];
          String chType;
          String headerText;
          if (bookNameShort == 'Ps') {
            chType = 'Psaume';
            headerText = '$chType $indexString';
          } else {
            chType = 'Chapitre';
            headerText = '$chType $indexString';
          }

          return GestureDetector(
            onScaleUpdate: (ScaleUpdateDetails scaleUpdateDetails) {
              dev.log("onScaleUpdate detected, in book_screen");
              //var currentZoom =  context.read<CurrentZoom>();
              double _newZoom = zoomBeforePinch! * scaleUpdateDetails.scale;
              // Sometimes when removing fingers from screen, after a pinch or zoom gesture
              // the gestureDetector reports a scale of 1.0, and the _newZoom is set to 100%
              // which is not what I want. So a simple trick I found is to ignore this 'perfect'
              // 1.0 value.
              if (scaleUpdateDetails.scale == 1.0) {
                dev.log("scaleUpdateDetails.scale == 1.0");
              } else {
                context.read<CurrentZoom>().updateZoom(_newZoom);
                dev.log(
                    "onScaleUpdate: pinch scaling factor: zoomBeforePinch: $zoomBeforePinch; ${scaleUpdateDetails.scale}; new zoom: $_newZoom");
              }
            },
            onScaleEnd: (ScaleEndDetails scaleEndDetails) {
              dev.log("onScaleEnd detected, in book_screen");
              zoomBeforePinch = context.read<CurrentZoom>().value;
            },
            child: Column(
              children: <Widget>[
                //Text(args.message),
                //Text('Yolo !'),
                Container(
                  color: Theme.of(context).primaryColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: GestureDetector(
                          child: Text(
                            headerText,
                            style: TextStyle(
                                color: Theme.of(context).tabBarTheme.labelColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        itemBuilder: (BuildContext context) {
                          List<PopupMenuItem> popupmenuitems = [];
                          int i = 0;
                          popupmenuitems.clear();
                          for (String string in bookListChapters!) {
                            popupmenuitems.add(PopupMenuItem(
                              value: i,
                              child: Text(
                                '$chType $string',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ));
                            i++;
                          }
                          return popupmenuitems;
                        },
                        onSelected: (dynamic i) => goToPage(i),
                        icon: Icon(Icons.arrow_drop_down,
                            color: Theme.of(context).tabBarTheme.labelColor,
                            size: 35),
                      ),
                    ],
                  ),
                ),
                MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.noScaling),
                  child: Expanded(
                      child: SingleChildScrollView(
                    // I created a new class which return the html widget, so that only this widget is rebuilt once the contact is loaded form the stored file.
                    child: Container(
                      padding: EdgeInsets.only(top: 14),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 600,
                          child: BibleHtmlView(
                            shortName: widget.bookNameShort,
                            indexStr: indexString,
                            keywords: widget.keywords,
                            reference: widget.reference,
                          ),
                        ),
                      ),
                    ),
                  )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void generator(int index) {}
}

class BibleHtmlView extends StatefulWidget {
  BibleHtmlView(
      {Key? key, this.shortName, this.indexStr, this.keywords, this.reference})
      : super(key: key);

  final String? shortName;
  final String? indexStr;
  final List<String>? keywords;
  final String? reference;

  @override
  BibleHtmlViewState createState() => BibleHtmlViewState();
}

enum LoadingState { Loading, Loaded }

class BibleHtmlViewState extends State<BibleHtmlView> {
  LoadingState loadingState = LoadingState.Loading;
  List<Verse> verses = [];
  late List<GlobalKey> keys;

  @override
  void initState() {
    super.initState();
    loadBible();
  }

  Future<void> loadBible() async {
    BibleDbHelper.instance
        .getChapterVerses(widget.shortName, widget.indexStr)
        .then((List<Verse> verses) {
      setState(() {
        this.verses = verses;
        loadingState = LoadingState.Loaded;
      });
      keys = List<GlobalKey>.generate(
        verses.length,
        (_) {
          return GlobalKey();
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (loadingState) {
      case LoadingState.Loading:
        return Text('Chargement en cours...');

      case LoadingState.Loaded:
        return BuildPage(
            keys: keys,
            keywords: widget.keywords ?? [],
            verses: verses,
            reference: widget.reference ?? "");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
