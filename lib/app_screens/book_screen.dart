import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
//import 'package:aelf_flutter/main.dart';
import 'package:aelf_flutter/chapter_storage.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:aelf_flutter/app_screens/not_dev_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aelf_flutter/css-theme.dart';

// Book widget
class ExtractArgumentsScreen extends StatefulWidget {
  static const routeName = '/extractArguments';

  final String bookName;
  final String bookNameShort;
  final ChapterStorage storage;
  final int bookChNbr;
  final int bookChToOpen;
  final List<dynamic> bookChStrings;

  const ExtractArgumentsScreen({Key key, this.storage, this.bookName, this.bookNameShort, this.bookChNbr, this.bookChToOpen, this.bookChStrings})
      : super(key: key);

  @override
  _ExtractArgumentsScreenState createState() => _ExtractArgumentsScreenState();
}

class _ExtractArgumentsScreenState extends State<ExtractArgumentsScreen> {
  var chapter = ChapterStorage('assets/chapter.txt').loadAsset().toString();

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
  
  final Completer<WebViewController> _controller = Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    // Extract the arguments from the current ModalRoute settings and cast
    // them as ScreenArguments.
    //final ScreenArguments args = ModalRoute.of(context).settings.arguments;

    // Book screen
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookName}'),
      ),
      body: 
      PageView.builder(
        controller: _pageController,
        itemCount: widget.bookChNbr,
        itemBuilder: (context, index) {
          final bookNameShort = widget.bookNameShort;
          final indexString = widget.bookChStrings[index];
          String chType;
          String headerText;
          String contentBase64 = 'Null';
          if (bookNameShort == 'Ps') {
            chType = 'Psaume';
            headerText = '$chType $indexString';
          } else {
            chType = 'Chapitre';
            headerText = '$chType $indexString';
          ChapterStorage('assets/bible/${widget.bookNameShort}/$indexString.html').loadAsset().then((chapterHTML){setState(() {
            chapter = chapterHTML;
          });});
          String neededhtml = 
          "<!DOCTYPE html><html><head><style>"+
          getcsstheme()+
          "</style></head>"+
          "<body>"+
          chapter+
          "</body></html>";
            contentBase64 = base64Encode(const Utf8Encoder().convert(neededhtml));
          }

          return Column(
                  children: <Widget>[
                    //Text(args.message),
                    //Text('Yolo !'),
                    SingleChildScrollView(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: GestureDetector(
                              //onTap: () => ToDo('Afficher la liste des chapitres').popUp(context), TODO: Make this  ShowMenu with all chapters/psalms
                              child: Text(
                                headerText,
                                style: Theme.of(context).textTheme.headline,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (BuildContext context) {
                              List<PopupMenuItem> popupmenuitems = [];
                              int i = 0;
                              popupmenuitems.clear();
                              for (String string in widget.bookChStrings) {
                                popupmenuitems.add(
                                  PopupMenuItem(
                                    value: i,
                                    child: Text('$chType $string'),
                                    )
                                );
                                i++;
                              }
                              return popupmenuitems;
                            },
                            onSelected: (i) => goToPage(i),
                            icon:Icon(Icons.arrow_drop_down),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Expanded(
                          child: WebView(
                            initialUrl: 'data:text/html;base64,$contentBase64',
                            javascriptMode: JavascriptMode.unrestricted,
                            //onWebViewCreated: (WebViewController webViewController) {
                            //  _controller.complete(webViewController);
                            //},
                            //gestureNavigationEnabled: true,
                            //gestureRecognizers: Set()
                            //  ..add(Factory<LongPressGestureRecognizer>(() => LongPressGestureRecognizer())),
                      //        child: Html(
                      //  data: chapter, 
                      //  padding: EdgeInsets.only(
                      //      left: 20.0, right: 20.0, bottom: 20.0),
                      //  customTextAlign: (dom.Node node) {
                      //    return TextAlign.justify;
                      //  },
                      //  customTextStyle: (dom.Node node, TextStyle baseStyle) {
                      //    return baseStyle
                      //        .merge(TextStyle(height: 1.2, fontSize: 16));
                      //  },
                      //)
                          )
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  generator(int index) {
  }
}
