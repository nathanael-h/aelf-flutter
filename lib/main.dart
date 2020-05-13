import 'dart:async';
import 'package:aelf_flutter/app_screens/about_screen.dart';
import 'package:aelf_flutter/app_screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/chapter_storage.dart';
import 'package:aelf_flutter/app_screens/not_dev_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:aelf_flutter/app_screens/bible_lists_screen.dart';

import 'package:aelf_flutter/app_screens/liturgy_screen.dart';
import 'package:aelf_flutter/datepicker.dart';
import 'package:aelf_flutter/liturgySaver.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:connectivity/connectivity.dart';
import 'package:aelf_flutter/settings.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';



void main() {
  runApp(MyApp(storage: ChapterStorage('assets/bible/gn1.txt')));
}

class MyApp extends StatelessWidget {
  MyApp({Key key, @required this.storage}) : super(key: key);

  // This widget is the root of your application.

  final ChapterStorage storage;

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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('fr', 'FR'),
      ],
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
          scaffoldBackgroundColor: Color.fromRGBO(239, 227, 206, 1.0),
          tabBarTheme: TabBarTheme(
            labelColor: Color.fromRGBO(191, 35, 41, 1.0),
            unselectedLabelColor: Color.fromRGBO(191, 35, 41, 0.4),
          )),
      home: MyHomePage(storage: ChapterStorage('assets/bible/gn1.txt')),
    );
  }
}

// https://flutter.dev/docs/cookbook/lists/mixed-list
// The base class for the different types of items the list can contain.
abstract class ListItem {}

// A ListItem that contains data to display a section.
class SectionItem implements ListItem {
  SectionItem(this.section);

  final String section;
}

Future<Map<String, dynamic>> loadAsset() async {
  return rootBundle
      .loadString('assets/bible/fr-fr_aelf.json')
      .then((jsonStr) => jsonDecode(jsonStr));
}

// A ListItem that contains data to display Bible books list.
class BookItem implements ListItem {
  BookItem(this.bookLong, this.bookShort, this.bookChNbr);

  final int bookChNbr;
  final String bookLong;
  final String bookShort;
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, @required this.storage}) : super(key: key);

  final ChapterStorage storage;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _pageController = PageController();
  String chapter;
  // datepicker
  DatePicker datepicker = new DatePicker();
  String selectedDate, selectedDateMenu;
  bool _datepickerIsVisible = false;
  // value to refresh liturgy
  int liturgyRefresh = 0;

  @override
  void initState() {
    super.initState();
    
    // init network connection to save liturgy elements
    addNetworkListener();

    print("load");
    // init datepicker
    selectedDate = datepicker.getDate();
    selectedDateMenu = datepicker.toShortPrettyString();
  }

  void addNetworkListener() async {
    // add internet listener
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        print("now, have internet");
        //check internet connection and auto save liturgy
        new LiturgySaver();
        setState(() {
          // refresh date selected to refresh screen
          refreshLiturgy();
        });
      } else if (result == ConnectivityResult.none) {
        print("now, not internet connection");
      }
    });
  }

  void refreshLiturgy() {
    liturgyRefresh++;
  }

  void _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    if (choice.title == 'A propos') {
      setState(() {
        About().popUp(context);
      });
    } else {
      setState(
        () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())),
      );
    }
  }

  void _showAboutPopUp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version+packageInfo.buildNumber;
    String lastVersion = prefs.getString(keyLastVersionInstalled);
    if (lastVersion != version) {
      Future.delayed(Duration.zero, () => About().popUp(context));
    }
    prefs.setString(keyLastVersionInstalled, version);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    // Show About Pop Up message when the App is run for the first time.
    _showAboutPopUp();
    //Bible home screen
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30, 32, 36, 1),
        title: Text('AELF'),
        actions: <Widget>[
          Visibility(
            visible: _datepickerIsVisible,
            child: FlatButton(
              textColor: Colors.white,
              onPressed: () {
                datepicker.selectDate(context).then((user) {
                  setState(() {
                    selectedDate = datepicker.getDate();
                    selectedDateMenu = datepicker.toShortPrettyString();
                    refreshLiturgy();
                  });
                });
              },
              child: Text("$selectedDateMenu"),
            ),
          ),
          /**
          IconButton(
            icon: Icon(choices[0].icon),
            onPressed: () => ToDo(choices[0].title).popUp(context),
          ),
          IconButton(
            icon: Icon(choices[1].icon),
            onPressed: () => ToDo(choices[1].title).popUp(context),
          ),
          **/
          PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.skip(0).map((Choice choice) {
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
          LiturgyScreen('messes', "$selectedDate", liturgyRefresh),
          LiturgyScreen('informations', "$selectedDate", liturgyRefresh),
          LiturgyScreen('lectures', "$selectedDate", liturgyRefresh),
          LiturgyScreen('laudes', "$selectedDate", liturgyRefresh),
          LiturgyScreen('tierce', "$selectedDate", liturgyRefresh),
          LiturgyScreen('sexte', "$selectedDate", liturgyRefresh),
          LiturgyScreen('none', "$selectedDate", liturgyRefresh),
          LiturgyScreen('vepres', "$selectedDate", liturgyRefresh),
          LiturgyScreen('complies', "$selectedDate", liturgyRefresh)
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
                setState(() {
                  _datepickerIsVisible = false;
                });
                _pageController.jumpToPage(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Messe'),
              onTap: () {
                setState(() {
                  _datepickerIsVisible = true;
                });
                _pageController.jumpToPage(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Informations'),
              onTap: () {
                setState(() {
                  _datepickerIsVisible = true;
                });
                _pageController.jumpToPage(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Lectures'),
              onTap: () {
                setState(() {
                  _datepickerIsVisible = true;
                });
                _pageController.jumpToPage(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Laudes'),
              onTap: () {
                setState(() {
                  _datepickerIsVisible = true;
                });
                _pageController.jumpToPage(4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Tierce'),
              onTap: () {
                setState(() {
                  _datepickerIsVisible = true;
                });
                _pageController.jumpToPage(5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Sexte'),
              onTap: () {
                setState(() {
                  _datepickerIsVisible = true;
                });
                _pageController.jumpToPage(6);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('None'),
              onTap: () {
                setState(() {
                  _datepickerIsVisible = true;
                });
                _pageController.jumpToPage(7);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Vêpres'),
              onTap: () {
                setState(() {
                  _datepickerIsVisible = true;
                });
                _pageController.jumpToPage(8);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Complies'),
              onTap: () {
                setState(() {
                  _datepickerIsVisible = true;
                });
                _pageController.jumpToPage(9);
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

  final IconData icon;
  final String title;
}

const List<Choice> choices = const <Choice>[
  //const Choice(title: 'Rechercher', icon: Icons.search),
  //const Choice(title: 'Partager', icon: Icons.share),
  //const Choice(title: 'Mode nuit', icon: Icons.directions_boat),
  //const Choice(title: 'Paramètres', icon: Icons.directions_bus),
  //const Choice(title: 'Synchroniser', icon: Icons.directions_railway),
  const Choice(title: 'A propos', icon: Icons.directions_walk),
];
// A Widget that extracts the necessary arguments from the ModalRoute.
