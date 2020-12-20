import 'dart:async';
import 'package:aelf_flutter/app_screens/about_screen.dart';
import 'package:aelf_flutter/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:aelf_flutter/creatMaterialColor.dart';
import 'package:aelf_flutter/app_screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/chapter_storage.dart';
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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

import 'widgets/material_drawer_item.dart';

void main() {
  runApp(MyApp(storage: ChapterStorage('assets/bible/gn1.txt')));
}

class AppSectionItem {
  final String title;
  final bool hasDatePicker;

  const AppSectionItem({this.title, this.hasDatePicker = true});
}

List<AppSectionItem> appSections = [
  AppSectionItem(title: "Bible", hasDatePicker: false),
  AppSectionItem(title: "Messe"),
  AppSectionItem(title: "Informations"),
  AppSectionItem(title: "Lectures"),
  AppSectionItem(title: "Laudes"),
  AppSectionItem(title: "Tierce"),
  AppSectionItem(title: "Sexte"),
  AppSectionItem(title: "None"),
  AppSectionItem(title: "Vêpres"),
  AppSectionItem(title: "Complies"),
];

class MyApp extends StatelessWidget {
  MyApp({Key key, @required this.storage}) : super(key: key);

  // This widget is the root of your application.

  final ChapterStorage storage;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, ThemeNotifier notifier, child) {
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
              GlobalCupertinoLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate
            ],
            supportedLocales: [
              const Locale('fr', 'FR'),
            ],
            theme: notifier.darkTheme ? dark : light,
            home: MyHomePage(storage: ChapterStorage('assets/bible/gn1.txt')),
          );
        },
      ),
    );
  }
}

