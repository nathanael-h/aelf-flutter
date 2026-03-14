import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/widgets/fr-fr_aelf.json.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/biblePositionState.dart';

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
  BookItem(this.bookLong, this.bookShort, this.bookChNbr, this.bookDeterminer);

  final int bookChNbr;
  final String bookLong;
  final String bookShort;
  final String bookDeterminer;
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
    BookItem("Livre de la Genèse", "Gn", 50, "du"),
    BookItem("Livre de l'Exode", "Ex", 40, "du"),
    BookItem("Livre du Lévitique", "Lv", 27, "du"),
    BookItem("Livre des Nombres", "Nb", 36, "du"),
    BookItem("Livre du Deutéronome", "Dt", 34, "du"),
    SectionItem("Livres Historiques"),
    BookItem("Livre de Josué", "Jos", 24, "du"),
    BookItem("Livre des Juges", "Jg", 21, "du"),
    BookItem("Livre de Ruth", "Rt", 4, "du"),
    BookItem("Premier livre de Samuel", "1S", 31, "du"),
    BookItem("Deuxième livre de Samuel", "2S", 24, "du"),
    BookItem("Premier livre des Rois", "1R", 22, "du"),
    BookItem("Deuxième livre des Rois", "2R", 25, "du"),
    BookItem("Premier livre des Chroniques", "1Ch", 29, "du"),
    BookItem("Deuxième livre des Chroniques", "2Ch", 36, "du"),
    BookItem("Livre d'Esdras", "Esd", 10, "du"),
    BookItem("Livre de Néhémie", "Ne", 13, "du"),
    BookItem("Livre de Tobie", "Tb", 14, "du"),
    BookItem("Livre de Judith", "Jdt", 16, "du"),
    BookItem("Livre d'Esther", "Est", 11, "du"),
    BookItem("Premier livre des Martyrs d'Israël", "1M", 16, "du"),
    BookItem("Deuxième livre des Martyrs d'Israël", "2M", 15, "du"),
    SectionItem("Livres poétiques et sapientiaux"),
    BookItem("Livre de Job", "Jb", 42, "du"),
    BookItem("Livre des Proverbes", "Pr", 31, "du"),
    BookItem("Livre de l'Écclésiaste (ou Qohèlet)", "Qo", 12, "du"),
    BookItem("Cantique des Cantiques", "Ct", 8, "du"),
    BookItem("Livre de la Sagesse", "Sg", 19, "du"),
    BookItem("Livre de Ben Sira (ou Ecclésiastique)", "Si", 52, "du"),
    SectionItem("Livres Prophétiques"),
    BookItem("Livre d'Isaïe", "Is", 66, "du"),
    BookItem("Livre de Jérémie", "Jr", 52, "du"),
    BookItem("Livre des Lamentations", "Lm", 5, "du"),
    BookItem("Livre de Baruch", "Ba", 5, "du"),
    BookItem("Lettre de Jérémie", "1Jr", 1, ""),
    BookItem("Livre d'Ézékiel", "Ez", 48, "du"),
    BookItem("Livre de Daniel", "Dn", 14, "du"),
    BookItem("Livre d'Osée", "Os", 14, "du"),
    BookItem("Livre de Joël", "Jl", 4, "du"),
    BookItem("Livre d'Amos", "Am", 9, ""),
    BookItem("Livre d'Abdias", "Ab", 1, "du"),
    BookItem("Livre de Jonas", "Jon", 4, "du"),
    BookItem("Livre de Michée", "Mi", 7, "du"),
    BookItem("Livre de Nahoum", "Na", 3, "du"),
    BookItem("Livre d'Habacuc", "Ha", 3, "du"),
    BookItem("Livre de Sophonie", "So", 3, "du"),
    BookItem("Livre d'Aggée", "Ag", 2, "du"),
    BookItem("Livre de Zacharie", "Za", 14, "du"),
    BookItem("Livre de Malachie", "Ml", 3, "du"),
  ];
  List listNewTestamentBooks = [
    SectionItem("Évangiles"),
    BookItem("Évangile selon saint Matthieu", "Mt", 28, "de l'"),
    BookItem("Évangile selon saint Marc", "Mc", 16, "de l'"),
    BookItem("Évangile selon saint Luc", "Lc", 24, "de l'"),
    BookItem("Évangile selon saint Jean", "Jn", 21, "de l'"),
    SectionItem("Actes"),
    BookItem("Actes des Apôtres", "Ac", 22, "des"),
    SectionItem("Lettres de saint Paul"),
    BookItem("Lettre aux Romains", "Rm", 16, "de la"),
    BookItem("Première lettre aux Corinthiens", "1Co", 16, "de la"),
    BookItem("Deuxième lettre aux Corinthiens", "2Co", 13, "de la"),
    BookItem("Lettre aux Galates", "Ga", 6, "de la"),
    BookItem("Lettre aux Éphésiens", "Ep", 6, "de la"),
    BookItem("Lettre aux Philippiens", "Ph", 4, "de la"),
    BookItem("Lettre aux Colossiens", "Col", 4, "de la"),
    BookItem("Première lettre aux Thessaloniciens", "1Th", 4, "de la"),
    BookItem("Deuxième lettre aux Thessaloniciens", "2Th", 3, "de la"),
    BookItem("Première lettre à Timothée", "1Tm", 6, "de la"),
    BookItem("Deuxième lettre à Timothée", "2Tm", 4, "de la"),
    BookItem("Lettre à Tite", "Tt", 3, "de la"),
    BookItem("Lettre à Philémon", "Phm", 1, "de la"),
    BookItem("Lettre aux Hébreux", "He", 13, "de la"),
    SectionItem("Lettres catholiques"),
    BookItem("Lettre de saint Jacques", "Jc", 5, "de la"),
    BookItem("Première lettre de saint Pierre", "1P", 5, "de la"),
    BookItem("Deuxième lettre de saint Pierre", "2P", 3, "de la"),
    BookItem("Première lettre de saint Jean", "1Jn", 5, "de la"),
    BookItem("Deuxième lettre de saint Jean", "2Jn", 1, "de la"),
    BookItem("Troisième lettre de saint Jean", "3Jn", 1, "de la"),
    BookItem("Lettre de saint Jude", "Jude", 1, "de la"),
    SectionItem("Apocalypse"),
    BookItem("Apocalypse", "Ap", 22, "de l'"),
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
                      child: Consumer<BiblePositionState>(
                        builder: (context, biblePosition, child) => Container(
                          width: 600,
                          child: Column(
                            children: [
                              Visibility(
                                visible: biblePosition.hasPosition,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, top: 0),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Theme.of(context)
                                                  .dividerColor,
                                              width: 0))),
                                  child: ListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(16, 16, 16, 0),
                                    title: Text(
                                      "Voulez-vous reprendre la lecture ${getBookNameDeterminerLong(biblePosition.lastBook ?? "")}, ${biblePosition.lastChapter} ?",
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExtractArgumentsScreen(
                                          bookNameShort: biblePosition.lastBook,
                                          bookChToOpen:
                                              biblePosition.lastChapter,
                                        ),
                                        settings: RouteSettings(
                                          arguments: ScreenArguments(
                                            'Extract Arguments Screen',
                                            'This message is extracted in the build method.',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
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
                                                    color: Theme.of(context)
                                                        .dividerColor,
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
                                            // Save position on book selection (always chapter "0")
                                            context
                                                .read<BiblePositionState>()
                                                .updatePosition(
                                                    item.bookShort, "0");

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
                                        margin: const EdgeInsets.only(
                                            left: 25, right: 25),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.fromLTRB(
                                              16, 16, 16, 0),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 600,
                        child: Consumer<BiblePositionState>(
                          builder: (context, biblePosition, child) => Column(
                            children: [
                              Visibility(
                                visible: biblePosition.hasPosition,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, top: 0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                        width: 0,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(16, 16, 16, 0),
                                    title: Text(
                                      "Voulez-vous reprendre la lecture ${getBookNameDeterminerLong(biblePosition.lastBook ?? "")}, ${biblePosition.lastChapter} ?",
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExtractArgumentsScreen(
                                          bookNameShort: biblePosition.lastBook,
                                          bookChToOpen:
                                              biblePosition.lastChapter,
                                        ),
                                        settings: RouteSettings(
                                          arguments: ScreenArguments(
                                            'Extract Arguments Screen',
                                            'This message is extracted in the build method.',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
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
                                            color:
                                                Theme.of(context).dividerColor,
                                            width: 0,
                                          ),
                                        ),
                                      ),
                                      child: ListTile(
                                        title: Text(item,
                                            textAlign: TextAlign.left,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
                                        onTap: () {
                                          // Save position on psalm selection
                                          context
                                              .read<BiblePositionState>()
                                              .updatePosition(
                                                  'Ps', item.split(' ')[1]);

                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ExtractArgumentsScreen(
                                                  bookNameShort: 'Ps',
                                                  bookChToOpen:
                                                      item.split(' ')[1],
                                                ),
                                              ));
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 600,
                        child: Consumer<BiblePositionState>(
                          builder: (context, biblePosition, child) => Column(
                            children: [
                              Visibility(
                                visible: biblePosition.hasPosition,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, top: 0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                        width: 0,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        EdgeInsets.fromLTRB(16, 16, 16, 0),
                                    title: Text(
                                      "Voulez-vous reprendre la lecture ${getBookNameDeterminerLong(biblePosition.lastBook ?? "")}, ${biblePosition.lastChapter} ?",
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExtractArgumentsScreen(
                                          bookNameShort: biblePosition.lastBook,
                                          bookChToOpen:
                                              biblePosition.lastChapter,
                                        ),
                                        settings: RouteSettings(
                                          arguments: ScreenArguments(
                                            'Extract Arguments Screen',
                                            'This message is extracted in the build method.',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
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
                                              color: Theme.of(context)
                                                  .dividerColor,
                                              width: 0,
                                            ),
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 0),
                                          title: Text(
                                            item.bookLong,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                          onTap: () {
                                            context
                                                .read<BiblePositionState>()
                                                .updatePosition(
                                                    item.bookShort, "0");
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ExtractArgumentsScreen(
                                                  bookNameShort: item.bookShort,
                                                  bookChToOpen: "0",
                                                ),
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
                                        margin: const EdgeInsets.only(
                                            left: 25, right: 25),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.fromLTRB(
                                              16, 16, 16, 0),
                                          title: Text(
                                            item.section,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ],
                          ),
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

  String getBookNameDeterminerLong(String bookNameShort) {
    if (bookNameShort == "Ps") {
      return "du Psaume";
    } else {
      int index = listOldTestamentBooks.indexWhere((book) =>
          book.runtimeType == BookItem && book.bookShort == bookNameShort);
      if (index > 0) {
        return "${listOldTestamentBooks[index].bookDeterminer} ${listOldTestamentBooks[index].bookLong}";
      } else {
        index = listNewTestamentBooks.indexWhere((book) =>
            book.runtimeType == BookItem && book.bookShort == bookNameShort);
        if (index > 0) {
          return "${listNewTestamentBooks[index].bookDeterminer} ${listNewTestamentBooks[index].bookLong}";
        }
      }
    }
    return bookNameShort;
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
