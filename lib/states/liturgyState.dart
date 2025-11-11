import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:aelf_flutter/utils/flutter_data_loader.dart';
import 'package:aelf_flutter/utils/liturgyDbHelper.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

class LiturgyState extends ChangeNotifier {
  String date = "${DateTime.now().toLocal()}".split(' ')[0];
  String region = 'lyon';
  String liturgyType = 'messes';
  final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
  // aelf settings
  String apiAelf = 'api.aelf.org';
  String apiEpitreCo = 'api.app.epitre.co';
  Map? aelfJson;
  String userAgent = '';
  Calendar offlineCalendar = Calendar(); //calendar initialisation
  Map<String, ComplineDefinition> offlineComplines = {};
  Map<String, Morning> offlineMorning = {};

  // get today date
  final today = DateTime.now();
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
    initUserAgent();
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
      log('liturgyType set to $newLiturgyType');
    } else {
      log('liturgyType == newLiturgyType, $newLiturgyType');
    }
  }

  void updateLiturgy() {
    switch (liturgyType) {
      case 'complies_new':
        getNewOfflineLiturgy(liturgyType, DateTime.parse(date), region)
            .then((value) {
          offlineComplines = value;
          notifyListeners();
        });
        break;

      case 'offline_morning':
        getOfflineMorning(liturgyType, DateTime.parse(date), region)
            .then((value) {
          offlineMorning = value;
          notifyListeners();
        });
        break;

      default:
        _getAELFLiturgy(liturgyType, date, region).then((value) {
          if (aelfJson != value) {
            aelfJson = value;
            notifyListeners();
          } else {
            log('aelfJson == newAelfJson');
          }
        });
    }

/*
    if (liturgyType.contains('offline')) {
      getOfflineCompline(liturgyType, date, region).then((value) {
        if (aelfJson != value) {
          aelfJson = value;
          notifyListeners();
        } else {
          log('aelfJson == newAelfJson');
        }
      });
    } else if (liturgyType.contains('new')) {
      offlineComplines = getNewOfflineLiturgy(liturgyType, date, region);

      notifyListeners();
    } else {
      _getAELFLiturgy(liturgyType, date, region).then((value) {
        if (aelfJson != value) {
          aelfJson = value;
          notifyListeners();
        } else {
          log('aelfJson == newAelfJson');
        }
      });
    }
    // getOfflineCompline();
    */
  }

  void initRegion() async {
    log('initRegion');
    await getRegion().then((savedRegion) {
      region = savedRegion;
    });
    updateLiturgy();
    autoSaveLiturgy();
  }

  void initUserAgent() async {
    // private String buildUserAgent() {
    //     return String.format(Locale.ROOT,
    //             "%s %s (%s); %s %s; Android %s",
    //             BuildConfig.APPLICATION_ID,
    //             BuildConfig.VERSION_CODE,
    //             BuildConfig.BUILD_TYPE,
    //             Build.MANUFACTURER,
    //             Build.MODEL,
    //             Build.VERSION.RELEASE
    //     );
    // }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String applicationId = packageInfo.packageName;
    String version = '${packageInfo.version}.${packageInfo.buildNumber}';
    String buildType = "buildTypeUndefined";
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String manufacturer = "ManufacturerUndefined";
    String model = "";
    String os = Platform.operatingSystem;
    String osVersion = "";

    if (kDebugMode) {
      buildType = "Debug";
    } else if (kReleaseMode) {
      buildType = "Release";
    } else if (kProfileMode) {
      buildType = "Profile";
    }

    WidgetsFlutterBinding.ensureInitialized();

    // Per platform info for
    // - manufacturer
    // - model
    // - osVersion
    switch (os) {
      case 'linux':
        LinuxDeviceInfo linuxDeviceInfo = await deviceInfo.linuxInfo;
        model = linuxDeviceInfo.id;
        try {
          final File file = File('/sys/devices/virtual/dmi/id/sys_vendor');
          manufacturer = file.readAsLinesSync()[0];
        } catch (e) {
          print("Couldn't read file /sys/devices/virtual/dmi/id/sys_vendor");
        }
        try {
          final File file = File('/sys/devices/virtual/dmi/id/product_name');
          model = file.readAsLinesSync()[0];
        } catch (e) {
          print("Couldn't read file /sys/devices/virtual/dmi/id/product_name");
        }
        osVersion = "${linuxDeviceInfo.id} ${linuxDeviceInfo.buildId!}";
        break;
      case 'android':
        AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
        manufacturer = androidDeviceInfo.manufacturer;
        model = androidDeviceInfo.model;
        osVersion = androidDeviceInfo.version.toString();
        break;
      case 'ios':
        IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
        manufacturer = "Apple";
        model = iosDeviceInfo.model;
        osVersion = iosDeviceInfo.systemVersion;
        break;
      default:
    }
    // AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    // print('Running on ${androidInfo.model}'); // e.g. "Moto G (4)"
    // LinuxDeviceInfo linuxDeviceInfo = await deviceInfo.linuxInfo;
    // IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    // print('Running on ${iosInfo.utsname.machine}'); // e.g. "iPod7,1"
    userAgent += "$applicationId ";
    userAgent += "$version ";
    userAgent += "($buildType); ";
    userAgent += "$manufacturer ";
    userAgent += "$model; ";
    userAgent += "$os ";
    userAgent += osVersion;
    print('userAgent = $userAgent');
  }

  Future<Map?> _getAELFLiturgy(String type, String date, String region) async {
    print('$date $type $region');
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
          "erreur_technique":
              "Un accès à Internet est requis pour consulter cette lecture."
        };

        // clear actualy date to refresh page when connect to internet
      }
    }
  }
