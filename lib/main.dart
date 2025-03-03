import 'dart:async';
import 'dart:developer';
import 'package:aelf_flutter/app_screens/about_screen.dart';
import 'package:aelf_flutter/app_screens/bible_search_screen.dart';
import 'package:aelf_flutter/bibleDbProvider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/pageState.dart';
import 'package:aelf_flutter/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:aelf_flutter/app_screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/chapter_storage.dart';
import 'package:aelf_flutter/app_screens/bible_lists_screen.dart';
import 'package:aelf_flutter/app_screens/liturgy_screen.dart';
import 'package:aelf_flutter/datepicker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:aelf_flutter/settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/material_drawer_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(MyApp(storage: ChapterStorage('assets/bible/gn1.txt')));
  // Initialize FFI
  sqfliteFfiInit();
  // Change the default factory
  databaseFactory = databaseFactoryFfi;
  // Initialize database
  ensureDatabase();
}

class AppSectionItem {
  final String title;
  final String name;
  final bool datePickerVisible;
  final bool searchVisible;

  const AppSectionItem(
      {required this.title,
      required this.name,
      this.datePickerVisible = true,
      this.searchVisible = false});
}

List<AppSectionItem> appSections = [
  AppSectionItem(
      title: "Bible",
      name: "bible",
      datePickerVisible: false,
      searchVisible: true),
  AppSectionItem(title: "Messe", name: "messes"),
  AppSectionItem(title: "Informations", name: "informations"),
  AppSectionItem(title: "Lectures", name: "lectures"),
  AppSectionItem(title: "Laudes", name: "laudes"),
  AppSectionItem(title: "Tierce", name: "tierce"),
  AppSectionItem(title: "Sexte", name: "sexte"),
  AppSectionItem(title: "None", name: "none"),
  AppSectionItem(title: "Vêpres", name: "vepres"),
  AppSectionItem(title: "Complies", name: "complies"),
];

class MyApp extends StatelessWidget {
  MyApp({Key? key, required this.storage}) : super(key: key);

  // This widget is the root of your application.

  final ChapterStorage storage;

