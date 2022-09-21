import 'dart:convert';

import 'package:aelf_flutter/liturgyDbHelper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

//TODO: use me
//TODO: test me


class LiturgyState extends ChangeNotifier {
  String date = "${DateTime.now().toLocal()}".split(' ')[0];
  String region = 'autre';
  String liturgyType = 'messes';
  final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
  // aelf settings
  String apiUrl = 'api.aelf.org';
  String aelfJson = '''{"Erreur": "Une erreur s'est produite lors de l'initialisation de cette lecture."}''';

  LiturgyState() {
    // TODO: init date, region and type
    _getAELFLiturgy(liturgyType, date, region).then((value) {
      aelfJson = value;
      notifyListeners();
      return null;
    });
  }

  Future _getAELFLiturgy(String type, String date, String region) async {
    print(date + ' ' + type + ' ' +region);
    // rep - server or db response
    Liturgy rep =
        await liturgyDbHelper.getRow(date, liturgyType, region);

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
        return _getAELFLiturgyOnWeb(date, liturgyType, region);
      } else {
        //_displayMessage("Connectez-vous pour voir cette lecture.");
        return {"erreur": "Un accès à Internet est requis pour consulter cette lecture."};

        // clear actualy date to refresh page when connect to internet
      }
    }
  }
//TODO: add a internet listener so that when internet comes back, it loads what needed.
  Future _getAELFLiturgyOnWeb(String type, String date, String region) async {
      Uri uri = Uri.https(apiUrl, 'v1/$liturgyType/$date/$region');
      // get aelf content in their web api
      final response = await http.get(uri);
      print('downloading: ' + uri.toString());
      if (response.statusCode == 200) {
        var obj = json.decode(response.body);
        return obj[liturgyType];
      } else if (response.statusCode == 404) {
        // this liturgy does not exist -> return message
        return jsonEncode({"$liturgyType":{"erreur": "Nous n'avons pas trouvé cette lecture."}});
      } else {
        // If the server did not return a 200 OK response,
        return jsonEncode({"$liturgyType":{"erreur": "La connexion au serveur à échoué."}});

      }
  }

}
