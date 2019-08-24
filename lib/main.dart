import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:aelf_flutter/app_screens/book_screen.dart';



void main() {
  runApp(MyApp(storage: ChapterStorage()));
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
      home: MyHomePage(storage: ChapterStorage()),
    );
  }
}

//https://flutter.dev/docs/cookbook/persistence/reading-writing-files
class ChapterStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localChapter async {
    final path = await _localPath;
    return File('$path/assets/chapter.txt');
  }

  Future<String> readChapter() async {
    try {
      final file = await _localChapter;

      // Read the chapter
      String contents = await file.readAsStringSync();
      return contents;
    } catch (e) {
      // If error, return a message
      return 'error while reading text file';
    }
  }
// Load Assets https://flutter.dev/docs/development/ui/assets-and-images
  Future<String> loadAsset() async {
    return await rootBundle.loadString('assets/chapter.txt');
  }

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
  List listNewTestamentBooks = [
      "Évangile selon Saint Matthieu",
      "Évangile selon Saint Marc",
      "Évangile selon Saint Luc",
      "Évangile selon Saint Jean",
      "Les Actes des Apôtres",
      "Lettre aux Romains",
      "Première lettre aux Corinthiens",
      "Deuxième lettre aux Corinthiens",
      "Lettre aux Galates",
      "Lettre aux Éphésiens",
      "Lettre aux Philippiens",
      "Lettre aux Colossiens",
      "Première lettre aux Théssaloniciens",
      "Deuxième lettre aux Théssaloniciens",
      "Première lettre à Timothée",
      "Deuxième lettre à Timothée",
      "Lettre à Tite",
      "Lettre à Philémon",
      "Lettre aux Hébreux",
      "Lettre de Saint Jacques",
      "Premier lettre de Saint Pierre",
      "Deuxième lettre de Saint Pierre",
      "Premier lettre de Saint Jean",
      "Deuxième lettre de Saint Jean",
      "Troisième lettre de Saint Jean",
      "Lettre de Saint Jude",
      "L'Apocalypse"
  ];

  @override
  void initState() {
    super.initState();
    widget.storage.loadAsset().then((String text) {
      setState(() {
        chapter = text;
      });
    });
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
                child: ListView(
                  children: <Widget>[
                    ListTile(
                      title: Text('Livre 1'),
                      onTap: () {
                        // When the user taps the button, navigate to the specific route
                        // and provide the arguments as part of the RouteSettings.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExtractArgumentsScreen(),
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
                    ListTile(
                      title: Text('Livre 2'),
                    ),
                    ListTile(
                      title: Text('$chapter'),
                    ),
                  ],
                ),
              ),
              Tab(
                child: GridView.count(
                  crossAxisCount: 5,
                  children: List.generate(150, (index) {
                    return Center(
                      child: Text(
                        'Psaume $index',
                      ),
                    );
                  }),
                ),
              ),
              Tab(
                child: ListView.builder(
                 itemCount: listNewTestamentBooks.length,
                 itemBuilder: (context, index) {
                   return ListTile (
                     title: Text(listNewTestamentBooks[index]),
                     onTap: () {
                       // When the user taps the button, navigate to the specific route
                       // and provide the arguments as part of the RouteSettings.
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => ExtractArgumentsScreen(storage: ChapterStorage(), bookName: listNewTestamentBooks[index],),
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
