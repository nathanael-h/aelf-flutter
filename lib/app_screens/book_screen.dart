import 'package:flutter/material.dart';
//import 'package:aelf_flutter/main.dart';
import 'package:aelf_flutter/chapter_storage.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

// Book widget
class ExtractArgumentsScreen extends StatefulWidget {
  static const routeName = '/extractArguments';

  final String bookName;
  final ChapterStorage storage;

  const ExtractArgumentsScreen({Key key, this.storage, this.bookName})
      : super(key: key);

  @override
  _ExtractArgumentsScreenState createState() => _ExtractArgumentsScreenState();
}

class _ExtractArgumentsScreenState extends State<ExtractArgumentsScreen> {
  var chapter = ChapterStorage('assets/chapter.txt').loadAsset().toString();

  @override
  void initState() {
    super.initState();
    widget.storage.loadAsset().then((String text) {
      setState(() {
        chapter = text;
      });
    });
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
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: TabBar(
            labelColor: Colors.red,
            unselectedLabelColor: Colors.red[100],
            tabs: [
              Tab(text: 'Chapitre précédent'),
              Tab(text: 'Chapitre 1'),
              Tab(text: 'Chapitre suivant'),
            ],),
          body: TabBarView(
            children: <Widget>[
              Tab(
                child: Column(
                  children: <Widget>[
                    //Text(args.message),
                    //Text('Yolo !'),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        '${widget.bookName}',
                        style: Theme.of(context).textTheme.headline,
                        textAlign: TextAlign.right,
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
                    ))),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  children: <Widget>[
                    //Text(args.message),
                    //Text('Yolo !'),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        '${widget.bookName}',
                        style: Theme.of(context).textTheme.headline,
                        textAlign: TextAlign.right,
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
                    ))),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  children: <Widget>[
                    //Text(args.message),
                    //Text('Yolo !'),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        '${widget.bookName}',
                        style: Theme.of(context).textTheme.headline,
                        textAlign: TextAlign.right,
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
                    ))),
                  ],
                ),
              ),            ],
          ),
        ),
      ),
    );
  }
}
