import 'dart:convert';
import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aelf_flutter/liturgyDbHelper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LiturgyScreen extends StatefulWidget {
  LiturgyScreen(this.liturgyType, this.liturgyDate, this.liturgyRegion,
      this.refresh, this.fontSize)
      : super();

  static const routeName = '/liturgyScreen';

  final String liturgyDate;
  final String liturgyType;
  final String liturgyRegion;
  final int refresh;
  final double fontSize;

  @override
  _LiturgyScreenState createState() => _LiturgyScreenState(this.fontSize);
}

class _LiturgyScreenState extends State<LiturgyScreen>
    with TickerProviderStateMixin {
  _LiturgyScreenState(this.fontSize);
  final double fontSize;

  // aelf settings
  String apiUrl = 'api.aelf.org';

  // add liturgy db helper
  final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
  Future futureAELFjson;
  String localDate;
  double localFontSize;

  @override
  void initState() {
    futureAELFjson = _getAELFLiturgy(
        widget.liturgyType, widget.liturgyDate, widget.liturgyRegion);
    localDate = widget.liturgyDate;
    localFontSize = widget.fontSize;
    super.initState();
  }

  Future _getAELFLiturgy(String type, String date, String region) async {
    print(widget.liturgyDate +
        ' ' +
        widget.liturgyType +
        ' ' +
        widget.liturgyRegion);
    // rep - server or db response
    Liturgy rep = await liturgyDbHelper.getRow(
        widget.liturgyDate, widget.liturgyType, widget.liturgyRegion);

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
        return _getAELFLiturgyOnWeb(
            widget.liturgyDate, widget.liturgyType, widget.liturgyRegion);
      } else {
        //_displayMessage("Connectez-vous pour voir cette lecture.");
        return {
          "erreur":
              "Un accès à Internet est requis pour consulter cette lecture."
        };

        // clear actualy date to refresh page when connect to internet
      }
    }
  }

//TODO: add a internet listener so that when internet comes back, it loads what needed.
  Future _getAELFLiturgyOnWeb(String type, String date, String region) async {
      Uri uri = Uri.https(apiUrl, 'v1/${widget.liturgyType}/${widget.liturgyDate}/${widget.liturgyRegion}');
      // get aelf content in their web api
      final response = await http.get(uri);
      print('downloading: ' + uri.toString());
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
        futureAELFjson = _getAELFLiturgy(
            widget.liturgyType, localDate, widget.liturgyRegion);
      });
    }
  }

  void _isFontSizeChanged() {
    if (localFontSize != widget.fontSize) {
      setState(() {
        localFontSize = widget.fontSize;
        futureAELFjson = _getAELFLiturgy(
            widget.liturgyType, localDate, widget.liturgyRegion);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDateChanged();
    _isFontSizeChanged();
    return Center(
      child: FutureBuilder(
        future: futureAELFjson,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return LiturgyFormatter(
                snapshot.data, widget.liturgyType, widget.fontSize);
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
}
