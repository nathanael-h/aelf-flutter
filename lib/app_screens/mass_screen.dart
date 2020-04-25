import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MassScreen extends StatefulWidget {

  final String apiUrl = 'https://api.aelf.org/v1/';

  MassScreen({Key key}) : super(key: key);
  @override
  _MassScreenState createState() => _MassScreenState();
}

class _MassScreenState extends State<MassScreen> {

  String date = '2020-04-25';
  String zone = 'france';
  Future<Mass> futureMass; 

  @override
  void initState() {
    futureMass = fetchMass2();
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
        Text(zone),
        FutureBuilder(
          future: futureMass,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data.title);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        )
      ],
    );
  }
}


Future<http.Response> fetchMass1() {
  //return http.get('https://api.aelf.org/v1/messes/2020-04-26/france');
  return http.get('https://jsonplaceholder.typicode.com/albums/1');

}


class Mass {
  final int userId;
  final int id;
  final String title;

  Mass({this.userId, this.id, this.title});

  factory Mass.fromJson(Map<String, dynamic> json) {
    return Mass(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
    );
  }
}

Future<Mass> fetchMass2() async {
  final response = await http.get('https://jsonplaceholder.typicode.com/albums/1');

  if (response.statusCode == 200) {
    return Mass.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load Mass');
  }
}