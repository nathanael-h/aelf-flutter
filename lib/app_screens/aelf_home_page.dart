import 'dart:async';
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
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AelfHomePage extends StatefulWidget {
  const AelfHomePage({Key? key}) : super(key: key);

  @override
  AelfHomePageState createState() => AelfHomePageState();
}

class AelfHomePageState extends State<AelfHomePage> {
  final _pageController = PageController(initialPage: 1);
  String? chapter;
  String? version;

  // Custom date picker helper
  final DatePickerHelper _datePickerHelper = DatePickerHelper();

  String? selectedDateMenu; // Label shown in the AppBar
  String? selectedDateRaw; // ISO string for API calls (YYYY-MM-DD)
  DateTime? lastCheckedDateTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Initialize version info
    _getPackageVersion();

    // Network connectivity logic
    _initNetworkLogic();

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
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
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
  void _initNetworkLogic() async {
    // Check initial state
    var connectivityResults = await Connectivity().checkConnectivity();
    _handleConnectivityChange(connectivityResults);

    // Listen for changes
    Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    bool hasConnection = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    if (hasConnection) {
      context.read<LiturgyState>().updateLiturgy();
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

    // Scheduling UI update after the first frame to avoid provider conflicts
    Future.microtask(() {
      if (!mounted) return;

      final int sectionIdx = _getAppSectionFromName(sectionName);
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
    bool isBigScreen = (MediaQuery.of(context).size.width > 800);

    return Consumer<PageState>(
      builder: (context, pageState, child) {
        final sectionName = appSections[pageState.activeAppSection].name;
        final liturgyState = context.watch<LiturgyState>();
        final shareVisible = sectionName != 'bible' &&
            ShareHelper.slugFor(liturgyState.liturgyType) != null;
        return Scaffold(
          appBar: AppBar(
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
                                  fontWeight: FontWeight.normal,
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
          body: Row(
            children: [
              // Persistent Side Menu for wide screens
              if (isBigScreen) ...[
                SizedBox(
                  width: 250,
                  child: LeftMenu(pageController: _pageController),
                ),
                const VerticalDivider(width: 1),
              ],

              // Main Content Area
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                      10,
                      (index) =>
                          index == 0 ? BibleListsScreen() : LiturgyScreen()),
                ),
              ),
            ],
          ),
          drawer: isBigScreen
              ? null
              : Drawer(child: LeftMenu(pageController: _pageController)),
        );
      },
    );
  }
}
