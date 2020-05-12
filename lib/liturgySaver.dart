import 'dart:async';
import 'package:aelf_flutter/liturgyDbHelper.dart';
import 'package:aelf_flutter/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiturgySaver  {
  final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
  // get today date
  final today = new DateTime.now();
  // list of save elements
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
  String apiUrl = 'https://api.aelf.org/v1/';

  LiturgySaver() {
    print("auto save");
    // for n days, get futur date, check if each type of liturgy exist and download else...
    for (int i = 0; i < nbDaysSaved; i++) {
      String saveDate = getDifferedDateAdd(i);
      types.forEach((type) {
        liturgyDbHelper.checkIfExist(saveDate, type).then((rep) {
          if (!rep) {
            // get content from aelf server
            getAELFLiturgyOnWeb(type, saveDate).then((content) {
              if (content != "") {
                // save liturgy
                saveToDb(type, saveDate, content);
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

  Future<String> getAELFLiturgyOnWeb(String type, String date) async {
    String liturgyZone = await getPrefRegion();

    try {
      // get aelf content in their web api
      final response = await http.get('$apiUrl$type/$date/$liturgyZone');
      if (response.statusCode == 200) {
        var obj = json.decode(response.body);
        return json.encode(obj[type]);
      } else if (response.statusCode == 404) {
        // this liturgy not exist -> display message
        return "Cette lecture n'existe pas.";
      } else {
        // If the server did not return a 200 or 404 OK response
        return "";
      }
    } catch (error) {
      print("getAELFLiturgyOnWeb in liturgy saver error: " + error.toString());
    }
  }

  void saveToDb(String type, String date, String content) {
    Liturgy element = new Liturgy(
      date: date,
      type: type,
      content: content,
    );
    liturgyDbHelper.insert(element);
    print("saved " + date + ' ' + type);
  }
}
