import 'package:flutter/material.dart';
//import 'package:aelf_flutter/main.dart';
import 'package:aelf_flutter/chapter_storage.dart';

// Book widget
class ExtractArgumentsScreen extends StatefulWidget {
  static const routeName = '/extractArguments';

  final String bookName;
  final ChapterStorage storage;

  const ExtractArgumentsScreen({Key key, this.storage, this.bookName}) : super(key: key);


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
      body: Column(
        children: <Widget>[
          //Text(args.message),
          //Text('Yolo !'),
          Text('${widget.bookName}', style: Theme.of(context).textTheme.title),
          Expanded (child: SingleChildScrollView(child: Text('$chapter'))),
        ],
      ),
    );
  }
}