Future<Map<String, dynamic>> loadAsset() async {
  return rootBundle
      .loadString('assets/bible/fr-fr_aelf.json')
      .then((jsonStr) => jsonDecode(jsonStr));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, @required this.storage}) : super(key: key);

  final ChapterStorage storage;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _pageController = PageController(initialPage: 1);
  String chapter;
  String version;
  // datepicker
  DatePicker datepicker = new DatePicker();
  String selectedDateMenu;
  String selectedDate;
  DateTime selectedDateTime;
  
  bool _datepickerIsVisible = true;
  String _title = "Messe";
  int _activeAppSection = 1;
  // value to refresh liturgy
  int liturgyRefresh = 0;

  // region for liturgy
  String liturgyRegion;

  @override
  void initState() {
    super.initState();

    // init version
    _getPackageVersion();

    // init liturgy region, default is romain
    _getRegion();

    // init network connection to save liturgy elements
    addNetworkListener();

    print("load");
    // init datepicker
    //selectedDate = datepicker.getDate();
    //selectedDateMenu = datepicker.toShortPrettyString();
    selectedDate = "${DateTime.now().toLocal()}".split(' ')[0];
    //selectedDateMenu = "${DateTime.now().toLocal()}".split(' ')[0];
    selectedDateMenu = "Ajourd'hui";
    selectedDateTime = DateTime.now();
  }

  void addNetworkListener() async {
    // add internet listener
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        print("now, have internet");
        //check internet connection and auto save liturgy
        String liturgyRegion =
            await Settings().getString(keyPrefRegion, 'romain');
        new LiturgySaver(liturgyRegion);
      } else if (result == ConnectivityResult.none) {
        print("now, no internet connection");
      }
    });
  }

  void _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    if (choice.title == 'A propos') {
      setState(() {
        About(version).popUp(context);
      });
    } else {
      setState(
        () {
          return Navigator.push(
              context, MaterialPageRoute(builder: (context) => SettingsMenu()));
        },
      );
    }
  }

  void _getPackageVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version + '.' + packageInfo.buildNumber;
    });
  }

  void _showAboutPopUp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastVersion = prefs.getString(keyLastVersionInstalled);
    if (lastVersion != version) {
      Future.delayed(Duration.zero, () => About(version).popUp(context));
    }
    prefs.setString(keyLastVersionInstalled, version);
  }

  Future<String> _getRegion() async {
    String region = await Settings().getString(keyPrefRegion, 'romain');
    setState(() {
      liturgyRegion = region;
    });
    return region;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    // Update Region

    // Show About Pop Up message when the App is run for the first time.
    _showAboutPopUp();
    //Bible home screen
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: <Widget>[
          Consumer<ThemeNotifier>(
            builder: (context, notifier, child) {
              return Switch(
                value: notifier.darkTheme, 
                onChanged: (value) {
                  notifier.toggleTheme();
                });
            },
            
          ),
          Visibility(
            visible: _datepickerIsVisible,
            child: FlatButton(
              textColor: Colors.white,
              onPressed: () {
                datepicker.selectDate(context).then((user) {
                  setState(() {
                    selectedDate = datepicker.getDate();
                    selectedDateMenu = datepicker.toShortPrettyString();
                  });
                });
              },
              child: Text(selectedDateMenu),
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
                  child: Row(
                    children: [
                      Text(choice.title),
                      Spacer(),
                      choice.widget,
                    ],
                  ),
                );
              }).toList();
            },
          )
        ],
      ),
      //body: BibleListsScreen(storage: ChapterStorage('assets/bible/gn1.txt')),
      body: FutureBuilder(
        //future: Settings().getString(keyPrefRegion, 'romain'),
        future: _getRegion(),
        builder: (context, regionSnapshot) {
          if (regionSnapshot.hasData) {
            return PageView(
              controller: _pageController,
              children: <Widget>[
                BibleListsScreen(
                    storage: ChapterStorage('assets/bible/gn1.txt')),
                LiturgyScreen(
                    'messes', selectedDate, regionSnapshot.data, liturgyRefresh),
                LiturgyScreen('informations', selectedDate, regionSnapshot.data,
                    liturgyRefresh),
                LiturgyScreen(
                    'lectures', selectedDate, regionSnapshot.data, liturgyRefresh),
                LiturgyScreen(
                    'laudes', selectedDate, regionSnapshot.data, liturgyRefresh),
                LiturgyScreen(
                    'tierce', selectedDate, regionSnapshot.data, liturgyRefresh),
                LiturgyScreen(
                    'sexte', selectedDate, regionSnapshot.data, liturgyRefresh),
                LiturgyScreen(
                    'none', selectedDate, regionSnapshot.data, liturgyRefresh),
                LiturgyScreen(
                    'vepres', selectedDate, regionSnapshot.data, liturgyRefresh),
                LiturgyScreen(
                    'complies', selectedDate, regionSnapshot.data, liturgyRefresh)
              ],
              physics: NeverScrollableScrollPhysics(),
            );
          } else {
            return Center(child: new CircularProgressIndicator());
          }
        },
      ),
      drawer: Drawer(
        child: Container(
          color: Theme.of(context).textTheme.headline6.color,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration:
                    BoxDecoration(color: Theme.of(context).primaryColor),
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
              for (var entry in appSections.asMap().entries)
                MaterialDrawerItem(
                  listTile: ListTile(
                  
                    title: Text(entry.value.title, style: Theme.of(context).textTheme.bodyText1),
                    selected: _activeAppSection == entry.key,
                    onTap: () {
                      setState(() {
                        _datepickerIsVisible = entry.value.hasDatePicker;
                        _title = entry.value.title;
                        _activeAppSection = entry.key;
                      });
                      print('onTap liturgyRegion = ' + liturgyRegion);
                      _pageController.jumpToPage(entry.key);
                      Navigator.pop(context);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Choice {
  const Choice({this.title, this.icon, this.widget});

  final IconData icon;
  final String title;
  final Widget widget;
}

List<Choice> choices = <Choice>[
  //const Choice(title: 'Rechercher', icon: Icons.search),
  //const Choice(title: 'Partager', icon: Icons.share),
  //const Choice(title: 'Mode nuit', icon: Icons.directions_boat),
  Choice(title: 'Paramètres', icon: Icons.directions_bus, widget: 
    Consumer<ThemeNotifier>(
      builder: (context, notifier, child) {
        return Switch(
          value: notifier.darkTheme, 
          onChanged: (value) {
            notifier.toggleTheme();
          });
      },     
    ),
  ),
  //const Choice(title: 'Synchroniser', icon: Icons.directions_railway),
  const Choice(title: 'A propos', icon: Icons.directions_walk, widget: Text('')),
];
// A Widget that extracts the necessary arguments from the ModalRoute.


// Source : https://github.com/flutter/samples/blob/master/provider_counter/lib/main.dart

//class DateProvider with ChangeNotifier {
//  DateTime value = DateTime.now();
//
//  void setDate(DateTime newDate) {
//    value = newDate;
//    notifyListeners();
//  }
// 
//}
//
