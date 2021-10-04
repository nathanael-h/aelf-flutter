import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/bibleDbHelper.dart';

class BibleSearchScreen extends StatefulWidget {
  static const routeName = '/bibleSearchScreen';
  BibleSearchScreen({Key key}) : super(key: key);

  @override
  _BibleSearchScreenState createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {

  String keyword = "";
  List verses;
  Map<String, dynamic> bibleIndex;
  Future searchVersesFuture;


  @override
  void initState() {
    keyword = '';
    searchVersesFuture = BibleDbHelper.instance.searchVerses(keyword);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    loadAsset().then((_bibleIndex) {
      setState(() {
        bibleIndex = _bibleIndex;
      });
    });
    return Scaffold(
      appBar: AppBar(
        title: Text('Rechercher'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Entrer quelques mots...',
                border: OutlineInputBorder(),
                labelText: 'Rechercher un passage de la Bible'
              ),
              onChanged: (value) {
                setState(() {
                  keyword = value ?? "";
                  if (value.length > 2) {
                    searchVersesFuture = BibleDbHelper.instance.searchVerses(keyword);
                  }
                });
              },
            ),
          ),
          Text('keyword=' + keyword),
          Expanded(
            child: FutureBuilder(
              future: searchVersesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) print('snapshot.haserror ');
                var data = snapshot.data;
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: data.asMap().length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Row(
                          children: [
                            //FIXME: When title is long (eg Deuxième Livre
                            //des Martyres d'Israël) it does not fit the widht screen
                            //and there is a display bug.
                            Text(
                              data[index].bookTitle.toString() 
                              //TODO: color should be AELF red
                              ),
                            Spacer(),
                            Text(data[index].book.toString()+ ' ' + data[index].chapter.toString())
                            //TODO : color should be greyed
                          ],
                        ),
                        subtitle: Text(data[index].text.toString()),
                        isThreeLine: false,
                        onTap: () {
                          print('Go to selected verse in Bible');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (contect)=>
                              ExtractArgumentsScreen(
                                bookNameShort: data[index].book,
                                bookChToOpen: data[index].chapter,
                              ))
                          );
                        },
                      );
                    }
                  );
                } else {
                  return Text('Aucun résultat');
                }
              },
            ),
          )
        ],
      )
    );
  }
} 

class VerseResult extends StatelessWidget {

  final Map data;

  VerseResult(this.data, {Key key}) : super (key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
        title: Text(
          'a'
        ),
      ),
      
    );
  }
}

// A Widget that accepts the necessary arguments via the constructor.

//class PassArgumentsScreen extends StatelessWidget {
//  static const routeName = '/passArguments';
//
//  final String title;
//  final String message;
//
//  // This Widget accepts the arguments as constructor parameters. It does not
//  // extract the arguments from the ModalRoute.
//  //
//  // The arguments are extracted by the onGenerateRoute function provided to the
//  // MaterialApp widget.
//  const PassArgumentsScreen({
//    Key key,
//    @required this.title,
//    @required this.message,
//  }) : super(key: key);
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text(title),
//      ),
//      body: Center(
//        child: Text(message),
//      ),
//    );
//  }
//}
//
//// You can pass any object to the arguments parameter. In this example,
//// create a class that contains both a customizable title and message.
//class ScreenArguments {
//  final String title;
//  final String message;
//
//  ScreenArguments(this.title, this.message);
//}
//