import 'package:flutter/material.dart';

class BibleSearchScreen extends StatefulWidget {
  static const routeName = '/bibleSearchScreen';
  BibleSearchScreen({Key key}) : super(key: key);

  @override
  _BibleSearchScreenState createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {

  String keyword;

  @override
  void initState() {
    keyword = '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rechercher'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Entrer quelques mots...',
                border: OutlineInputBorder(),
                labelText: 'Rechercher un passage de la Bible'
              ),
              onChanged: (value) {
                setState(() {
                  keyword = value;
                });
              },
            ),
          ),
          Text(keyword)
        ],
      )
    );
  }
} // A Widget that accepts the necessary arguments via the constructor.

//class PassArgumentsScreen extends StatelessWidget {
//  static const routeName = '/passArguments';
//
//  final String title;
//  final String message;
//
//  // This Widget accepts the arguments as constructor parameters. It does not
//  // extract the arguments from the ModalRoute.
//  //
//  // The arguments are extracted by the onGenerateRoute function provided to the
//  // MaterialApp widget.
//  const PassArgumentsScreen({
//    Key key,
//    @required this.title,
//    @required this.message,
//  }) : super(key: key);
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text(title),
//      ),
//      body: Center(
//        child: Text(message),
//      ),
//    );
//  }
//}
//
//// You can pass any object to the arguments parameter. In this example,
//// create a class that contains both a customizable title and message.
//class ScreenArguments {
//  final String title;
//  final String message;
//
//  ScreenArguments(this.title, this.message);
//}
//