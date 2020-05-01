import 'dart:async';
import 'package:aelf_flutter/app_screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/chapter_storage.dart';
import 'package:aelf_flutter/app_screens/not_dev_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:aelf_flutter/app_screens/bible_lists_screen.dart';
import 'package:aelf_flutter/settings.dart';

void main() {
  runApp(MyApp(storage: ChapterStorage('assets/bible/gn1.txt')));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  final ChapterStorage storage;
  MyApp({Key key, @required this.storage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        // If you push the PassArguments route
        if (settings.name == PassArgumentsScreen.routeName) {
          // Cast the arguments to the correct type: ScreenArguments.
          final ScreenArguments args = settings.arguments;

          // Then, extract the required data from the arguments and
          // pass the data to the correct screen.
          return MaterialPageRoute(
            builder: (context) {
              return PassArgumentsScreen(
                title: args.title,
                message: args.message,
              );
            },
          );
        }
        return null;
      },
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a red toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          primaryColor: Color.fromRGBO(191, 35, 41, 1.0),
          accentColor: Color.fromRGBO(191, 35, 41, 0.7),
          backgroundColor: Color.fromRGBO(239, 227, 206, 1.0),
          scaffoldBackgroundColor: Color.fromRGBO(239, 227, 206, 1.0)),
      home: MyHomePage(storage: ChapterStorage('assets/bible/gn1.txt')),
    );
  }
}

// https://flutter.dev/docs/cookbook/lists/mixed-list
// The base class for the different types of items the list can contain.
abstract class ListItem {}

// A ListItem that contains data to display a section.
class SectionItem implements ListItem {
  final String section;

  SectionItem(this.section);
}

Future<Map<String, dynamic>> loadAsset() async {
  return rootBundle
      .loadString('assets/bible/fr-fr_aelf.json')
      .then((jsonStr) => jsonDecode(jsonStr));
}

// A ListItem that contains data to display Bible books list.
class BookItem implements ListItem {
  final String bookLong;
  final String bookShort;
  final int bookChNbr;

  BookItem(this.bookLong, this.bookShort, this.bookChNbr);
}

class MyHomePage extends StatefulWidget {
  final ChapterStorage storage;
  MyHomePage({Key key, @required this.storage}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String chapter;
  void _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(
      () => ToDo(choice.title).popUp(context),
    );
  }

  final _pageController = PageController();

  _welcomeMessage() {
    
    return FutureBuilder<dynamic>(
            future: getVisitedFlag(),
            builder: (context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data.toString());
              } else {
                return Text('waiting');
              }
            },
            );
        
  }

  void _showAboutPopUp () {
    Future.delayed(Duration.zero, () => About().popUp(context));
  }
  
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    // Show About Pop Up message. TODO: Add a check if the message has been already presented
    // TODO: 
    _showAboutPopUp();
    //Bible home screen
    return Scaffold(
      appBar: AppBar(
        title: Text('AELF'),
        actions: <Widget>[
          IconButton(
            icon: Icon(choices[0].icon),
            onPressed: () => ToDo(choices[0].title).popUp(context),
          ),
          IconButton(
            icon: Icon(choices[1].icon),
            onPressed: () => ToDo(choices[1].title).popUp(context),
          ),
          PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.skip(2).map((Choice choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
          )
        ],
      ),
      //body: BibleListsScreen(storage: ChapterStorage('assets/bible/gn1.txt')),
      body: PageView(
        controller: _pageController,
        children: <Widget>[
          BibleListsScreen(storage: ChapterStorage('assets/bible/gn1.txt')),
          Center(child: Text('Afficher ici la messe'))
        ],
        physics: NeverScrollableScrollPhysics(),
      ),
      drawer: Drawer(
        child: ListView(
          //padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              title: Text('Bible'),
              onTap: () {
                _pageController.jumpToPage(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Messe'),
              onTap: () {
                //print("onTap Messe");
                _pageController.jumpToPage(1);
                Navigator.pop(context);
                ToDo('Messe').popUp(context);
              },
            ),
            ListTile(
              title: Text('Lectures'),
              onTap: () => ToDo('Lectures').popUp(context),
            ),
            ListTile(
              title: Text('Laudes'),
              onTap: () => ToDo('Laudes').popUp(context),
            ),
            ListTile(
              title: Text('Tierce'),
              onTap: () => ToDo('Tierce').popUp(context),
            ),
            ListTile(
              title: Text('Sexte'),
              onTap: () => ToDo('Sexte').popUp(context),
            ),
            ListTile(
              title: Text('None'),
              onTap: () => ToDo('None').popUp(context),
            ),
            ListTile(
              title: Text('Vêpres'),
              onTap: () => ToDo('Vêpres').popUp(context),
            ),
            ListTile(
              title: Text('Complies'),
              onTap: () => ToDo('Complies').popUp(context),
            ),
          ],
        ),
      ),
    );
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Rechercher', icon: Icons.search),
  const Choice(title: 'Partager', icon: Icons.share),
  const Choice(title: 'Mode nuit', icon: Icons.directions_boat),
  const Choice(title: 'Paramètres', icon: Icons.directions_bus),
  const Choice(title: 'Synchroniser', icon: Icons.directions_railway),
  const Choice(title: 'A propos', icon: Icons.directions_walk),
];
// A Widget that extracts the necessary arguments from the ModalRoute.