/*
  Future<Map?> getOfflineCompline(
      String type, String date, String region) async {
    // Date is in form YYYY-MM-DD parse it and return a DateTime(YYYY, MM, DD)
    DateTime dateTime = DateTime.parse(date);
    String compline = exportComplineToAelfJson(offlineCalendar, dateTime);
    print("json: $compline");
    Map obj = json.decode(compline);
    obj.removeWhere((key, value) => key != 'complies');

    return obj;
  }
  */

  Future<Map<String, ComplineDefinition>> getNewOfflineLiturgy(
      String type, DateTime dateTime, String region) async {
    print("getNewOfflineCompline called for $type, $dateTime, $region");

    // Create Flutter DataLoader
    final dataLoader = FlutterDataLoader();

    offlineCalendar = getCalendar(offlineCalendar, dateTime, region);

    // Retrieving and returning the list of possible Complines
    Map<String, ComplineDefinition> possibleComplines =
        await complineDefinitionResolution(
            offlineCalendar, dateTime, dataLoader);

    return possibleComplines;
    /*
  Map<String, Compline> complineTextCompiled =
      complineTextCompilation(possibleComplines);
  return complineTextCompiled;
  */
  }

  Future<Map<String, Morning>> getOfflineMorning(
      String type, DateTime dateTime, String region) async {
    print("getOfflineMorning called for $type, $dateTime, $region");

    // Create Flutter DataLoader
    final dataLoader = FlutterDataLoader();

    Map<String, Morning> offlineMorning =
        await ferialMorningResolution(offlineCalendar, dateTime, dataLoader);

    return offlineMorning;
  }

// TODO: add a internet listener so that when internet comes back, it loads what needed.
  Future<Map?> _getAELFLiturgyOnWeb(
      String? type, String date, String region) async {
    Uri uri;
    type == 'informations'
        ? uri = Uri.https(
            apiEpitreCo, '82/office/$type/$date.json', {'region': region})
        : uri = Uri.https(apiAelf, 'v1/$type/$date/$region');
    // get aelf content in their web api
    // TODO: move this http client upper, so that it would be used for bulk downloads.
    final httpClient = HttpClient();
    httpClient.userAgent = userAgent;
    print('downloading: $uri');
    final request = await httpClient.getUrl(
      uri,
    );
    final response = await request.close();
    final data = await response.transform(utf8.decoder).join();
    httpClient.close();
    if (response.statusCode == 200) {
      Map obj = json.decode(data);
      obj.removeWhere((key, value) => key != type);
      return obj;
    } else if (response.statusCode == 404) {
      // this liturgy does not exist -> return message
      Map? obj = json.decode(
          """{"$type": {"erreur_technique": "Nous n'avons pas trouvé cette lecture."}}""");
      return obj;
    } else {
      // If the server did not return a 200 OK response,
      Map? obj = json.decode(
          """{type: {"erreur_technique": "La connexion au serveur a échoué."}}""");
      return obj;
    }
  }

  void autoSaveLiturgy() async {
    print("auto save");
    // for n days, get futur date, check if each type of liturgy exist and download else...
    for (int i = 0; i < nbDaysSaved; i++) {
      String saveDate = getDifferedDateAdd(i);
      //String region = await getPrefRegion() ?? "romain";
      for (var type in types) {
        liturgyDbHelper.checkIfExist(saveDate, type, region).then((rep) {
          if (!rep) {
            // get content from aelf server
            _getAELFLiturgyOnWeb(type, saveDate, region).then((content) {
              if (content.toString().contains("erreur_technique")) {
                print(
                    "_getAELFLiturgyOnWeb: $content, $saveDate, $type, $region");
              } else {
                // save liturgy
                saveToDb(type, saveDate, json.encode(content), region);
              }
            });
          }
        });
      }
    }
    // delete bible n days before
    String deleteDate = getDifferedDateSub(nbDaysSavedBefore);
    liturgyDbHelper.deleteBibleDbBeforeDays(deleteDate);
  }

  String getDifferedDateAdd(int nbDays) {
    return today.add(Duration(days: nbDays)).toString().substring(0, 10);
  }

  String getDifferedDateSub(int nbDays) {
    return today.subtract(Duration(days: nbDays)).toString().substring(0, 10);
  }

  void saveToDb(String type, String date, String content, String region) {
    Liturgy element = Liturgy(
      date: date,
      type: type,
      content: content,
      region: region,
    );
    liturgyDbHelper.insert(element);
    // ignore: prefer_interpolation_to_compose_strings
    print("saved " + date + ' ' + type + ' ' + region);
  }
}
