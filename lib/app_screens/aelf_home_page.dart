import 'dart:async';
import 'dart:developer';
import 'package:aelf_flutter/app_screens/about_screen.dart';
import 'package:aelf_flutter/app_screens/bible_lists_screen.dart';
import 'package:aelf_flutter/app_screens/bible_search_screen.dart';
import 'package:aelf_flutter/app_screens/liturgy_screen.dart';
import 'package:aelf_flutter/app_screens/settings_screen.dart';
import 'package:aelf_flutter/data/app_sections.dart';
import 'package:aelf_flutter/data/popup_menu_choices.dart';
import 'package:aelf_flutter/utils/datepicker.dart';
import 'package:aelf_flutter/models/popup_menu_choice.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/pageState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/left_menu.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AelfHomePage extends StatefulWidget {
  AelfHomePage({Key? key}) : super(key: key);

  @override
  AelfHomePageState createState() => AelfHomePageState();
}

class AelfHomePageState extends State<AelfHomePage> {
  final _pageController = PageController(initialPage: 1);
  String? chapter;
  String? version;
  // datepicker
  DatePicker datepicker = DatePicker();
  String? selectedDateMenu;
  String? selectedDate;
  DateTime? selectedDateTime;
  Timer? _timer;

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

    _timer = Timer.periodic(Duration(minutes: 1), (Timer t) => _updateDate());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _updateDate() {
    final newDate = DateTime.now();
    if (newDate.day != selectedDateTime!.day) {
      setState(() {
        selectedDateMenu = datepicker.toShortPrettyString();
      });
    }
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
    print("network state = $result");
    if (result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet)) {
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

  void _select(PopupMenuChoice choice) {
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
      version = '${packageInfo.version}.${packageInfo.buildNumber}';
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
          title: Text(pageState.title),
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
            PopupMenuButton<PopupMenuChoice>(
              color: Theme.of(context).textTheme.titleLarge!.color,
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              onSelected: _select,
              itemBuilder: (BuildContext context) {
                return popupMenuChoices.skip(0).map((PopupMenuChoice choice) {
                  return PopupMenuItem<PopupMenuChoice>(
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
                  BibleListsScreen(),
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