  @override
  Widget build(BuildContext context) {
    // Prevent screen to be locked
    if (Theme.of(context).platform != TargetPlatform.linux) {
      WakelockPlus.enable();
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentZoom>(create: (_) => CurrentZoom()),
        ChangeNotifierProvider<LiturgyState>(create: (_) => LiturgyState()),
        ChangeNotifierProvider<PageState>(create: (_) => PageState())
      ],
      child: ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
        child: Consumer<ThemeNotifier>(
          builder: (context, ThemeNotifier notifier, child) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                onGenerateRoute: (settings) {
                  // If you push the PassArguments route
                  if (settings.name == PassArgumentsScreen.routeName) {
                    // Cast the arguments to the correct type: ScreenArguments.
                    final ScreenArguments? args =
                        settings.arguments as ScreenArguments?;

                    // Then, extract the required data from the arguments and
                    // pass the data to the correct screen.
                    return MaterialPageRoute(
                      builder: (context) {
                        return PassArgumentsScreen(
                          title: args!.title,
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
                theme: notifier.darkTheme! ? dark : light,
                // Disable dynamic font size as it is now possible to pinch to zoom
                // source https://stackoverflow.com/a/54489680
                home: MyHomePage(
                    storage: ChapterStorage('assets/bible/gn1.txt')));
          },
        ),
      ),
    );
  }
}

void ensureDatabase() async {
  await BibleDbSqfProvider.instance.ensureDatabase();
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.storage}) : super(key: key);

  final ChapterStorage storage;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _pageController = PageController(initialPage: 1);
  String? chapter;
  String? version;
  // datepicker
  DatePicker datepicker = new DatePicker();
  String? selectedDateMenu;
  String? selectedDate;
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    print("initState called");

    // init version
    _getPackageVersion();

    // check network state
    getNetworkstate();

    // init network connection to save liturgy elements
    addNetworkListener();

    print("load");
    // init datepicker
    //selectedDate = datepicker.getDate();
    //selectedDateMenu = datepicker.toShortPrettyString();
    selectedDate = "${DateTime.now().toLocal()}".split(' ')[0];
    //selectedDateMenu = "${DateTime.now().toLocal()}".split(' ')[0];
    selectedDateMenu = "Aujourd'hui";
    selectedDateTime = DateTime.now();

    _computeCurrentOffice();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getAppSectionFromName(String name) {
    return appSections
        .indexWhere((element) => element.name.toLowerCase() == name.toString());
  }

  Future<void> _computeCurrentOffice() async {
    int currentHour = DateTime.now().hour;
    final bool isSunday = DateTime.now().weekday == DateTime.sunday;
    String sectionName;

    if (currentHour < 3) {
      sectionName = 'complies';
    } else if (currentHour < 4) {
      sectionName = 'lectures';
    } else if (currentHour < 8) {
      sectionName = 'laudes';
    } else if (currentHour < 15 && isSunday) {
      sectionName = 'messes';
    } else if (currentHour < 10) {
      sectionName = 'tierce';
    } else if (currentHour < 13) {
      sectionName = 'sexte';
    } else if (currentHour < 16) {
      sectionName = 'none';
    } else if (currentHour < 21) {
      sectionName = 'vepres';
    } else {
      sectionName = 'complies';
    }

    Future.microtask(() {
      context.read<LiturgyState>().updateLiturgyType(sectionName);
      context
          .read<PageState>()
          .changeActiveAppSection(_getAppSectionFromName(sectionName));
      context.read<PageState>().changeSearchButtonVisibility(
          appSections[_getAppSectionFromName(sectionName)].searchVisible);
      context.read<PageState>().changeDatePickerButtonVisibility(
          appSections[_getAppSectionFromName(sectionName)].datePickerVisible);
      context.read<PageState>().changePageTitle(
          appSections[_getAppSectionFromName(sectionName)].title);
    });
  }

  void getNetworkstate() async {
    var result = await Connectivity().checkConnectivity();
    print("network state = " + result.toString());
    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet) {
      context.read<LiturgyState>().updateLiturgy();
    }
  }

  void addNetworkListener() async {
    // add internet listener
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) async {
      if (result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet)) {
        print("now, have internet");
        //check internet connection and auto save liturgy
        context.read<LiturgyState>().updateLiturgy();
      } else if (result.first == ConnectivityResult.none) {
        print("now, no internet connection");
      }
    });
  }

  _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    if (choice.title == 'A propos') {
      setState(() {
        About(version).popUp(context);
      });
    } else if (choice.title == 'Paramètres') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SettingsMenu()));
    }
  }

  void _getPackageVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version + '.' + packageInfo.buildNumber;
    });
  }

  void _showAboutPopUp() async {
    log('showAboutPopUp called');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastVersion = prefs.getString(keyLastVersionInstalled);
    if (version != null && lastVersion != version) {
      Future.delayed(Duration.zero, () {
        log('showAboutPopUp, yes');
        About(version).popUp(context);
      });
      await prefs.setString(keyLastVersionInstalled, version!);
    }
  }

  void _pushBibleSearchScreen() {
    print('_pushBibleSearchScreen');
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return BibleSearchScreen();
    }));
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
    bool isBigScreen = (MediaQuery.of(context).size.width > 800);
    return Consumer<PageState>(
      builder: (context, pageState, child) => Scaffold(
        appBar: AppBar(
          title: Text(
            pageState.title,
            style: TextStyle(fontFamily: 'LibertinusSans'),
          ),
          actions: <Widget>[
            //Consumer<ThemeNotifier>(
            //  builder: (context, notifier, child) {
            //    return Switch(
            //      value: notifier.darkTheme,
            //      onChanged: (value) {
            //        notifier.toggleTheme();
            //      });
            //  },
            //
            //),
            Visibility(
                visible: pageState.searchVisible,
                child: Tooltip(
                    message: "Rechercher dans la Bible",
                    child: TextButton(
                      onPressed: _pushBibleSearchScreen,
                      child: Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ))),
            Visibility(
              visible: pageState.datePickerVisible,
              child: TextButton(
                onPressed: () {
                  datepicker.selectDate(context).then((user) {
                    // Update date in LiturgyState
                    context
                        .read<LiturgyState>()
                        .updateDate(datepicker.getDate());
                    setState(() {
                      selectedDate = datepicker.getDate();
                      selectedDateMenu = datepicker.toShortPrettyString();
                    });
                  });
                },
                child: Text(
                  selectedDateMenu!,
                  style: TextStyle(color: Colors.white),
                ),
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
              color: Theme.of(context).textTheme.titleLarge!.color,
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              onSelected: _select,
              itemBuilder: (BuildContext context) {
                return choices.skip(0).map((Choice choice) {
                  return PopupMenuItem<Choice>(
                    value: choice,
                    child: Row(
                      children: [
                        Text(
                          choice.title!,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .color),
                        ),
                        Spacer(),
                        choice.widget!,
                      ],
                    ),
                  );
                }).toList();
              },
            )
          ],
        ),
        //body: BibleListsScreen(storage: ChapterStorage('assets/bible/gn1.txt')),
        body: Row(
          children: [
            Visibility(
                // On big screen, there is a permanent Left Menu
                visible: isBigScreen,
                child: Row(
                  children: [
                    // The Left Menu
                    Container(
                      color: Colors.green,
                      width: 250,
                      child: LeftMenu(pageController: _pageController),
                    ),
                    // Vertical decoration on the right of the Left Menu
                    Consumer(
                      builder: (context, ThemeNotifier notifier, child) =>
                          Column(
                        children: [
                          Visibility(
                            visible: !notifier.darkTheme!,
                            child: Container(
                                // The heigth of the TabBar, should not be harcoded...
                                // TODO: get the real value with code
                                // Me migth use the plugin measure_size_builder but
                                // I found no case when the TabBar height is different then 48dp,
                                // thus I'll keep it hard-coded for now.
                                height: 48,
                                width: 1,
                                decoration: BoxDecoration(
                                    border: Border(
                                        right: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 1)))),
                          ),
                          Expanded(
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        right: Divider.createBorderSide(
                                            context)))),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
            Expanded(
              child: PageView(
                controller: _pageController,
                children: <Widget>[
                  BibleListsScreen(
                      storage: ChapterStorage('assets/bible/gn1.txt')),
                  LiturgyScreen(),
                  LiturgyScreen(),
                  LiturgyScreen(),
                  LiturgyScreen(),
                  LiturgyScreen(),
                  LiturgyScreen(),
                  LiturgyScreen(),
                  LiturgyScreen(),
                  LiturgyScreen()
                ],
                physics: NeverScrollableScrollPhysics(),
              ),
            ),
          ],
        ),
        drawer: isBigScreen
            ? null
            : Drawer(
                child: LeftMenu(pageController: _pageController),
              ),
      ),
    );
  }
}

class LeftMenu extends StatelessWidget {
  const LeftMenu({
    Key? key,
    required PageController pageController,
  })  : _pageController = pageController,
        super(key: key);

  final PageController _pageController;

  @override
  Widget build(BuildContext context) {
    return Consumer<PageState>(
      builder: (context, pageState, child) => Container(
        color: Theme.of(context).textTheme.titleLarge!.color,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
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
                          fontFamily: 'LibertinusSans',
                          fontSize: 20.0,
                          fontWeight: FontWeight.normal,
                          color: Colors.white),
                    ),
                  ),
                  /*Text(
                    "punchline",
                    style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.normal,
                        color: Colors.white70),
                  ),*/
                ],
              ),
            ),
            for (var entry in appSections.asMap().entries)
              MaterialDrawerItem(
                listTile: ListTile(
                  title: Text(entry.value.title,
                      style: TextStyle(fontFamily: 'LibertinusSans')),
                  selected: pageState.activeAppSection == entry.key,
                  onTap: () {
                    if (entry.value.name != 'bible') {
                      context
                          .read<LiturgyState>()
                          .updateLiturgyType(entry.value.name);
                    }
                    context.read<PageState>().changeActiveAppSection(entry.key);
                    context.read<PageState>().changeSearchButtonVisibility(
                        entry.value.searchVisible);
                    context.read<PageState>().changeDatePickerButtonVisibility(
                        entry.value.datePickerVisible);
                    context
                        .read<PageState>()
                        .changePageTitle(entry.value.title);
                    _pageController.jumpToPage(entry.key);
                    Scaffold.of(context).hasDrawer
                        ? Scaffold.of(context).closeDrawer()
                        : null;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Choice {
  const Choice({this.title, this.icon, this.widget});

  final IconData? icon;
  final String? title;
  final Widget? widget;
}

List<Choice> choices = <Choice>[
  //const Choice(title: 'Rechercher', icon: Icons.search),
  //const Choice(title: 'Partager', icon: Icons.share),
  //const Choice(title: 'Mode nuit', icon: Icons.directions_boat),
  Choice(
    title: 'Mode nuit',
    icon: Icons.directions_bus,
    widget: Consumer<ThemeNotifier>(
      builder: (context, notifier, child) {
        return Switch(
            value: notifier.darkTheme!,
            onChanged: (value) {
              notifier.toggleTheme();
              Navigator.of(context).pop();
            });
      },
    ),
  ),
  //const Choice(title: 'Synchroniser', icon: Icons.directions_railway),
  Choice(title: 'Paramètres', icon: Icons.directions_walk, widget: Text('')),
  const Choice(
      title: 'A propos', icon: Icons.directions_walk, widget: Text('')),
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
