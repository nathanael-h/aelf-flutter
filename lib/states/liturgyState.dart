import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:aelf_flutter/models/office_header_info.dart';
import 'package:aelf_flutter/utils/flutter_data_loader.dart';
import 'package:aelf_flutter/utils/liturgyDbHelper.dart';
import 'package:aelf_flutter/utils/location_service.dart';
import 'package:aelf_flutter/utils/region_sync.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:aelf_flutter/utils/user_agent.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(),
);

class LiturgyState extends ChangeNotifier {
  String date = "${DateTime.now().toLocal()}".split(' ')[0];
  String region = 'romain';
  String offlineRegion = 'romain';

  /// French display name of the current offline location (e.g. "France",
  /// "Lyon", "Calendrier romain"), cached synchronously so the drawer header can
  /// render it without awaiting [locationDisplayLabel].
  String offlineRegionLabel = 'Calendrier romain';

  /// The offline-liturgy location id for the current [offlineRegion]
  /// (e.g. belgique -> belgium). See `utils/region_sync.dart`.
  String get _liturgyId => liturgyIdFor(offlineRegion);

  /// Infers the online region string from an offline locationId by walking up
  /// the parent chain. Returns 'romain' if no match is found.
  ///
  /// The rule itself lives in `utils/region_sync.dart` so it can be asserted
  /// against the whole real location tree without building a [LiturgyState].
  Future<String> inferOnlineRegion(String locationId) async {
    final data = await _liturgyData;
    return inferOnlineRegionFor(locationId, data.locationData);
  }

  String liturgyType = 'messes';
  final LiturgyDbHelper liturgyDbHelper = LiturgyDbHelper.instance;
  // aelf settings
  String apiAelf = 'api.aelf.org';
  String apiEpitreCo = 'api.app.epitre.co';
  Map? aelfJson;

