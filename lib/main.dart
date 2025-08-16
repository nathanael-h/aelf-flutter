import 'package:aelf_flutter/app_screens/aelf_home_page.dart';
import 'package:aelf_flutter/bibleDbProvider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/pageState.dart';
import 'package:aelf_flutter/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/bible_lists_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'widgets/material_drawer_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(MyApp());
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
  MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.

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
                home: AelfHomePage());
          },
        ),
      ),
    );
  }
}

void ensureDatabase() async {
  await BibleDbSqfProvider.instance.ensureDatabase();
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
                  title: Text(entry.value.title,
                      style: Theme.of(context).textTheme.bodyLarge),
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
