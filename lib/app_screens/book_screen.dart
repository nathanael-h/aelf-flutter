import 'dart:developer' as dev;
import 'package:aelf_flutter/main.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/bibleDbHelper.dart';
import 'package:provider/provider.dart';

// Book widget
class ExtractArgumentsScreen extends StatefulWidget {
  static const routeName = '/extractArguments';

  final String? bookNameShort;
  final String? bookChToOpen;

  const ExtractArgumentsScreen(
      {Key? key,
      this.bookNameShort,
      this.bookChToOpen})
      : super(key: key);

  @override
  _ExtractArgumentsScreenState createState() => _ExtractArgumentsScreenState();
}

class _ExtractArgumentsScreenState extends State<ExtractArgumentsScreen> {
  PageController? _pageController;
  int? chNbr;
  late Map<String, dynamic> bibleIndex;
  List<dynamic>? bookListChapters;
  int bibleChapterId = 0;
  String bookNameLong = "";

  // Source : https://github.com/HackMyChurch/aelf-dailyreadings/blob/841e3d72f7bc6de3d0f4867d42131392e67b42df/app/src/main/java/co/epitre/aelf_lectures/bible/BibleBookFragment.java#L56
  // FIXME: this is *very* ineficient
  // Locate chapter
  Future<int> locateChapter (String? bookChToOpen) async{
    bool found = false;
    
    await loadBibleIndex();
    for (String bibleBookChapter in bibleIndex[widget.bookNameShort]['chapters']) {
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
  print('bibleChapterId = ' + bibleChapterId.toString());
  return bibleChapterId;
  }

  loadChNbr (String? string) {
    BibleDbHelper.instance
      .getChapterNumber(string)
      .then((value) {
        setState(() {
          this.chNbr = value;
          print('chNbr = ' + this.chNbr.toString());
        });
      });  
}

  loadBibleIndex() async {     
    bibleIndex = await loadAsset() ;
    bookListChapters = bibleIndex[widget.bookNameShort]['chapters'];
  }

  loadBookNameLong (String? string) {
    BibleDbHelper.instance
      .getBookNameLong(string)
      .then((value) {
        setState(() {
          this.bookNameLong = value;
        });
      });
  }

  @override
  void initState() {
    super.initState();

    loadChNbr(widget.bookNameShort);
    locateChapter(widget.bookChToOpen).then((bibleChapterId) {
      _pageController = PageController(
        initialPage: bibleChapterId
      );
    });
    loadBookNameLong(widget.bookNameShort);
  }

  @override
  void dispose() {
    _pageController!.dispose();
    super.dispose();
  }

  goToPage(i) {
    _pageController!.jumpToPage(i);
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
      body: 
      (bookListChapters == null) //TODO: replace this with a state of the art handling of async/await
      ? Center(child: Text('Chargement...'),)
      : PageView.builder(
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
                dev.log("onScaleUpdate: pinch scaling factor: zoomBeforePinch: $zoomBeforePinch; ${scaleUpdateDetails.scale}; new zoom: $_newZoom");
              };
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
                        color: Theme.of(context).colorScheme.background,
                        itemBuilder: (BuildContext context) {
                          List<PopupMenuItem> popupmenuitems = [];
                          int i = 0;
                          popupmenuitems.clear();
                          for (String string in bookListChapters as Iterable<String>) {
                            popupmenuitems.add(PopupMenuItem(
                              value: i,
                              child: Text('$chType $string', style: Theme.of(context).textTheme.bodyMedium,),
                            ));
                            i++;
                          }
                          return popupmenuitems;
                        },
                        onSelected: (dynamic i) => goToPage(i),
                        icon: Icon(Icons.arrow_drop_down,
                            color: Theme.of(context).tabBarTheme.labelColor, size: 35),
                      ),
                    ],
                  ),
                ),
                Expanded(
                    child: SingleChildScrollView(
                  // I created a new class which return the html widget, so that only this widget is rebuilt once the contact is loaded form the stored file.
                  child: Container(
                    padding: EdgeInsets.only(top: 14),
                    child: BibleHtmlView(
                      shortName: widget.bookNameShort,
                      indexStr: indexString,
                    ),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  generator(int index) {}
}

class BibleHtmlView extends StatefulWidget {
  BibleHtmlView({
    Key? key,
    this.shortName,
    this.indexStr,
  }) : super(key: key);

  final String? shortName;
  final String? indexStr;

  @override
  _BibleHtmlViewState createState() => _BibleHtmlViewState();
}

enum LoadingState {
  Loading,
  Loaded
}

class _BibleHtmlViewState extends State<BibleHtmlView> {

  LoadingState loadingState = LoadingState.Loading;
  List<Verse> verses = [];

  @override
  void initState() {
    super.initState();
    loadBible();
  }

  loadBible() {
    BibleDbHelper.instance
      .getChapterVerses(widget.shortName, widget.indexStr)
      .then((List<Verse> verses){
        setState(() {
          this.verses = verses;
          this.loadingState = LoadingState.Loaded;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    switch (loadingState) {
      case LoadingState.Loading:
        return Text('Chargement en cours...');
        
      case LoadingState.Loaded:
        return buildPage(context);
    }

    return null;
  }

  Widget buildPage(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        var spans = <TextSpan>[];

        var lineHeight = 1.2;
        var fontSize = 16.0 * currentZoom.value!/100;
        var verseIdFontSize = 10.0 * currentZoom.value!/100;
        var verseIdStyle = TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: verseIdFontSize, height: lineHeight);
        var textStyle = TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color,fontSize: fontSize, height: lineHeight);

        for(Verse v in verses) {
          spans.add(TextSpan(children: <TextSpan>[
            TextSpan(text: '${v.verse} ', style: verseIdStyle),
            TextSpan(text: v.text!.replaceAll('\n', ' '), style: textStyle),
            TextSpan(text: '\n', style: textStyle)
          ]));
        }

        return Container(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 25),
        child: SelectableText.rich(TextSpan(children: spans))
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