  /// The `informations` block for the current [date] + [region], powering the
  /// online offices/mass drawer header (day, liturgical year/week, region).
  /// Loaded by [_loadInformations]; null until the first
  /// online office loads, or when offline/unreachable. See
  /// `LeftMenuOfficeHeader` / `OfficeHeaderInfo.fromApi`.
  Map? informationsJson;
  // Latest in-flight informations request, so a slow older response cannot
  // overwrite a newer date/region (mirrors the sequencing gap noted below).
  String? _informationsRequestKey;
  String userAgent = '';
  Calendar offlineCalendar = Calendar();
  // Region for which offlineCalendar was last computed — used to detect cache invalidation
  String? _calendarRegion;
  // In-flight calendar computation — concurrent callers await this instead of starting a new one.
  Future<void>? _calendarFuture;
  // Loaded once at startup; all calendar builds wait on this future.
  late final Future<LiturgyData> _liturgyData;
  Map<String, ComplineDefinition> offlineComplines = {};
  Map<String, CelebrationContext> offlineMorning = {};
  Map<String, CelebrationContext> offlineReadings = {};
  Map<String, CelebrationContext> offlineMiddleOfDay = {};
  Map<String, CelebrationContext> offlineVespers = {};
  Map<String, CelebrationContext> offlineMass = {};
  // Set when an offline_* fetch below fails; cleared at the start of the
  // next updateLiturgy() call. Lets the UI show an error instead of an
  // indefinite spinner (the Map staying empty looks identical to "still loading").
  String? offlineLoadError;
  bool useImprecatoryVerses = false;
  bool useScrollMode = false;
  bool psalmSvgEnabled = false;
  String psalmSvgSource = 'seminaire-emmanuel';
  bool isFullScreen = false;
  bool? _scrollModeBeforeFullScreen;
  String? epiphanyDateOverride;
  String? ascensionDateOverride;
  String? corpusDominiDateOverride;
  // Effective values from the selected location (used as display default when no override is set).
  String locationEpiphanyDate = 'day';
  String locationAscensionDate = 'thursday';
  String locationCorpusDominiDate = 'sunday';

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
    _liturgyData = LiturgyData.loadFromDataLoader(FlutterDataLoader());
    // FIXME: both initRegion() and initImprecatoryVerses() call updateLiturgy()
    // + autoSaveLiturgy(), so each runs twice (concurrently) at startup —
    // duplicate DB/network work. Consolidate to a single post-init trigger.
    // TODO: these init*() are `async void`; errors are swallowed. Convert to
    // Future<void> and await them in a single orchestrating initializer.
    initRegion();
    initOfflineRegion();
    initUserAgent();
    initImprecatoryVerses();
    initScrollMode();
    initEpiphanyAscension();
    initPsalmSvg();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Several fetches finish through `.then()` / `await` continuations that
  /// outlive the state (see the sequencing FIXME in [updateLiturgy]). Dropping
  /// the notification once disposed keeps a late AELF response from throwing
  /// "A LiturgyState was used after being disposed" instead of being ignored.
  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
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
      if (isFullScreen) exitFullScreen();
      updateLiturgy();
      notifyListeners();
      log('liturgyType set to $newLiturgyType');
    } else {
      log('liturgyType == newLiturgyType, $newLiturgyType');
    }
  }

  Future<void> updateLiturgy() async {
    final offlineEnabled = await getFeatureOfflineLiturgy();

    if (!offlineEnabled && liturgyType.startsWith('offline_')) {
      _clearOfflineData();
      notifyListeners();
      return;
    }

    // FIXME: the offline branches below assign their .then() result
    // unconditionally with no request sequencing. Rapid date/region/type
    // changes can let an older future resolve after a newer one and overwrite
    // with stale content. Add a per-request token (capture a sequence int and
    // ignore results that aren't the latest) like the AELF branch's guard.
    final parsedDate = DateTime.parse(date);
    if (liturgyType.startsWith('offline_') &&
        liturgyType != 'offline_calendar') {
      offlineLoadError = null;
    }
    void onOfflineLoadError(Object e, StackTrace st) {
      log('updateLiturgy($liturgyType) failed: $e\n$st');
      offlineLoadError = e.toString();
      notifyListeners();
    }

    switch (liturgyType) {
      case 'offline_complines':
        gotOfflineComplines(liturgyType, parsedDate, _liturgyId)
            .then<void>((value) {
          offlineComplines = value;
          notifyListeners();
        }).catchError(onOfflineLoadError);

      case 'offline_morning':
        getOfflineMorning(parsedDate, _liturgyId).then<void>((value) {
          offlineMorning = value;
          notifyListeners();
        }).catchError(onOfflineLoadError);

      case 'offline_readings':
        getOfflineReadings(parsedDate, _liturgyId).then<void>((value) {
          offlineReadings = value;
          notifyListeners();
        }).catchError(onOfflineLoadError);

      case 'offline_tierce':
      case 'offline_sexte':
      case 'offline_none':
        getOfflineMiddleOfDay(parsedDate, _liturgyId).then<void>((value) {
          offlineMiddleOfDay = value;
          notifyListeners();
        }).catchError(onOfflineLoadError);

      case 'offline_vespers':
        getOfflineVespers(parsedDate, _liturgyId).then<void>((value) {
          offlineVespers = value;
          notifyListeners();
        }).catchError(onOfflineLoadError);

      case 'offline_mass':
        getOfflineMass(parsedDate, _liturgyId).then<void>((value) {
          offlineMass = value;
          notifyListeners();
        }).catchError(onOfflineLoadError);

      case 'offline_calendar':
        break; // calendar builds its own data — no server fetch needed.

      default:
        _getAELFLiturgy(liturgyType, date, region).then((value) {
          if (aelfJson != value) {
            aelfJson = value;
            notifyListeners();
          } else {
            log('aelfJson == newAelfJson');
          }
        });
        // Refresh the drawer-header metadata alongside the office content.
        _loadInformations();
    }
  }

  /// Loads the `informations` block for the current [date] + [region] into
  /// [informationsJson] (drawer header only — independent of the office
  /// content). Additive: never touches [aelfJson] or the offline data.
  Future<void> _loadInformations() async {
    final key = '$date|$region';
    _informationsRequestKey = key;
    try {
      final value = await _getAELFLiturgy('informations', date, region);
      // Drop a stale response that resolved after a newer date/region change.
      if (_informationsRequestKey != key) return;
      final block = value?['informations'];
      final Map? newInformations = block is Map ? block : null;
      if (informationsJson != newInformations) {
        informationsJson = newInformations;
        notifyListeners();
      }
    } catch (e) {
      log('_loadInformations failed: $e');
    }
  }

  /// The `CelebrationContext` map of the active offline office, or null for
  /// offices with none loaded (complines, calendar).
  Map<String, CelebrationContext>? get _activeOfflineOfficeMap {
    switch (liturgyType) {
      case 'offline_morning':
        return offlineMorning;
      case 'offline_readings':
        return offlineReadings;
      case 'offline_tierce':
      case 'offline_sexte':
      case 'offline_none':
        return offlineMiddleOfDay;
      case 'offline_vespers':
        return offlineVespers;
      case 'offline_mass':
        return offlineMass;
      default:
        return null;
    }
  }

  /// Every celebrable celebration of the active offline office (the concurring
  /// feasts of the day), for the drawer header's one-square-per-feast list.
  /// Falls back to the single first entry when none is flagged celebrable.
  List<CelebrationContext> get offlineCelebrations {
    final map = _activeOfflineOfficeMap;
    if (map == null || map.isEmpty) return const <CelebrationContext>[];
    final celebrable =
        map.values.where((c) => c.isCelebrable).toList(growable: false);
    return celebrable.isNotEmpty
        ? celebrable
        : <CelebrationContext>[map.values.first];
  }

  /// The primary celebration of the active offline office: the first celebrable
  /// entry (the offline views' default). Null when the office has none loaded.
  CelebrationContext? get primaryOfflineCelebration {
    final list = offlineCelebrations;
    return list.isEmpty ? null : list.first;
  }

  static const _frenchWeekdays = <String>[
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  /// The header degree label for an offline celebration, matching the online
  /// wording. `precedence` follows the offline_liturgy scale (see
  /// `getCelebrationTypeLabel`); ferial ranks (≥ 13) show "Férie".
  static String? _offlineDegree(int? precedence) {
    switch (precedence) {
      case 3:
      case 4:
        return 'Solennité';
      case 5:
      case 7:
      case 8:
        return 'Fête';
      case 10:
      case 11:
        return 'Mémoire obligatoire';
      case 12:
        return 'Mémoire facultative';
    }
    return (precedence ?? 13) >= 13 ? 'Férie' : null;
  }

  /// Matches "dimanche" (case-insensitive) inside a Sunday's celebration
  /// title, e.g. "Vingt-cinquième Dimanche du Temps Ordinaire" — used to
  /// shorten it to "Vingt-cinquième Dimanche", the season itself coming from
  /// [liturgicalTimeLabels] instead (so it reads "Temps Ordinaire", not
  /// "du Temps Ordinaire" — the title's own trailing wording varies with the
  /// connector each season uses: "du", "de", "de l'"…).
  static final RegExp _sundayMarker = RegExp('dimanche', caseSensitive: false);

  /// The short title ("Vingt-cinquième Dimanche") from a Sunday's [title],
  /// or null when [title] doesn't contain "dimanche" (i.e. it's not a
  /// Sunday-of-season title but a named feast's own title instead).
  static String? _sundayShortTitle(String title) {
    final match = _sundayMarker.firstMatch(title);
    return match == null ? null : title.substring(0, match.end);
  }

  /// Seasons whose ferial days are counted in numbered weeks. Christmas time
  /// has no such count in common usage, so its ferials show the season name
  /// alone.
  static const _numberedWeekSeasons = <String>{
    'ot',
    'advent',
    'lent',
    'easter'
  };

  /// Matches a ferial code `season_week_day` (e.g. "ot_25_4"), optionally
  /// dated (Advent 17–24: "advent-18_3_5") or followed by a variant suffix
  /// ("easter_6_3_before_ascension"), capturing the liturgical week.
  static final RegExp _ferialCodePattern =
      RegExp(r'^[a-z]+(?:-\d+)?_(\d+)_\d+(?:_.+)?$');

  /// The key of [liturgicalTimeLabels] / [liturgicalTimeLabelsDative] for a
  /// calendar [liturgicalTime]: offline_liturgy tags Easter time
  /// 'paschaltime' but keys its label tables by 'easter'.
  static String? _labelKey(String? liturgicalTime) =>
      liturgicalTime == 'paschaltime' ? 'easter' : liturgicalTime;

  /// Whether the day's primary celebration is a plain ferial day, i.e. there
  /// is no feast to headline (the header then shows the weekday). True for
  /// precedence 13, and for the privileged ferials of Lent and of Advent
  /// 17–24 (precedence 9) as long as the ferial itself is what's celebrated.
  /// Ash Wednesday, Holy Week and the Easter/Christmas octaves are not: their
  /// own titles carry information.
  @visibleForTesting
  static bool isPlainFerial({
    int? precedence,
    String? celebrationCode,
    String? ferialCode,
    String? liturgicalTime,
  }) {
    final rank = precedence ?? 13;
    if (rank >= 13) return true;
    return rank == 9 &&
        celebrationCode == ferialCode &&
        (liturgicalTime == 'lent' || liturgicalTime == 'advent');
  }

  /// The season/week line of a ferial day: "{n}ème semaine {season}" (e.g.
  /// "25ème semaine du Temps Ordinaire"), with [n] the *liturgical* week read
  /// from [ferialCode] — not the 1–4 breviary (psalter) week. Falls back to
  /// the season name alone ("Carême", "Temps de Noël") when the season has no
  /// numbered weeks or [ferialCode] carries none (e.g. "lent_0_4", the days
  /// after Ash Wednesday). Null when [liturgicalTime] is unknown.
  @visibleForTesting
  static String? ferialSeasonText(String? liturgicalTime, String? ferialCode) {
    final key = _labelKey(liturgicalTime);
    final seasonName = liturgicalTimeLabels[key];
    if (!_numberedWeekSeasons.contains(key)) return seasonName;
    final match = _ferialCodePattern.firstMatch(ferialCode ?? '');
    final week = match == null ? 0 : int.parse(match.group(1)!);
    if (week == 0) return seasonName;
    final ordinal = week == 1 ? '1ère' : '$weekème';
    return '$ordinal semaine ${liturgicalTimeLabelsDative[key]}';
  }

  /// Assembles the offline offices/mass drawer header: the day's primary
  /// celebration as title + degree, a Sunday's short title + season, or the
  /// plain weekday + season/week on a ferial day; liturgical year
  /// (paire/impaire) and psalter week. Region-only until the office + calendar
  /// have loaded for [date].
  OfficeHeaderInfo get offlineHeaderInfo {
    final parsedDate = DateTime.tryParse(date);
    final celebrations = offlineCelebrations;
    final primary = celebrations.isNotEmpty ? celebrations.first : null;
    // A plain ferial day has nothing to headline, so fall back to the weekday.
    final bool isFerial = isPlainFerial(
      precedence: primary?.precedence,
      celebrationCode: primary?.celebrationCode,
      ferialCode: primary?.ferialCode,
      liturgicalTime: primary?.liturgicalTime,
    );
    final String? primaryTitle = primary?.celebrationTitle;
    final bool hasPrimaryTitle =
        !isFerial && primaryTitle != null && primaryTitle.isNotEmpty;

    String? day;
    String? degree;
    String? seasonText;
    final sundayTitle =
        hasPrimaryTitle ? _sundayShortTitle(primaryTitle) : null;
    if (sundayTitle != null) {
      day = sundayTitle;
      seasonText = liturgicalTimeLabels[_labelKey(primary?.liturgicalTime)];
    } else if (hasPrimaryTitle) {
      day = primaryTitle;
      degree = _offlineDegree(primary?.precedence);
    } else if (parsedDate != null) {
      day = _frenchWeekdays[parsedDate.weekday - 1];
    }

    String? yearParity;
    int? week;
    if (parsedDate != null) {
      final dayContent = offlineCalendar.getDayContent(parsedDate);
      if (dayContent != null) {
        yearParity = dayContent.liturgicalYear.isEven ? 'paire' : 'impaire';
        week = dayContent.breviaryWeek;
      }
    }
    week ??= primary?.breviaryWeek;

    // Plain ferial day: no title to split, so build the season/week line
    // from the liturgical week ([week] is the psalter week, shown separately).
    if (degree == null && seasonText == null) {
      seasonText =
          ferialSeasonText(primary?.liturgicalTime, primary?.ferialCode);
    }

    return OfficeHeaderInfo.fromOfflineDay(
      day: day,
      degree: degree,
      seasonText: seasonText,
      colorName: primary?.liturgicalColor,
      liturgicalYear: yearParity,
      psalterWeek: week,
      region: offlineRegion,
    );
  }

  void _clearOfflineData() {
    offlineComplines = {};
    offlineMorning = {};
    offlineReadings = {};
    offlineMiddleOfDay = {};
    offlineVespers = {};
    offlineMass = {};
    offlineLoadError = null;
  }

  static const _validOnlineRegions = kValidOnlineRegions;

  void initRegion() async {
    log('initRegion');
    await getRegion().then((savedRegion) {
      if (_validOnlineRegions.contains(savedRegion)) {
        region = savedRegion;
      } else {
        region = 'france';
        setRegion('france');
      }
    });
    updateLiturgy();
    autoSaveLiturgy();
  }

  void initOfflineRegion() async {
    log('initOfflineRegion');
    offlineRegion = await getOfflineRegion();
    await _refreshOfflineRegionLabel();
    notifyListeners();
  }

  /// Recomputes [offlineRegionLabel] from the current [offlineRegion] using the
  /// location tree. Mirrors [locationDisplayLabel] but caches the result.
  Future<void> _refreshOfflineRegionLabel() async {
    if (offlineRegion == 'romain' || offlineRegion.isEmpty) {
      offlineRegionLabel = 'Calendrier romain';
      return;
    }
    final data = await _liturgyData;
    offlineRegionLabel =
        data.locationData[_liturgyId]?.frenchName ?? 'Calendrier romain';
  }

  /// Selects an offline location from the drawer header's location sheet, using
  /// the same flow as the settings screen (`_onLocationSelected`): persist it,
  /// switch the offline region, and keep the online region roughly aligned by
  /// inference so the API-backed liturgy keeps working.
  Future<void> selectOfflineLocation(String locationId) async {
    await LocationService.setSelectedLocation(locationId);
    updateOfflineRegion(locationId);
    final onlineRegion = await inferOnlineRegion(locationId);
    updateRegion(onlineRegion);
  }

  void initEpiphanyAscension() async {
    log('initEpiphanyAscension');
    epiphanyDateOverride = await getEpiphanyDateOverride();
    ascensionDateOverride = await getAscensionDateOverride();
    corpusDominiDateOverride = await getCorpusDominiDateOverride();
    final data = await _liturgyData;
    locationEpiphanyDate = getEpiphanyDate(_liturgyId, data.locationData);
    locationAscensionDate = getAscensionDate(_liturgyId, data.locationData);
    locationCorpusDominiDate =
        getCorpusDominiDate(_liturgyId, data.locationData);
    notifyListeners();
  }

  void updateEpiphanyDate(String value) {
    if (epiphanyDateOverride != value) {
      log('updateEpiphanyDate to $value');
      epiphanyDateOverride = value;
      setEpiphanyDateOverride(value);
      _calendarRegion = null;
      if (liturgyType.startsWith('offline_')) updateLiturgy();
      notifyListeners();
    }
  }

  void updateAscensionDate(String value) {
    if (ascensionDateOverride != value) {
      log('updateAscensionDate to $value');
      ascensionDateOverride = value;
      setAscensionDateOverride(value);
      _calendarRegion = null;
      if (liturgyType.startsWith('offline_')) updateLiturgy();
      notifyListeners();
    }
  }

  void updateCorpusDominiDate(String value) {
    if (corpusDominiDateOverride != value) {
      log('updateCorpusDominiDate to $value');
      corpusDominiDateOverride = value;
      setCorpusDominiDateOverride(value);
      _calendarRegion = null;
      if (liturgyType.startsWith('offline_')) updateLiturgy();
      notifyListeners();
    }
  }

  void updateOfflineRegion(String newRegion) {
    if (offlineRegion != newRegion) {
      log('updateOfflineRegion to $newRegion');
      offlineRegion = newRegion;
      setOfflineRegion(newRegion);
      // Invalidate the calendar cache so it is recomputed for the new region
      _calendarRegion = null;
      // Refresh location defaults for the new region (used as display default in settings).
      // Use _liturgyId (not newRegion) so app region ids are mapped to offline-liturgy
      // location ids (e.g. belgique->belgium, suisse->switzerland).
      _liturgyData.then((data) {
        locationEpiphanyDate = getEpiphanyDate(_liturgyId, data.locationData);
        locationAscensionDate = getAscensionDate(_liturgyId, data.locationData);
        locationCorpusDominiDate =
            getCorpusDominiDate(_liturgyId, data.locationData);
        offlineRegionLabel =
            (offlineRegion == 'romain' || offlineRegion.isEmpty)
                ? 'Calendrier romain'
                : (data.locationData[_liturgyId]?.frenchName ??
                    'Calendrier romain');
        notifyListeners();
      });
      if (liturgyType.startsWith('offline_')) {
        updateLiturgy();
      }
      notifyListeners();
    } else {
      log('offlineRegion == newRegion');
    }
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
    // device_info is best-effort: it is a plugin, so it is unavailable in
    // tests and can fail on an unusual host. initUserAgent is called
    // unawaited from the constructor, so an escaping error would surface as an
    // unhandled async exception; a vaguer User-Agent is a much better outcome.
    try {
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
            print(
                "Couldn't read file /sys/devices/virtual/dmi/id/product_name");
          }
          // See linuxOsVersion: BUILD_ID is absent on Debian-family systems.
          osVersion = linuxOsVersion(linuxDeviceInfo.id,
              linuxDeviceInfo.buildId, linuxDeviceInfo.versionId);
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
    } catch (e) {
      log('device info unavailable, User-Agent will be less specific: $e');
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

  /// Whether the device reports a usable connection.
  ///
  /// Connectivity reporting is best-effort, and on Linux it is fragile:
  /// connectivity_plus reaches NetworkManager over D-Bus, so it fails wherever
  /// there is no system bus, no NetworkManager, or no permission to reach it —
  /// a minimal desktop, a confined snap, a CI container.
  ///
  /// It fails badly. The error surfaces from a D-Bus signal-stream listener
  /// rather than from the future we await, so a try/catch never sees it *and
  /// the future never completes*. Awaiting it directly would hang
  /// [_getAELFLiturgy] forever and the liturgy would simply never appear.
  ///
  /// So: run the check in a guarded zone, and complete from whichever comes
  /// first — the answer, the orphaned error, or a timeout. When in doubt
  /// assume connected; the HTTP request reports its own failure as an
  /// `erreur_technique`, which beats refusing to try.
  Future<bool> _hasNetwork() {
    final completer = Completer<bool>();
    void finish(bool value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    runZonedGuarded(() async {
      final results = await Connectivity().checkConnectivity();
      finish(results.isEmpty || results.first != ConnectivityResult.none);
    }, (error, stack) {
      log('connectivity check failed, assuming online: $error');
      finish(true);
    });

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        log('connectivity check timed out, assuming online');
        return true;
      },
    );
  }

  Future<Map?> _getAELFLiturgy(String type, String date, String region) async {
    print('$date $type $region');
    // rep - server or db response
    Liturgy? rep = await liturgyDbHelper.getRow(date, type, region);

    if (rep != null) {
      Map? obj = json.decode(rep.content!);
      //_displayAelfLiturgy(obj);
      print("db yes");
      return obj;
    } else {
      print("db no");
      //check internet connection
      if (await _hasNetwork()) {
        return _getAELFLiturgyOnWeb(type, date, region);
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

  Future<List<LocationNode>> get locationTree async {
    final data = await _liturgyData;
    return data.locationTree;
  }

  /// Ensures offlineCalendar covers [date] for [region].
  /// Recomputes only when the region changed or the date falls outside
  /// the already-computed range. Uses getDayContent() as a range probe
  /// since getCalendar() covers ~2 liturgical years.
  Future<void> _ensureCalendar(DateTime date, String region) async {
    // If a computation is already running, wait for it before re-checking.
    final ongoing = _calendarFuture;
    if (ongoing != null) {
      await ongoing;
      if (_calendarRegion == region &&
          offlineCalendar.getDayContent(date) != null) {
        log('Calendar satisfied after coalescing: $date / $region');
        return;
      }
    }

    if (_calendarRegion == region &&
        offlineCalendar.getDayContent(date) != null) {
      log('Calendar cache hit: $date / $region');
      return;
    }

    log('Calendar compute: $date / $region');
    _calendarFuture = () async {
      final data = await _liturgyData;
      offlineCalendar = getCalendar(Calendar(), date, region, data,
          epiphanyOverride: epiphanyDateOverride,
          ascensionOverride: ascensionDateOverride,
          corpusDominiOverride: corpusDominiDateOverride);
      _calendarRegion = region;
    }();
    try {
      await _calendarFuture;
    } finally {
      _calendarFuture = null;
    }
  }

  Future<Map<String, ComplineDefinition>> gotOfflineComplines(
      String type, DateTime dateTime, String region) async {
    print("getNewOfflineCompline called for $type, $dateTime, $region");

    // Create Flutter DataLoader
    final dataLoader = FlutterDataLoader();

    await _ensureCalendar(dateTime, region);
    //  String calendarDisplay = offlineCalendar.formattedDisplay;
    //  logger.d(calendarDisplay);

    // Retrieving and returning the list of possible Complines
    Map<String, ComplineDefinition> possibleComplines =
        await complineDetection(offlineCalendar, dateTime, dataLoader);

    return possibleComplines;
    /*
  Map<String, Compline> complineTextCompiled =
      complineTextCompilation(possibleComplines);
  return complineTextCompiled;
  */
  }

  Future<Map<String, CelebrationContext>> getOfflineMorning(
      DateTime dateTime, String region) async {
    print("getOfflineMorning called for $dateTime, $region");

    // Create Flutter DataLoader
    final dataLoader = FlutterDataLoader();
    await _ensureCalendar(dateTime, region);
    //  String calendarDisplay = offlineCalendar.formattedDisplay;
    //  logger.d(calendarDisplay);
    Map<String, CelebrationContext> offlineMorning =
        await morningDetection(offlineCalendar, dateTime, dataLoader);
    return offlineMorning;
  }

  Future<Map<String, CelebrationContext>> getOfflineReadings(
      DateTime dateTime, String region) async {
    print("getOfflineReadings called for $dateTime, $region");

    // Create Flutter DataLoader
    final dataLoader = FlutterDataLoader();
    await _ensureCalendar(dateTime, region);
    //  String calendarDisplay = offlineCalendar.formattedDisplay;
    //  logger.d(calendarDisplay);
    Map<String, CelebrationContext> offlineReadings =
        await readingsDetection(offlineCalendar, dateTime, dataLoader);
    return offlineReadings;
  }

  Future<Map<String, CelebrationContext>> getOfflineMiddleOfDay(
      DateTime dateTime, String region) async {
    print("getOfflineMiddleOfDay called for $dateTime, $region");

    final dataLoader = FlutterDataLoader();
    await _ensureCalendar(dateTime, region);
    Map<String, CelebrationContext> offlineMiddleOfDay =
        await middleOfDayDetection(offlineCalendar, dateTime, dataLoader);
    return offlineMiddleOfDay;
  }

  Future<Map<String, CelebrationContext>> getOfflineVespers(
      DateTime dateTime, String region) async {
    print("getOfflineVespers called for $dateTime, $region");

    // Create Flutter DataLoader
    final dataLoader = FlutterDataLoader();
    await _ensureCalendar(dateTime, region);
    Map<String, CelebrationContext> offlineVespers =
        await vespersDetection(offlineCalendar, dateTime, dataLoader);
    return offlineVespers;
  }

  Future<Map<String, CelebrationContext>> getOfflineMass(
      DateTime dateTime, String region) async {
    print("getOfflineMass called for $dateTime, $region");

    // Create Flutter DataLoader
    final dataLoader = FlutterDataLoader();
    await _ensureCalendar(dateTime, region);
    Map<String, CelebrationContext> offlineMass =
        await massDetection(offlineCalendar, dateTime, dataLoader);
    return offlineMass;
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
          """{"$type": {"erreur_technique": "La connexion au serveur a échoué."}}""");
      return obj;
    }
  }

  void autoSaveLiturgy() async {
    print("auto save");
    final offlineEnabled = await getFeatureOfflineLiturgy();
    final List<String> typesToSave = offlineEnabled ? ['messes'] : types;
    for (int i = 0; i < nbDaysSaved; i++) {
      String saveDate = getDifferedDateAdd(i);
      for (var type in typesToSave) {
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

  /// Builds a full calendar for the liturgical year ending in [year].
  /// Returns a new Calendar without touching offlineCalendar.
  Future<Calendar> buildCalendarForYear(int year) async {
    final data = await _liturgyData;
    return getCalendar(
      Calendar(),
      DateTime(year, 7, 1),
      _liturgyId,
      data,
      epiphanyOverride: epiphanyDateOverride,
      ascensionOverride: ascensionDateOverride,
      corpusDominiOverride: corpusDominiDateOverride,
    );
  }

  /// French display label for the current offline region.
  Future<String> get locationDisplayLabel async {
    if (offlineRegion == 'romain' || offlineRegion.isEmpty) {
      return 'Calendrier romain';
    }
    final data = await _liturgyData;
    final loc = data.locationData[_liturgyId];
    return loc?.frenchName ?? 'Calendrier romain';
  }

  void initImprecatoryVerses() async {
    log('initImprecatoryVerses');
    await getImprecatoryVerses().then((savedImprecatoryVerses) {
      useImprecatoryVerses = savedImprecatoryVerses;
    });
    updateLiturgy();
    autoSaveLiturgy();
  }

  void updateImprecatoryVerses(bool bool) {
    if (useImprecatoryVerses != bool) {
      log('updateImprecatoryVerses to $bool');
      useImprecatoryVerses = bool;
      setImprecatoryVerses(bool);
      updateLiturgy();
      notifyListeners();
    } else {
      log('updateImprecatoryVerses is already set to $bool');
    }
  }

  void initScrollMode() async {
    useScrollMode = await getScrollMode();
    notifyListeners();
  }

  void updateScrollMode(bool value) {
    if (useScrollMode != value) {
      useScrollMode = value;
      setScrollMode(value);
      notifyListeners();
    }
  }

  void initPsalmSvg() async {
    psalmSvgEnabled = await getPsalmSvgEnabled();
    psalmSvgSource = await getPsalmSvgSource();
    notifyListeners();
  }

  void updatePsalmSvgEnabled(bool value) {
    if (psalmSvgEnabled != value) {
      psalmSvgEnabled = value;
      setPsalmSvgEnabled(value);
      notifyListeners();
    }
  }

  void updatePsalmSvgSource(String value) {
    if (psalmSvgSource != value) {
      psalmSvgSource = value;
      setPsalmSvgSource(value);
      notifyListeners();
    }
  }

  void enterFullScreen() {
    _scrollModeBeforeFullScreen = useScrollMode;
    useScrollMode = true;
    isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen() {
    final previous = _scrollModeBeforeFullScreen ?? false;
    useScrollMode = previous;
    setScrollMode(previous);
    _scrollModeBeforeFullScreen = null;
    isFullScreen = false;
    notifyListeners();
  }
}
