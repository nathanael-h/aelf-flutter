import 'package:flutter/material.dart';
//import 'package:aelf_flutter/main.dart';
import 'package:aelf_flutter/chapter_storage.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

// Book widget
class ExtractArgumentsScreen extends StatefulWidget {
  static const routeName = '/extractArguments';

  final String bookName;
  final String bookNameShort;
  final ChapterStorage storage;
  final int bookChNbr;
  final String bookChToOpen;

  const ExtractArgumentsScreen({Key key, this.storage, this.bookName, this.bookNameShort, this.bookChNbr, this.bookChToOpen})
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
    widget.storage.loadAsset().then((String text) {
      setState(() {
        chapter = text;
      });
    });
    _pageController = PageController(
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
//    _pageController.jumpToPage(widget.bookChToOpen);
    super.dispose();
  }
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
          String chapterFile = "";
          final bookNameShort = widget.bookNameShort;
          String headerText;
          if (bookNameShort == 'Ps') {
            chapterFile = widget.bookChToOpen;
            headerText = 'Psaume $chapterFile';
          } else {
            chapterFile = (index+1).toString();
            headerText = 'Chapitre $chapterFile' + "⇣";
          }
          ChapterStorage('assets/bible/${widget.bookNameShort}/$chapterFile.html').loadAsset().then((chapterHTML){setState(() {
            chapter = chapterHTML;
          });});

          return Column(
                  children: <Widget>[
                    //Text(args.message),
                    //Text('Yolo !'),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GestureDetector(
                        onTap: () {
                          final snackBar = SnackBar(content: Text("TODO: Affiche la liste des chapitres..."));
                          
                          Scaffold.of(context).showSnackBar(snackBar);
                        },
                        child: Text(
                          headerText,
                          style: Theme.of(context).textTheme.headline,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    Expanded(
                        child: SingleChildScrollView(
                            child: Html(
                      data: chapter, 
                      padding: EdgeInsets.only(
                          left: 20.0, right: 20.0, bottom: 20.0),
                      customTextAlign: (dom.Node node) {
                        return TextAlign.justify;
                      },
                      customTextStyle: (dom.Node node, TextStyle baseStyle) {
                        return baseStyle
                            .merge(TextStyle(height: 1.2, fontSize: 16));
                      },
                    )
                    )
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
