import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/chapter_storage.dart';
import 'package:aelf_flutter/app_screens/not_dev_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

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
        scaffoldBackgroundColor: Color.fromRGBO(239, 227, 206, 1.0)
        
      ),
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
  return rootBundle.loadString('assets/bible/fr-fr_aelf.json')
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
  List listOldTestamentBooks = [
    //SectionItem("Pentateuque"),
    //BookItem("La Génèse", "Gn"),
    SectionItem("Pentateuque"),
    BookItem("La Genèse", "Gn", 50),
    BookItem("L'Exode", "Ex",40),
    BookItem("Le Lévitique", "Lv",27),
    BookItem("Les Nombres", "Nb",36),
    BookItem("Le Deutéronome", "Dt",34),
    SectionItem("Livres Historiques"),
    BookItem("Le Livre de Josué", "Jos",24),
    BookItem("Le Livre des Juges", "Jg",21),
    BookItem("Le Livre de Ruth", "Rt",4),
    BookItem("Premier Livre de Samuel", "1S",31),
    BookItem("Deuxième Livre de Samuel", "2S",24),
    BookItem("Premier Livre des Rois", "1R",22),
    BookItem("Deuxième Livre des Rois", "2R",25),
    BookItem("Premier Livre des Chroniques", "1Ch",29),
    BookItem("Deuxième Livre des Chroniques", "2Ch",36),
    BookItem("Le Livre d'Esdras", "Esd",10),
    BookItem("Le Livre de Néhémie", "Ne",13),
    BookItem("Tobie", "Tb",14),
    BookItem("Judith", "Jdt",16),
    BookItem("Esther", "Est",11),
    BookItem("Premier Livre des Martyrs d'Israël", "1M",16),
    BookItem("Deuxième Livre des Martyrs d'Israël", "2M",15),
    SectionItem("Livres Poètiques et Sapientiaux"),
    BookItem("Job", "Jb",42),
    BookItem("Les Proverbes", "Pr",31),
    BookItem("L'Écclésiaste (Qohélet)", "Qo",12),
    BookItem("Le Cantique des Cantiques", "Ct",8),
    BookItem("Le Livre de la Sagesse", "Sg",19),
    BookItem("L'Écclésiastique (Siracide)", "Si",52),
    SectionItem("Livres Prophètiques"),
    BookItem("Isaïe", "Is",66),
    BookItem("Jérémie", "Jr",52),
    BookItem("Les Lamentations", "Lm",5),
    BookItem("Baruch", "Ba",5),
    BookItem("Lettre de Jérémie", "1Jr",1),
    BookItem("Ézéchiel", "Ez",48),
    BookItem("Daniel", "Dn",14),
    BookItem("Osée", "Os",14),
    BookItem("Joël", "Jl",4),
    BookItem("Amos", "Am",9),
    BookItem("Abdias", "Ab",1),
    BookItem("Jonas", "Jon",4),
    BookItem("Michée", "Mi",7),
    BookItem("Nahum", "Na",3),
    BookItem("Habaquq", "Ha",3),
    BookItem("Sophonie", "So",3),
    BookItem("Aggée", "Ag",2),
    BookItem("Zacharie", "Za",14),
    BookItem("Malachie", "Ml",3),
  ];
  List listNewTestamentBooks = [
    SectionItem("Évangiles"),
    BookItem("Évangile selon Saint Matthieu", "Mt",28),
    BookItem("Évangile selon Saint Marc", "Mc",16),
    BookItem("Évangile selon Saint Luc", "Lc",24),
    BookItem("Évangile selon Saint Jean", "Jn",21),
    SectionItem("Actes"),
    BookItem("Les Actes des Apôtres", "Ap",22),
    SectionItem("Épitres de Saint Paul"),
    BookItem("Aux Romains", "Rm",16),
    BookItem("Première aux Corinthiens", "1Co",16),
    BookItem("Deuxième aux Corinthiens", "2Co",13),
    BookItem("Aux Galates", "Ga",6),
    BookItem("Aux Éphésiens", "Ep",6),
    BookItem("Aux Philippiens", "Ph",4),
    BookItem("Aux Colossiens", "Col",4),
    BookItem("Première aux Théssaloniciens", "1Th",4),
    BookItem("Deuxième aux Théssaloniciens", "2Th",3),
    BookItem("Première à Timothée", "1Tm",6),
    BookItem("Deuxième à Timothée", "2Tm",4),
    BookItem("À Tite", "Tt",3),
    BookItem("À Philémon", "Phm",1),
    SectionItem("Épîtres Catholiques"),
    BookItem("Épître aux Hébreux", "He",13),
    BookItem("Épître de Saint Jacques", "Jc",5),
    BookItem("Premier Épître de Saint Pierre", "1P",5),
    BookItem("Deuxième Épître de Saint Pierre", "2P",3),
    BookItem("Premier Épître de Saint Jean", "1Jn",5),
    BookItem("Deuxième Épître de Saint Jean", "2Jn",1),
    BookItem("Troisième Épître de Saint Jean", "3Jn",1),
    BookItem("Épître de Saint Jude", "Jude",1),
    SectionItem("Apocalypse"),
    BookItem("L'Apocalypse", "Ap",22),
  ];

  List listPsalms = [];
  Map<String, dynamic> bibleIndex;

  @override
  void initState() {
    super.initState();
    widget.storage.loadAsset().then((String text) {
      setState(() {
        chapter = text;
      });
    });
    listPsalms.addAll(
        List.generate(151,(counter) => "Psaume $counter")
    ); 
    listPsalms.insertAll(
      listPsalms.indexOf("Psaume 113"), 
      ["Psaume 113A", "Psaume 113B"]);
    listPsalms.insertAll(
      listPsalms.indexOf("Psaume 9"), 
      ["Psaume 9A", "Psaume 9B"]);
    listPsalms.remove("Psaume 0");
    listPsalms.remove("Psaume 9");
    listPsalms.remove("Psaume 113");
  }

  void _select(Choice choice) {
  // Causes the app to rebuild with the new _selectedChoice.
  setState(() => ToDo(choice.title).popUp(context),);
}




  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    //Load the Bible map from json file
    loadAsset().then((_bibleIndex){setState(() {
    bibleIndex = _bibleIndex;
    });});
    //Bible home screen
    return Scaffold(
      appBar: AppBar(
        title: Text('AELF'),
        actions: <Widget>[
          IconButton(icon: Icon(choices[0].icon), onPressed: () => ToDo(choices[0].title).popUp(context),),
          IconButton(icon: Icon(choices[1].icon), onPressed: () => ToDo(choices[1].title).popUp(context),),
          PopupMenuButton<Choice>(
            onSelected: _select,
            itemBuilder: (BuildContext context) {
              return choices.skip(2).map((Choice choice){
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
            )
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: TabBar(
            labelColor: Color.fromRGBO(191, 35, 41, 1.0),
            unselectedLabelColor: Color.fromRGBO(191, 35, 41, 0.4),
            tabs: [
              Tab(child: Text('Ancien \nTestament', textAlign: TextAlign.center,),),
              Tab(child: Text('Psaumes', textAlign: TextAlign.center,),),
              Tab(child: Text('Nouveau \nTestament', textAlign: TextAlign.center,),),
            ],
          ),
          body: new TabBarView(
            children: [
              Tab(
                child: ListView.builder(
                  itemCount: listOldTestamentBooks.length,
                  itemBuilder: (context, index) {
                    final item = listOldTestamentBooks[index];
                    if (item is BookItem) {
                      return ListTile(
                        title: Text(item.bookLong),
                        onTap: () {
                          print('index is' + '$index');
                          print('tapped on + $item.bookShort');
                          // When the user taps the button, navigate to the specific route
                          // and provide the arguments as part of the RouteSettings.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExtractArgumentsScreen(
                                storage: ChapterStorage('assets/bible/' +
                                    item.bookShort +
                                    '/1.html'),
                                bookName: item.bookLong,
                                bookNameShort: item.bookShort,
                                bookChNbr: bibleIndex[item.bookShort]['chapters'].length,
                                bookChToOpen: 0,
                                bookChStrings: bibleIndex[item.bookShort]['chapters']
                              ),
                              // Pass the arguments as part of the RouteSettings. The
                              // ExtractArgumentScreen reads the arguments from these
                              // settings.
                              settings: RouteSettings(
                                arguments: ScreenArguments(
                                  'Extract Arguments Screen',
                                  'This message is extracted in the build method.',
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else if (item is SectionItem) {
                      return ListTile(
                        title: Text(
                          item.section,
                          style: Theme.of(context).textTheme.headline,
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              Tab(
                child: GridView.builder(
                  itemCount: listPsalms.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                  itemBuilder: (context, index) {
                    final item = listPsalms[index];
                    return ListTile(
                      title: Center(child: Text(item, textAlign: TextAlign.center,)),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => ExtractArgumentsScreen(
                              storage: ChapterStorage('assets/bible/Ps/'
                              + item.substring(7) +
                              '.html'),
                              bookName: 'Psaumes',
                              bookNameShort: 'Ps',
                              bookChNbr: bibleIndex['Ps']['chapters'].length,
                              bookChToOpen: index,
                              bookChStrings: bibleIndex['Ps']['chapters']
                            ),
                          )
                          );
                      },
                      );
                  },
                ),
              ),
              Tab(
                child: ListView.builder(
                  itemCount: listNewTestamentBooks.length,
                  itemBuilder: (context, index) {
                    final item = listNewTestamentBooks[index];
                    if (item is BookItem) {
                      return ListTile(
                        title: Text(item.bookLong),
                        onTap: () {
                          // When the user taps the button, navigate to the specific route
                          // and provide the arguments as part of the RouteSettings.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExtractArgumentsScreen(
                                storage: ChapterStorage('assets/bible/' +
                                    item.bookShort +
                                    '/1.html'),
                                bookName: item.bookLong,
                                bookNameShort: item.bookShort,
                                bookChNbr: bibleIndex[item.bookShort]['chapters'].length,
                                bookChToOpen: 0,
                                bookChStrings: bibleIndex[item.bookShort]['chapters']
                              ),
                              // Pass the arguments as part of the RouteSettings. The
                              // ExtractArgumentScreen reads the arguments from these
                              // settings.
                              settings: RouteSettings(
                                arguments: ScreenArguments(
                                  'Extract Arguments Screen',
                                  'This message is extracted in the build method.',
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else if (item is SectionItem) {
                      return ListTile(
                        title: Text(
                          item.section,
                          style: Theme.of(context).textTheme.headline,
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ], // Children
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          //padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              title: Text('Bible'),
            ),
            ListTile(title: Text('Messe'), onTap: () => ToDo('Messe').popUp(context),),
            ListTile(title: Text('Lectures'), onTap: () => ToDo('Lectures').popUp(context),),
            ListTile(title: Text('Laudes'), onTap: () => ToDo('Laudes').popUp(context),),
            ListTile(title: Text('Tierce'), onTap: () => ToDo('Tierce').popUp(context),),
            ListTile(title: Text('Sexte'), onTap: () => ToDo('Sexte').popUp(context),),
            ListTile(title: Text('None'), onTap: () => ToDo('None').popUp(context),),
            ListTile(title: Text('Vêpres'), onTap: () => ToDo('Vêpres').popUp(context),),
            ListTile(title: Text('Complies'), onTap: () => ToDo('Complies').popUp(context),),
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

// A Widget that accepts the necessary arguments via the constructor.
class PassArgumentsScreen extends StatelessWidget {
  static const routeName = '/passArguments';

  final String title;
  final String message;

  // This Widget accepts the arguments as constructor parameters. It does not
  // extract the arguments from the ModalRoute.
  //
  // The arguments are extracted by the onGenerateRoute function provided to the
  // MaterialApp widget.
  const PassArgumentsScreen({
    Key key,
    @required this.title,
    @required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}

// You can pass any object to the arguments parameter. In this example,
// create a class that contains both a customizable title and message.
class ScreenArguments {
  final String title;
  final String message;

  ScreenArguments(this.title, this.message);
}
