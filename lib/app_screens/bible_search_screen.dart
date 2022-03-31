import 'dart:async';

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
  Timer timer = null;



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
    final width = MediaQuery.of(context).size.width < 768 ? MediaQuery.of(context).size.width : 768 ;
    final toggleMaxWidth = width * 0.95;
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
                  if (timer != null) {
                    timer.cancel();
                  }
                  timer = Timer(Duration(milliseconds: 500), () {
                    searchVersesFuture.ignore();
                    searchVersesFuture = BibleDbHelper.instance.searchVerses(keyword, order);
                  });
                });
              },
            ),
          ),
          ToggleButtons(
            color: Theme.of(context).textTheme.bodyText2.color,
            selectedColor: Theme.of(context).textTheme.bodyText2.color,
            constraints: BoxConstraints.expand(width: toggleMaxWidth / 2, height: 30),
            borderRadius: BorderRadius.circular(4),
            onPressed: (index) {
            // Respond to button selection
              setState(() {
                isSelected[0] = !isSelected[0];
                isSelected[1] = !isSelected[1];
                order = -order;
                searchVersesFuture.ignore();
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
                if (snapshot.hasError) {
                  print('snapshot.haserror ');
                  return Center(
                    child: Text("Erreur: ${snapshot.error.toString()}"),
                  );
                }
                if (!snapshot.hasData && keyword.length > 3) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasData) {
                  var data = snapshot.data;
                  if (data.asMap().length == 0) {
                    return Padding(
                    padding: const EdgeInsets.fromLTRB(4,12,4,4),
                    child: Text('Aucun résultat'),
                  );
                  }
                  return ListView.builder(
                    itemCount: data.asMap().length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Row(
                          children: [
                            //FIXME: When title is long (eg Deuxième Livre
                            //des Martyres d'Israël) it does not fit the widht screen
                            //and there is a display bug.
                            Expanded(
                              child: Text(
                                data[index].bookTitle.toString(),
                                style: TextStyle(color: Theme.of(context).accentColor), 
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                ),
                            ),
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
                  return Container();
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