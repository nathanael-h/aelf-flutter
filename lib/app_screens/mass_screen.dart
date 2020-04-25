import 'package:flutter/material.dart';

class MassScreen extends StatefulWidget {

  final String apiUrl = 'https://api.aelf.org/v1/';

  MassScreen({Key key}) : super(key: key);
  @override
  _MassScreenState createState() => _MassScreenState();
}

class _MassScreenState extends State<MassScreen> {

  String date = '2020-04-25';
  String zone = 'france';

  @override
  void initState() {

  }

  @override
  void dispose() {
    super.dispose;
  }

  @override 
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('Salut salut !'),
        Text(date),
        Text(zone)
      ],
    );
  }
}