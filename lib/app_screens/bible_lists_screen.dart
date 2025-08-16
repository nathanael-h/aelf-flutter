import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/widgets/fr-fr_aelf.json.dart';
import 'package:flutter/material.dart';

// https://flutter.dev/docs/cookbook/lists/mixed-list
// The base class for the different types of items the list can contain.
abstract class ListItem {}

// A ListItem that contains data to display a section.
class SectionItem implements ListItem {
  SectionItem(this.section);

  final String section;
}

// A ListItem that contains data to display Bible books list.
class BookItem implements ListItem {
  BookItem(this.bookLong, this.bookShort, this.bookChNbr);

  final int bookChNbr;
  final String bookLong;
  final String bookShort;
}

class BibleListsScreen extends StatefulWidget {
  BibleListsScreen({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  BibleListsScreenState createState() => BibleListsScreenState();
}

class BibleListsScreenState extends State<BibleListsScreen> {
  List listOldTestamentBooks = [
    //SectionItem("Pentateuque"),
    //BookItem("La Génèse", "Gn"),
    SectionItem("Pentateuque"),
    BookItem("Livre de la Genèse", "Gn", 50),
    BookItem("Livre de l'Exode", "Ex", 40),
    BookItem("Livre du Lévitique", "Lv", 27),
    BookItem("Livre des Nombres", "Nb", 36),
    BookItem("Livre du Deutéronome", "Dt", 34),
    SectionItem("Livres Historiques"),
    BookItem("Livre de Josué", "Jos", 24),
    BookItem("Livre des Juges", "Jg", 21),
    BookItem("Livre de Ruth", "Rt", 4),
    BookItem("Premier livre de Samuel", "1S", 31),
    BookItem("Deuxième livre de Samuel", "2S", 24),
    BookItem("Premier livre des Rois", "1R", 22),
    BookItem("Deuxième livre des Rois", "2R", 25),
    BookItem("Premier livre des Chroniques", "1Ch", 29),
    BookItem("Deuxième livre des Chroniques", "2Ch", 36),
    BookItem("Livre d'Esdras", "Esd", 10),
    BookItem("Livre de Néhémie", "Ne", 13),
    BookItem("Livre de Tobie", "Tb", 14),
    BookItem("Livre de Judith", "Jdt", 16),
    BookItem("Livre d'Esther", "Est", 11),
    BookItem("Premier livre des Martyrs d'Israël", "1M", 16),
    BookItem("Deuxième livre des Martyrs d'Israël", "2M", 15),
    SectionItem("Livres poétiques et sapientiaux"),
    BookItem("Livre de Job", "Jb", 42),
    BookItem("Livre des Proverbes", "Pr", 31),
    BookItem("Livre de l'Écclésiaste (ou Qohèlet)", "Qo", 12),
    BookItem("Cantique des Cantiques", "Ct", 8),
    BookItem("Livre de la Sagesse", "Sg", 19),
    BookItem("Livre de Ben Sira (ou Ecclésiastique)", "Si", 52),
    SectionItem("Livres Prophétiques"),
    BookItem("Livre d'Isaïe", "Is", 66),
    BookItem("Livre de Jérémie", "Jr", 52),
    BookItem("Livre des Lamentations", "Lm", 5),
    BookItem("Livre de Baruch", "Ba", 5),
    BookItem("Lettre de Jérémie", "1Jr", 1),
    BookItem("Livre d'Ézékiel", "Ez", 48),
    BookItem("Livre de Daniel", "Dn", 14),
    BookItem("Livre d'Osée", "Os", 14),
    BookItem("Livre de Joël", "Jl", 4),
    BookItem("Livre d'Amos", "Am", 9),
    BookItem("Livre d'Abdias", "Ab", 1),
    BookItem("Livre de Jonas", "Jon", 4),
    BookItem("Livre de Michée", "Mi", 7),
    BookItem("Livre de Nahoum", "Na", 3),
    BookItem("Livre d'Habacuc", "Ha", 3),
    BookItem("Livre de Sophonie", "So", 3),
    BookItem("Livre d'Aggée", "Ag", 2),
    BookItem("Livre de Zacharie", "Za", 14),
    BookItem("Livre de Malachie", "Ml", 3),
  ];
  List listNewTestamentBooks = [
    SectionItem("Évangiles"),
    BookItem("Évangile selon saint Matthieu", "Mt", 28),
    BookItem("Évangile selon saint Marc", "Mc", 16),
    BookItem("Évangile selon saint Luc", "Lc", 24),
    BookItem("Évangile selon saint Jean", "Jn", 21),
    SectionItem("Actes"),
    BookItem("Actes des Apôtres", "Ac", 22),
    SectionItem("Lettres de saint Paul"),
    BookItem("Lettre aux Romains", "Rm", 16),
    BookItem("Première lettre aux Corinthiens", "1Co", 16),
    BookItem("Deuxième lettre aux Corinthiens", "2Co", 13),
    BookItem("Lettre aux Galates", "Ga", 6),
    BookItem("Lettre aux Éphésiens", "Ep", 6),
    BookItem("Lettre aux Philippiens", "Ph", 4),
    BookItem("Lettre aux Colossiens", "Col", 4),
    BookItem("Première lettre aux Thessaloniciens", "1Th", 4),
    BookItem("Deuxième lettre aux Thessaloniciens", "2Th", 3),
    BookItem("Première lettre à Timothée", "1Tm", 6),
    BookItem("Deuxième lettre à Timothée", "2Tm", 4),
    BookItem("Lettre à Tite", "Tt", 3),
    BookItem("Lettre à Philémon", "Phm", 1),
    BookItem("Lettre aux Hébreux", "He", 13),
    SectionItem("Lettres catholiques"),
    BookItem("Lettre de saint Jacques", "Jc", 5),
    BookItem("Première lettre de saint Pierre", "1P", 5),
    BookItem("Deuxième lettre de saint Pierre", "2P", 3),
    BookItem("Première lettre de saint Jean", "1Jn", 5),
    BookItem("Deuxième lettre de saint Jean", "2Jn", 1),
    BookItem("Troisième lettre de saint Jean", "3Jn", 1),
    BookItem("Lettre de saint Jude", "Jude", 1),
    SectionItem("Apocalypse"),
    BookItem("Apocalypse", "Ap", 22),
  ];

  List listPsalms = [];
  Map<String, dynamic> bibleIndex = bibleIndexMap;

  @override
  void initState() {
    super.initState();
    listPsalms.addAll(List.generate(151, (counter) => "Psaume $counter"));
    listPsalms.insertAll(
        listPsalms.indexOf("Psaume 113"), ["Psaume 113A", "Psaume 113B"]);
    listPsalms
        .insertAll(listPsalms.indexOf("Psaume 9"), ["Psaume 9A", "Psaume 9B"]);
    listPsalms.remove("Psaume 0");
    listPsalms.remove("Psaume 9");
    listPsalms.remove("Psaume 113");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Container(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                indicatorColor: Theme.of(context).tabBarTheme.labelColor,
                labelColor: Theme.of(context).tabBarTheme.labelColor,
                unselectedLabelColor:
                    Theme.of(context).tabBarTheme.unselectedLabelColor,
                tabs: [
                  Tab(
                    child: Text(
                      'Ancien \nTestament',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Psaumes',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Nouveau \nTestament',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Tab(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 600,
                        child: ListView.builder(
                          itemCount: listOldTestamentBooks.length,
                          itemBuilder: (context, index) {
                            final item = listOldTestamentBooks[index];
                            if (item is BookItem) {
                              return Container(
                                margin: const EdgeInsets.only(
                                    left: 20, right: 20, top: 0),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color:
                                                Theme.of(context).dividerColor,
                                            width: 0))),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 0),
                                  title: Text(item.bookLong,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge),
                                  onTap: () {
                                    //print('index is' + '$index');
                                    //print('tapped on + $item.bookShort');
                                    // When the user taps the button, navigate to the specific route
                                    // and provide the arguments as part of the RouteSettings.
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExtractArgumentsScreen(
                                          bookNameShort: item.bookShort,
                                          bookChToOpen: "0",
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
                                ),
                              );
                            } else if (item is SectionItem) {
                              return Container(
                                margin:
                                    const EdgeInsets.only(left: 25, right: 25),
                                child: ListTile(
                                  contentPadding:
                                      EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  title: Text(
                                    item.section,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 600,
                        child: ListView.builder(
                          itemCount: listPsalms.length,
                          itemBuilder: (context, index) {
                            final item = listPsalms[index];
                            return Container(
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 0),
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Theme.of(context).dividerColor,
                                          width: 0))),
                              child: ListTile(
                                title: Text(item,
                                    textAlign: TextAlign.left,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExtractArgumentsScreen(
                                          bookNameShort: 'Ps',
                                          bookChToOpen: item.split(' ')[1],
                                        ),
                                      ));
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 600,
                        child: ListView.builder(
                          itemCount: listNewTestamentBooks.length,
                          itemBuilder: (context, index) {
                            final item = listNewTestamentBooks[index];
                            if (item is BookItem) {
                              return Container(
                                margin: const EdgeInsets.only(
                                    left: 20, right: 20, top: 0),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color:
                                                Theme.of(context).dividerColor,
                                            width: 0))),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 0),
                                  title: Text(
                                    item.bookLong,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  onTap: () {
                                    // When the user taps the button, navigate to the specific route
                                    // and provide the arguments as part of the RouteSettings.
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExtractArgumentsScreen(
                                                bookNameShort: item.bookShort,
                                                bookChToOpen: "0"),
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
                                ),
                              );
                            } else if (item is SectionItem) {
                              return Container(
                                margin:
                                    const EdgeInsets.only(left: 25, right: 25),
                                child: ListTile(
                                  contentPadding:
                                      EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  title: Text(
                                    item.section,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ], // Children
              ),
            ),
          ],
        ),
      ),
    );
  }
} // A Widget that accepts the necessary arguments via the constructor.

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
    Key? key,
    required this.title,
    required this.message,
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
