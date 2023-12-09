import 'dart:async';

import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/widgets/fr-fr_aelf.json.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/bibleDbHelper.dart';
import 'package:flutter_html/flutter_html.dart';

class BibleSearchScreen extends StatefulWidget {
  static const routeName = '/bibleSearchScreen';
  BibleSearchScreen({Key? key}) : super(key: key);

  @override
  _BibleSearchScreenState createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {

  String keyword = "";
  List? verses;
  Map<String, dynamic> bibleIndex = bibleIndexMap;
  late Future<List<Verse>?> searchVersesFuture;
  final isSelected = <bool>[true, false];
  int order=-1; //-1 = biblique ; 1 = pertinence
  Timer? timer = null;



  @override
  void initState() {
    keyword = '';
    searchVersesFuture = BibleDbHelper.instance.searchVerses(keyword, -1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width < 768 ? MediaQuery.of(context).size.width : 768 ;
    final num toggleMaxWidth = width * 0.95;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Rechercher'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Entrer quelques mots...',
                  border: OutlineInputBorder(),
                  labelText: 'Rechercher un passage de la Bible',
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  labelStyle: Theme.of(context).textTheme.bodyMedium,
                  helperStyle: Theme.of(context).textTheme.bodyMedium,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary))
                ),
                onChanged: (value) {
                  setState(() {
                    keyword = value;
                    if (timer != null) {
                      timer!.cancel();
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
              color: Theme.of(context).textTheme.bodyMedium!.color,
              selectedColor: Theme.of(context).textTheme.bodyMedium!.color,
              fillColor: Theme.of(context).textSelectionTheme.selectionColor,
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
                    List<Verse>? data = <Verse>[];
                    data = snapshot.data as List<Verse>?;
                    if (data!.asMap().length == 0) {
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
                              Expanded(
                                child: Text(
                                  data![index].bookTitle.toString(),
                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary), 
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  ),
                              ),
                              Text(data[index].book.toString()+ ' ' + data[index].chapter.toString(),
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                              )
                            ],
                          ),
                          subtitle: Html(
                            data:data[index].text.toString(),
                            style: {
                              "*": Style(color: Theme.of(context).textTheme.bodyMedium!.color)
                            }
                          ),
                          isThreeLine: false,
                          onTap: () {
                            print('Go to selected verse in Bible');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (contect)=>
                                ExtractArgumentsScreen(
                                  bookNameShort: data![index].book,
                                  bookChToOpen: data[index].chapter,
                                  keywords: keyword.trim().split(RegExp(r"(\s+)")),
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
      ),
    );
  }
} 

class VerseResult extends StatelessWidget {

  final Map data;

  VerseResult(this.data, {Key? key}) : super (key: key);

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