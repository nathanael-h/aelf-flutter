import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/chapter_storage.dart';
import 'package:aelf_flutter/app_screens/not_dev_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:aelf_flutter/app_screens/bible_lists_screen.dart';
import 'package:aelf_flutter/app_screens/liturgy_screen.dart';

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

  DateTime selectedDate = DateTime.now();
  String selectedDateMenu = '2020-04-27';
  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2016),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedDateMenu = "${picked.toLocal()}".split(' ')[0];
        // TODO: refresh view
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    //Bible home screen
    return Scaffold(
      appBar: AppBar(
        title: Text('AELF'),
        actions: <Widget>[
          FlatButton(
            textColor: Colors.white,
            onPressed: () => _selectDate(context),
            child: Text("$selectedDateMenu"),
          ),
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
          LiturgyScreen('messes', "$selectedDateMenu"),
          LiturgyScreen('lectures', '2020-04-27'),
          LiturgyScreen('laudes', '2020-04-27'),
          LiturgyScreen('tierce', '2020-04-27'),
          LiturgyScreen('sexte', '2020-04-27'),
          LiturgyScreen('none', '2020-04-27'),
          LiturgyScreen('vepres', '2020-04-27'),
          LiturgyScreen('complies', '2020-04-27')
        ],
        physics: NeverScrollableScrollPhysics(),
      ),
      drawer: Drawer(
        child: ListView(
          //padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration:
                  BoxDecoration(color: Color.fromRGBO(191, 35, 41, 1.0)),
              child: Column(
                children: <Widget>[
                  Image.asset(
                    'assets/icons/ic_launcher_android_round.png',
                    height: 90,
                    width: 90,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      "AELF",
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                  ),
                  /*Text(
                    "punchline",
                    style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70),
                  ),*/
                ],
              ),
            ),
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
                _pageController.jumpToPage(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Lectures'),
              onTap: () {
                _pageController.jumpToPage(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Laudes'),
              onTap: () {
                _pageController.jumpToPage(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Tierce'),
              onTap: () {
                _pageController.jumpToPage(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Sexte'),
              onTap: () {
                _pageController.jumpToPage(5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('None'),
              onTap: () {
                _pageController.jumpToPage(6);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Vêpres'),
              onTap: () {
                _pageController.jumpToPage(7);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Complies'),
              onTap: () {
                _pageController.jumpToPage(8);
                Navigator.pop(context);
              },
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
