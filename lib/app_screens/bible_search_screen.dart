import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/bibleDbHelper.dart';
import 'package:flutter_html/flutter_html.dart';

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
  final isSelected = <bool>[true, false];
  int order=-1; //-1 = biblique ; 1 = pertinence



  @override
  void initState() {
    keyword = '';
    searchVersesFuture = BibleDbHelper.instance.searchVerses(keyword, -1);
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
              style: Theme.of(context).textTheme.bodyText2,
              decoration: InputDecoration(
                hintText: 'Entrer quelques mots...',
                border: OutlineInputBorder(),
                labelText: 'Rechercher un passage de la Bible',
                hintStyle: Theme.of(context).textTheme.bodyText2,
                labelStyle: Theme.of(context).textTheme.bodyText2,
                helperStyle: Theme.of(context).textTheme.bodyText2,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).accentColor))
              ),
              onChanged: (value) {
                setState(() {
                  keyword = value ?? "";
                  searchVersesFuture = BibleDbHelper.instance.searchVerses(keyword, order);
                });
              },
            ),
          ),
          ToggleButtons(
            color: Theme.of(context).textTheme.bodyText2.color,
            selectedColor: Theme.of(context).textTheme.bodyText2.color,
            onPressed: (index) {
            // Respond to button selection
              setState(() {
                isSelected[0] = !isSelected[0];
                isSelected[1] = !isSelected[1];
                order = -order;
                searchVersesFuture = BibleDbHelper.instance.searchVerses(keyword, order);
              });
            },
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text('Ordre Biblique'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text('Pertinence'),
              )
            ], 
            isSelected: isSelected),
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
                              data[index].bookTitle.toString(),
                              style: TextStyle(color: Theme.of(context).accentColor) 
                              ),
                            Spacer(),
                            Text(data[index].book.toString()+ ' ' + data[index].chapter.toString(),
                            style: TextStyle(color: Theme.of(context).textTheme.bodyText2.color),
                            )
                          ],
                        ),
                        subtitle: Html(data:data[index].text.toString()),
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