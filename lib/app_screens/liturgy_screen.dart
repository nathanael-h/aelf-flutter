import 'dart:convert';
import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aelf_flutter/liturgyDbHelper.dart';
import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:connectivity/connectivity.dart';

class LiturgyScreen extends StatefulWidget {
  LiturgyScreen(this.liturgyType, this.liturgyDate, this.liturgyRegion, this.refresh) : super();

  static const routeName = '/liturgyScreen';

  final String liturgyDate;
  final String liturgyType;
  final String liturgyRegion;
  final int refresh;

  @override
  _LiturgyScreenState createState() => _LiturgyScreenState();
}

class _LiturgyScreenState extends State<LiturgyScreen>
    with TickerProviderStateMixin {
  // aelf settings
  String apiUrl = 'https://api.aelf.org/v1/';

  // refresh value to save previous refresh and not refresh limitless
  int _liturgyRefresh = -1;

  // add liturgy db helper
  final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
  Future futureAELFjson;
  String localDate;


  @override
  void initState() {
  futureAELFjson = _getAELFLiturgy(widget.liturgyType, widget.liturgyDate, widget.liturgyRegion);
  localDate = widget.liturgyDate;
    super.initState();
  }

  Future _getAELFLiturgy(String type, String date, String region) async {
    print(widget.liturgyDate + ' ' + widget.liturgyType + ' ' + widget.liturgyRegion);
    // rep - server or db response
    Liturgy rep =
        await liturgyDbHelper.getRow(widget.liturgyDate, widget.liturgyType, widget.liturgyRegion);

    if (rep != null) {
      var obj = json.decode(rep.content);
      //_displayAelfLiturgy(obj);
      print("db yes");
      return obj;
    } else {
      print("db no");
      //check internet connection
      ConnectivityResult connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        return _getAELFLiturgyOnWeb(widget.liturgyDate, widget.liturgyType, widget.liturgyRegion);
      } else {
        //_displayMessage("Connectez-vous pour voir cette lecture.");
        return {"erreur": "Connectez-vous pour voir cette lecture."};

        // clear actualy date to refresh page when connect to internet
      }
    }
  }
//TODO: add a internet listener so that when internet comes back, it loads what needed.
  Future _getAELFLiturgyOnWeb(String type, String date, String region) async {
      // get aelf content in their web api
      final response = await http.get(
          //'https://jsonplaceholder.typicode.com/todos/1');
          '$apiUrl${widget.liturgyType}/${widget.liturgyDate}/${widget.liturgyRegion}');
      print('downloading: $apiUrl${widget.liturgyType}/${widget.liturgyDate}/${widget.liturgyRegion}');
      if (response.statusCode == 200) {
        var obj = json.decode(response.body);
        return obj[widget.liturgyType];
      } else if (response.statusCode == 404) {
        // this liturgy does not exist -> return message
        return jsonEncode({"${widget.liturgyType}":{"erreur": "Nous n'avons pas trouvé cette lecture."}});
      } else {
        // If the server did not return a 200 OK response,
        return jsonEncode({"${widget.liturgyType}":{"erreur": "La connexion au serveur à échoué."}});

      }
  }

  void _isDateChanged() {
    if (localDate != widget.liturgyDate) {
      setState(() {
        localDate = widget.liturgyDate;
        futureAELFjson = _getAELFLiturgy(widget.liturgyType, localDate, widget.liturgyRegion);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDateChanged();
    return Center(
      child: FutureBuilder(
        future: futureAELFjson,
        builder: (context, snapshot){
          if (snapshot.hasData) {
            return LiturgyFormatter(snapshot.data, widget.liturgyType);
          } else {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
              } else {
              return CircularProgressIndicator();  
              }
            }
        },
      ),
    );
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
