import 'dart:convert';
import 'dart:developer';

import 'package:aelf_flutter/liturgyDbHelper.dart';
import 'package:aelf_flutter/settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LiturgyState extends ChangeNotifier {
  String date = "${DateTime.now().toLocal()}".split(' ')[0];
  String region = 'romain';
  String liturgyType = 'messes';
  final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
  // aelf settings
  String apiUrl = 'api.aelf.org';
  Map? aelfJson;

  // get today date
  final today = new DateTime.now();
  // AutoSave params
  List<String> types = [
    "messes",
    "lectures",
    "laudes",
    "tierce",
    "sexte",
    "none",
    "vepres",
    "complies",
    "informations"
  ];
  int nbDaysSaved = 20;
  int nbDaysSavedBefore = 20;

  LiturgyState() {
    print("LiturgyState init 1");
    initRegion();
  }

  void updateDate(String newDate) {
    if (date != newDate) {
      date = newDate;
      updateLiturgy();
      notifyListeners();
    } else {
      log('date == newDate');
    }
  }

  void updateRegion(String newRegion) {
    if (region != newRegion) {
      log('updateRegion to $newRegion');
      region = newRegion;
      setRegion(newRegion);
      updateLiturgy();
      notifyListeners();
    } else {
      log('region == newRegion');
    }
  }

  void updateLiturgyType(String newLiturgyType) {
    if (liturgyType != newLiturgyType) {
      liturgyType = newLiturgyType;
      updateLiturgy();
      notifyListeners();
    } else {
      log('liturgyType == newLiturgyType');
    }
  }

  void updateLiturgy() {
    _getAELFLiturgy(liturgyType, date, region).then((value) {
      if (aelfJson != value) {
        aelfJson = value;
        notifyListeners();
      } else {
        log('aelfJson == newAelfJson');
      }
    });
  }

  void initRegion() async {
    log('initRegion');
    await getRegion().then((savedRegion) {
      region = savedRegion;
    });
    updateLiturgy();
    autoSaveLiturgy();
  }

  Future<Map?> _getAELFLiturgy(String type, String date, String region) async {
    print(date + ' ' + type + ' ' + region);
    // rep - server or db response
    Liturgy? rep = await liturgyDbHelper.getRow(date, liturgyType, region);

    if (rep != null) {
      Map? obj = json.decode(rep.content!);
      //_displayAelfLiturgy(obj);
      print("db yes");
      return obj;
    } else {
      print("db no");
      //check internet connection
      List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());
      if (connectivityResult.first != ConnectivityResult.none) {
        return _getAELFLiturgyOnWeb(liturgyType, date, region);
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
  Future<Map?> _getAELFLiturgyOnWeb(
      String? type, String date, String region) async {
    Uri uri = Uri.https(apiUrl, 'v1/$type/$date/$region');
    // get aelf content in their web api
    final response = await http.get(uri);
    print('downloading: ' + uri.toString());
    if (response.statusCode == 200) {
      Map obj = json.decode(response.body);
      obj.removeWhere((key, value) => key != type);
      return obj;
    } else if (response.statusCode == 404) {
      // this liturgy does not exist -> return message
      Map? obj = json.decode(
          """{"$type": {"erreur": "Nous n'avons pas trouvé cette lecture."}}""");
      return obj;
    } else {
      // If the server did not return a 200 OK response,
      Map? obj = json.decode(
          """{type: {"erreur": "La connexion au serveur à échoué."}}""");
      return obj;
    }
  }

  void autoSaveLiturgy() async {
    print("auto save");
    // for n days, get futur date, check if each type of liturgy exist and download else...
    for (int i = 0; i < nbDaysSaved; i++) {
      String saveDate = getDifferedDateAdd(i);
      //String region = await getPrefRegion() ?? "romain";
      types.forEach((type) {
        liturgyDbHelper.checkIfExist(saveDate, type, region).then((rep) {
          if (!rep) {
            // get content from aelf server
            _getAELFLiturgyOnWeb(type, saveDate, region).then((content) {
              if (content != "") {
                // save liturgy
                saveToDb(type, saveDate, json.encode(content), region);
              }
            });
          }
        });
      });
    }
    // delete bible n days before
    String deleteDate = getDifferedDateSub(nbDaysSavedBefore);
    liturgyDbHelper.deleteBibleDbBeforeDays(deleteDate);
  }

  String getDifferedDateAdd(int nbDays) {
    return today.add(new Duration(days: nbDays)).toString().substring(0, 10);
  }

  String getDifferedDateSub(int nbDays) {
    return today
        .subtract(new Duration(days: nbDays))
        .toString()
        .substring(0, 10);
  }

  void saveToDb(String type, String date, String content, String region) {
    Liturgy element = new Liturgy(
      date: date,
      type: type,
      content: content,
      region: region,
    );
    liturgyDbHelper.insert(element);
    print("saved " + date + ' ' + type + ' ' + region);
  }
}
