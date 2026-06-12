import 'dart:async';
import 'dart:io' show Platform;
import 'package:aelf_flutter/app_screens/about_screen.dart';
import 'package:aelf_flutter/app_screens/bible_lists_screen.dart';
import 'package:aelf_flutter/app_screens/bible_search_screen.dart';
import 'package:aelf_flutter/app_screens/liturgy_screen.dart';
import 'package:aelf_flutter/app_screens/settings_screen.dart';
import 'package:aelf_flutter/data/app_sections.dart';
import 'package:aelf_flutter/data/popup_menu_choices.dart';
import 'package:aelf_flutter/utils/datepicker.dart';
import 'package:aelf_flutter/models/popup_menu_choice.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/pageState.dart';
import 'package:aelf_flutter/utils/share_helper.dart';
import 'package:aelf_flutter/widgets/left_menu.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AelfHomePage extends StatefulWidget {
  const AelfHomePage({Key? key}) : super(key: key);

  @override
  AelfHomePageState createState() => AelfHomePageState();
}

class AelfHomePageState extends State<AelfHomePage>
    with WidgetsBindingObserver {
  final _pageController = PageController(initialPage: 1);
  String? chapter;
  String? version;

  // Custom date picker helper
  final DatePickerHelper _datePickerHelper = DatePickerHelper();

  String? selectedDateMenu; // Label shown in the AppBar
  String? selectedDateRaw; // ISO string for API calls (YYYY-MM-DD)
  DateTime? lastCheckedDateTime;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static const _displayChannel = MethodChannel('aelf_flutter/display');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyImmersiveMode();

    // Initialize version info
    _getPackageVersion();

    // Network connectivity logic — intentionally not awaited: listener setup
    // runs in background and does not block widget initialization.
    unawaited(_initNetworkLogic());

    // Initial date setup
    lastCheckedDateTime = DateTime.now();
    selectedDateRaw = _datePickerHelper.getRawDateString();
    selectedDateMenu = _datePickerHelper.formatToPrettyString(longView: false);

    // Determine which office to show based on current time
    _computeCurrentOffice();

    // Timer to auto-refresh "Today" label if the app stays open past midnight
    _timer = Timer.periodic(
        const Duration(minutes: 1), (Timer t) => _updateDateAtMidnight());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applyImmersiveMode();
  }

  @override
  void didChangeMetrics() => _applyImmersiveMode();

  // NOTE: two distinct fullscreen mechanisms coexist and are orthogonal:
  //  - _applyImmersiveMode() below controls the OS system bars (always on).
  //  - liturgyState.isFullScreen hides the in-app AppBar/menu (offline only).
  /// Re-applies the reading display mode. Faithful port of the native Android
  /// app's prepare_fullscreen(): edge-to-edge behind translucent system bars
  /// (the status bar stays visible, not hidden) plus SYSTEM_UI_FLAG_LOW_PROFILE
  /// on Android to dim the bar icons, applied via a platform channel.
  void _applyImmersiveMode() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (Platform.isAndroid) {
        _displayChannel.invokeMethod('applyLowProfile');
      }
    }
  }

  /// Refreshes the date automatically if the day changes while the app is running
  void _updateDateAtMidnight() {
    final now = DateTime.now();
    if (now.day != lastCheckedDateTime!.day) {
      setState(() {
        lastCheckedDateTime = now;
        _datePickerHelper.selectedDate = now;
        selectedDateRaw = _datePickerHelper.getRawDateString();
        selectedDateMenu =
            _datePickerHelper.formatToPrettyString(longView: false);
      });
    }
  }

  /// Groups network initialization for clarity
  Future<void> _initNetworkLogic() async {
    // Check initial state
    var connectivityResults = await Connectivity().checkConnectivity();
    _handleConnectivityChange(connectivityResults);

    // Listen for changes
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // The stream can fire after the widget is disposed; guard the context use.
    if (!mounted) return;

    bool hasConnection = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    final liturgyState = context.read<LiturgyState>();
    // Offline types load from local assets — connectivity is irrelevant.
    if (hasConnection && !liturgyState.liturgyType.startsWith('offline_')) {
      liturgyState.updateLiturgy();
    }
  }

  /// Logic to auto-select the current prayer office based on time
  Future<void> _computeCurrentOffice() async {
    final int hour = DateTime.now().hour;
    final bool isSunday = DateTime.now().weekday == DateTime.sunday;
    String sectionName;

    if (hour < 3) {
      sectionName = 'complies';
    } else if (hour < 4) {
      sectionName = 'lectures';
    } else if (hour < 8) {
      sectionName = 'laudes';
    } else if (hour < 15 && isSunday) {
      sectionName = 'messes';
    } else if (hour < 10) {
      sectionName = 'tierce';
    } else if (hour < 13) {
      sectionName = 'sexte';
    } else if (hour < 16) {
      sectionName = 'none';
    } else if (hour < 21) {
      sectionName = 'vepres';
    } else {
      sectionName = 'complies';
    }

    final offlineEnabled = await getFeatureOfflineLiturgy();
    if (offlineEnabled) {
      const offlineMap = {
        'laudes': 'offline_morning',
        'lectures': 'offline_readings',
        'tierce': 'offline_tierce',
        'sexte': 'offline_sexte',
        'none': 'offline_none',
        'vepres': 'offline_vespers',
        'complies': 'offline_complines',
      };
      sectionName = offlineMap[sectionName] ?? sectionName;
    }

    // Scheduling UI update after the first frame to avoid provider conflicts
    Future.microtask(() {
      if (!mounted) return;

      final int sectionIdx = _getAppSectionFromName(sectionName);
      // indexWhere returns -1 if the section is unknown; bail out rather than
      // throwing a RangeError on appSections[sectionIdx].
      if (sectionIdx < 0) return;
      final section = appSections[sectionIdx];

      context.read<LiturgyState>().updateLiturgyType(sectionName);

      context.read<PageState>().changeSectionAll(
            section: sectionIdx,
            searchVisible: section.searchVisible,
            datePickerVisible: section.datePickerVisible,
            title: section.title,
          );
    });
  }

  int _getAppSectionFromName(String name) {
    return appSections.indexWhere((e) => e.name.toLowerCase() == name);
  }

  /// Opens the Date Picker and syncs the UI/State
  Future<void> _handleDatePicker() async {
    bool hasChanged = await _datePickerHelper.selectDate(context);

    if (hasChanged && mounted) {
      String newRawDate = _datePickerHelper.getRawDateString();

      // Update data state
      context.read<LiturgyState>().updateDate(newRawDate);

      // Update UI state
      setState(() {
        selectedDateRaw = newRawDate;
        selectedDateMenu =
            _datePickerHelper.formatToPrettyString(longView: false);
      });
    }
  }

  void _onMenuChoiceSelected(PopupMenuChoice choice) {
    if (choice.title == 'A propos') {
      About(version).popUp(context);
    } else if (choice.title == 'Paramètres') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SettingsMenu()));
    }
  }

  void _getPackageVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        version = '${packageInfo.version}.${packageInfo.buildNumber}';
      });
      _showAboutPopUp();
    }
  }

  void _showAboutPopUp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastVersion = prefs.getString(keyLastVersionInstalled);

    if (version != null && lastVersion != version) {
      // Small delay to ensure the UI is ready
      // TODO: persist keyLastVersionInstalled even if unmounted within 500ms,
      // otherwise the "what's new" popup reappears on the next launch.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          About(version).popUp(context);
          prefs.setString(keyLastVersionInstalled, version!);
        }
      });
    }
  }

  void _pushBibleSearchScreen() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => BibleSearchScreen()));
  }

  // TODO(share): add _isSharing guard to prevent double-tap opening two share sheets.
  Future<void> _handleShare() async {
    final pageState = context.read<PageState>();
    final liturgyState = context.read<LiturgyState>();
    await ShareHelper.shareLiturgy(
      title: pageState.title,
      liturgyType: liturgyState.liturgyType,
      date: liturgyState.date,
      region: liturgyState.region,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we are on a tablet/desktop to adapt layout
    final screenSize = MediaQuery.of(context).size;
    bool isBigScreen = (screenSize.width > 800);
    final isLandscape = screenSize.width > screenSize.height;

    return Consumer<PageState>(
      builder: (context, pageState, child) {
        // TODO: guard activeAppSection against an out-of-range index for
        // consistency with the `sectionIdx < 0` check in _computeCurrentOffice.
        final sectionName = appSections[pageState.activeAppSection].name;
        final liturgyState = context.watch<LiturgyState>();
        final shareVisible = sectionName != 'bible' &&
            ShareHelper.slugFor(liturgyState.liturgyType) != null;
        final isFullScreen = liturgyState.isFullScreen;
        final showFullScreenButton =
            liturgyState.liturgyType.startsWith('offline_') &&
                liturgyState.liturgyType != 'offline_calendar';
        return Scaffold(
          appBar: isFullScreen
              ? null
              : AppBar(
                  title: Text(pageState.title),
                  actions: <Widget>[
                    // Bible Search Button
                    Visibility(
                        visible: pageState.searchVisible,
                        child: IconButton(
                          tooltip: "Rechercher dans la Bible",
                          onPressed: _pushBibleSearchScreen,
                          icon: const Icon(Icons.search, color: Colors.white),
                        )),

                    // Date Picker Button
                    Visibility(
                      visible: pageState.datePickerVisible,
                      child: TextButton(
                        onPressed: _handleDatePicker,
                        child: Text(
                          selectedDateMenu ?? "Aujourd'hui",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    // Share Button
                    Visibility(
                      visible: shareVisible,
                      child: IconButton(
                        tooltip: "Partager",
                        onPressed: _handleShare,
                        icon: const Icon(Icons.share, color: Colors.white),
                      ),
                    ),

                    // Settings/About Menu
                    PopupMenuButton<PopupMenuChoice>(
                      color: Theme.of(context).drawerTheme.backgroundColor ??
                          Theme.of(context).colorScheme.surface,
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: _onMenuChoiceSelected,
                      itemBuilder: (BuildContext context) {
                        return popupMenuChoices.map((PopupMenuChoice choice) {
                          return PopupMenuItem<PopupMenuChoice>(
                            value: choice,
                            child: Row(
                              children: [
                                Text(choice.title!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color)),
                                const Spacer(),
                                choice.widget ?? const SizedBox.shrink(),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    )
                  ],
                ),
          body: Stack(
            children: [
              Row(
                children: [
                  // Persistent Side Menu for wide screens
                  if (isBigScreen && !isFullScreen) ...[
                    SizedBox(
                      width: 250,
                      child: LeftMenu(pageController: _pageController),
                    ),
                    const VerticalDivider(width: 1),
                  ],

                  // Main Content Area
                  // FIXME: this PageView builds only 10 pages, but there are
                  // 18 app sections (offline offices 10-16, calendar 17).
                  // left_menu.jumpToPage(sectionIndex) only "works" because the
                  // jump clamps to the last page and pages 1-9 are identical
                  // LiturgyScreen()s driven by liturgyType. Use
                  // appSections.length, or restructure to 2 pages (bible +
                  // a single liturgy page) since content is liturgyType-driven.
                  // TODO: de-duplicate the two PageView branches below — they
                  // are identical except for the Center/FractionallySizedBox
                  // wrapper; extract the PageView and conditionally wrap it.
                  Expanded(
                    child: (isFullScreen && isLandscape)
                        ? Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.85,
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                children: List.generate(
                                    10,
                                    (index) => index == 0
                                        ? BibleListsScreen()
                                        : LiturgyScreen()),
                              ),
                            ),
                          )
                        : PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: List.generate(
                                10,
                                (index) => index == 0
                                    ? BibleListsScreen()
                                    : LiturgyScreen()),
                          ),
                  ),
                ],
              ),
              if (showFullScreenButton)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Opacity(
                    opacity: 0.5,
                    child: Tooltip(
                      message: isFullScreen
                          ? 'Quitter le plein écran'
                          : 'Plein écran',
                      child: Material(
                        elevation: 2,
                        shape: const CircleBorder(),
                        // TODO: move this hardcoded brand red to a theme constant.
                        color: const Color(0xFFBF2329),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: isFullScreen
                              ? liturgyState.exitFullScreen
                              : liturgyState.enterFullScreen,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          drawer: (isBigScreen || isFullScreen)
              ? null
              : Drawer(child: LeftMenu(pageController: _pageController)),
        );
      },
    );
  }
}
