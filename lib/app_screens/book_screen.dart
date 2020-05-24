import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/chapter_storage.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:aelf_flutter/bibleDbHelper.dart';

class UnselectableTextSpan extends TextSpan {
  const UnselectableTextSpan({
    String text,
    List<InlineSpan> children,
    TextStyle style,
    GestureRecognizer recognizer,
    String semanticsLabel,
  }): super(
    text: text,
    children: children,
    style: style,
    recognizer: recognizer,
    semanticsLabel: semanticsLabel,
  );

  @override
  void computeToPlainText(
    StringBuffer buffer, {
    bool includeSemanticsLabels = true,
    bool includePlaceholders = true
  }) {
    // This widget is not selectable, there is no text to add
  }

  // Hack: Pretend to be a vanilla TextSpan
  @override
  Type get runtimeType {
    return TextSpan;
  }
}

// Book widget
class ExtractArgumentsScreen extends StatefulWidget {
  static const routeName = '/extractArguments';

  final String bookName;
  final String bookNameShort;
  final ChapterStorage storage;
  final int bookChNbr;
  final int bookChToOpen;
  final List<dynamic> bookChStrings;

  const ExtractArgumentsScreen(
      {Key key,
      this.storage,
      this.bookName,
      this.bookNameShort,
      this.bookChNbr,
      this.bookChToOpen,
      this.bookChStrings})
      : super(key: key);

  @override
  _ExtractArgumentsScreenState createState() => _ExtractArgumentsScreenState();
}

class _ExtractArgumentsScreenState extends State<ExtractArgumentsScreen> {
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.bookChToOpen,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  goToPage(i) {
    _pageController.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    // Extract the arguments from the current ModalRoute settings and cast
    // them as ScreenArguments.
    //final ScreenArguments args = ModalRoute.of(context).settings.arguments;

    // Book screen
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30, 32, 36, 1),
        title: Text('${widget.bookName}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.bookChNbr,
        itemBuilder: (context, index) {
          final bookNameShort = widget.bookNameShort;
          final indexString = widget.bookChStrings[index];
          String chType;
          String headerText;
          if (bookNameShort == 'Ps') {
            chType = 'Psaume';
            headerText = '$chType $indexString';
          } else {
            chType = 'Chapitre';
            headerText = '$chType $indexString';
          }

          return Column(
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
                              color: Theme.of(context).backgroundColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      color: Theme.of(context).backgroundColor,
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuItem> popupmenuitems = [];
                        int i = 0;
                        popupmenuitems.clear();
                        for (String string in widget.bookChStrings) {
                          popupmenuitems.add(PopupMenuItem(
                            value: i,
                            child: Text('$chType $string'),
                          ));
                          i++;
                        }
                        return popupmenuitems;
                      },
                      onSelected: (i) => goToPage(i),
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).backgroundColor, size: 35),
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
          );
        },
      ),
    );
  }

  generator(int index) {}
}

class BibleHtmlView extends StatefulWidget {
  BibleHtmlView({
    Key key,
    this.shortName,
    this.indexStr,
  }) : super(key: key);

  final String shortName;
  final String indexStr;

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
    var spans = <TextSpan>[];

    var lineHeight = 1.2;
    var fontSize = 16.0;
    var verseIdFontSize = 10.0;
    var verseIdStyle = TextStyle(color: Theme.of(context).primaryColor, fontSize: verseIdFontSize, height: lineHeight);
    var textStyle = TextStyle(color: Color.fromRGBO(93, 69, 26, 1),fontSize: fontSize, height: lineHeight);

    for(Verse v in verses) {
      spans.add(TextSpan(children: <TextSpan>[
        UnselectableTextSpan(text: '${v.verse} ', style: verseIdStyle),
        TextSpan(text: v.text.replaceAll('\n', ' '), style: textStyle),
        TextSpan(text: '\n', style: textStyle)
      ]));
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 25),
      child: SelectableText.rich(TextSpan(children: spans))
      );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
