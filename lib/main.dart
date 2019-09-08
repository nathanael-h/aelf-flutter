import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/chapter_storage.dart';

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
        primarySwatch: Colors.red,
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

// A ListItem that contains data to display Bible books list.
class BookItem implements ListItem {
  final String bookLong;
  final String bookShort;

  BookItem(this.bookLong, this.bookShort);
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
    BookItem("La Genèse", "Gn"),
    BookItem("L'Exode", "Ex"),
    BookItem("Le Lévitique", "Lv"),
    BookItem("Les Nombres", "Nb"),
    BookItem("Le Deutéronome", "Dt"),
    SectionItem("Livres Historiques"),
    BookItem("Le Livre de Josué", "Jos"),
    BookItem("Le Livre des Juges", "Jg"),
    BookItem("Le Livre de Ruth", "Rt"),
    BookItem("Premier Livre de Samuel", "1S"),
    BookItem("Deuxième Livre de Samuel", "2S"),
    BookItem("Premier Livre des Rois", "1R"),
    BookItem("Deuxième Livre des Rois", "2R"),
    BookItem("Premier Livre des Chroniques", "1Ch"),
    BookItem("Deuxième Livre des Chroniques", "2Ch"),
    BookItem("Le Livre d'Esdras", "Esd"),
    BookItem("Le Livre de Néhémie", "Ne"),
    BookItem("Tobie", "Tb"),
    BookItem("Judith", "Jdt"),
    BookItem("Esther", "Est"),
    BookItem("Premier Livre des Martyrs d'Israël", "1M"),
    BookItem("Deuxième Livre des Martyrs d'Israël", "2M"),
    SectionItem("Livres Poètiques et Sapientiaux"),
    BookItem("Job", "Jb"),
    BookItem("Les Proverbes", "Pr"),
    BookItem("L'Écclésiaste (Qohélet)", "Qo"),
    BookItem("Le Cantique des Cantiques", "Ct"),
    BookItem("Le Livre de la Sagesse", "Sg"),
    BookItem("L'Écclésiastique (Siracide)", "Si"),
    SectionItem("Livres Prophètiques"),
    BookItem("Isaïe", "Is"),
    BookItem("Jérémie", "Jr"),
    BookItem("Les Lamentations", "Lm"),
    BookItem("Baruch", "Ba"),
    BookItem("Lettre de Jérémie", "1Jr"),
    BookItem("Ézéchiel", "Ez"),
    BookItem("Daniel", "Dn"),
    BookItem("Osée", "Os"),
    BookItem("Joël", "Jl"),
    BookItem("Amos", "Am"),
    BookItem("Abdias", "Ab"),
    BookItem("Jonas", "Jon"),
    BookItem("Michée", "Mi"),
    BookItem("Nahum", "Na"),
    BookItem("Habaquq", "Ha"),
    BookItem("Sophonie", "So"),
    BookItem("Aggée", "Ag"),
    BookItem("Zacharie", "Za"),
    BookItem("Malachie", "Ml"),
  ];
  List listNewTestamentBooks = [
    SectionItem("Évangiles"),
    BookItem("Évangile selon Saint Matthieu", "Mt"),
    BookItem("Évangile selon Saint Marc", "Mc"),
    BookItem("Évangile selon Saint Luc", "Lc"),
    BookItem("Évangile selon Saint Jean", "Jn"),
    SectionItem("Actes"),
    BookItem("Les Actes des Apôtres", "Ap"),
    SectionItem("Épitres de Saint Paul"),
    BookItem("Aux Romains", "Rm"),
    BookItem("Première aux Corinthiens", "1Co"),
    BookItem("Deuxième aux Corinthiens", "2Co"),
    BookItem("Aux Galates", "Ga"),
    BookItem("Aux Éphésiens", "Ep"),
    BookItem("Aux Philippiens", "Ph"),
    BookItem("Aux Colossiens", "Col"),
    BookItem("Première aux Théssaloniciens", "1Th"),
    BookItem("Deuxième aux Théssaloniciens", "2Th"),
    BookItem("Première à Timothée", "1Tm"),
    BookItem("Deuxième à Timothée", "2Tm"),
    BookItem("À Tite", "Tt"),
    BookItem("À Philémon", "Phm"),
    SectionItem("Épîtres Catholiques"),
    BookItem("Épître aux Hébreux", "He"),
    BookItem("Épître de Saint Jacques", "Jc"),
    BookItem("Premier Épître de Saint Pierre", "1P"),
    BookItem("Deuxième Épître de Saint Pierre", "2P"),
    BookItem("Premier Épître de Saint Jean", "1Jn"),
    BookItem("Deuxième Épître de Saint Jean", "2Jn"),
    BookItem("Troisième Épître de Saint Jean", "3Jn"),
    BookItem("Épître de Saint Jude", "Jude"),
    SectionItem("Apocalypse"),
    BookItem("L'Apocalypse", "Ap"),
  ];

  List listPsalms = [];
  
  

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
        title: Text('AELF Flutter'),
      ),
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: TabBar(
            labelColor: Colors.red,
            unselectedLabelColor: Colors.red[100],
            tabs: [
              Tab(text: 'Ancien \nTestament'),
              Tab(text: 'Psaumes'),
              Tab(text: 'Nouveau \nTestament'),
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
                      title: Center(child: Text(item)),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => ExtractArgumentsScreen(
                              storage: ChapterStorage('assets/bible/Ps/'
                              + item.substring(7) +
                              '.html'),
                              bookName: item,
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
          ],
        ),
      ),
    );
  }
}

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
