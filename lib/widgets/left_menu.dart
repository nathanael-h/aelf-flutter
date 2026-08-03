import 'package:aelf_flutter/data/app_sections.dart';
import 'package:aelf_flutter/models/office_header_info.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/pageState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/widgets/left_menu_header.dart';
import 'package:aelf_flutter/widgets/left_menu_office_header.dart';
import 'package:aelf_flutter/widgets/location_selector_widget.dart';
import 'package:aelf_flutter/widgets/material_drawer_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeftMenu extends StatelessWidget {
  const LeftMenu({
    Key? key,
    required PageController pageController,
  })  : _pageController = pageController,
        super(key: key);

  final PageController _pageController;

  static const _aelfReplacedOffices = {
    'laudes',
    'tierce',
    'sexte',
    'none',
    'vepres',
    'complies',
    'lectures',
    'informations'
  };

  static bool _showSection(String name, bool offlineEnabled) {
    if (name.startsWith('offline_') && !offlineEnabled) return false;
    if (_aelfReplacedOffices.contains(name) && offlineEnabled) return false;
    return true;
  }

  static String _sectionName(int index) =>
      (index >= 0 && index < appSections.length) ? appSections[index].name : '';

  /// Mass and the Divine Office hours (online and their `offline_` twins) all
  /// get the offices header. Bible has its own; everything else (informations,
  /// the offline calendar) keeps the legacy AELF header.
  static const _officeSections = {
    'messes',
    'lectures',
    'laudes',
    'tierce',
    'sexte',
    'none',
    'vepres',
    'complies',
  };

  static bool _isOfficeSection(String name) {
    if (_officeSections.contains(name)) return true;
    // offline_* offices, but not the offline calendar.
    return name.startsWith('offline_') && name != 'offline_calendar';
  }

  /// Mass is not yet available in the offline liturgy: its header always uses
  /// the online API, whatever the offline-liturgy setting. Kept as a helper so
  /// an eventual `offline_messes` section is treated the same way.
  static bool _isMassSection(String name) =>
      name == 'messes' || name == 'offline_messes';

  /// The native app swaps the drawer header per section
  /// (`setDrawerHeaderView`): Bible has `navigation_drawer_header_bible.xml`,
  /// Mass/offices have `navigation_drawer_header_offices.xml`, the rest show the
  /// AELF logo.
  Widget _header(BuildContext context, PageState pageState) {
    final String name = _sectionName(pageState.activeAppSection);

    if (name == 'bible') {
      return const LeftMenuHeader(
        title: 'La Bible',
        subtitle: 'Traduction liturgique',
      );
    }

    if (_isOfficeSection(name)) {
      final liturgy = context.watch<LiturgyState>();
      final bool offlineEnabled =
          context.watch<FeatureFlagsState>().offlineLiturgyEnabled;

      // The header takes its data from the offline calendar only for the
      // offline_* office twins while the feature is on. Everything else — the
      // online offices, every section when the setting is off, and Mass (not
      // yet available offline) — uses the online API `informations`.
      final bool useOfflineSource = offlineEnabled &&
          name.startsWith('offline_') &&
          !_isMassSection(name);

      if (useOfflineSource) {
        // Region control is the full offline location hierarchy, picked through
        // the same nested bottom sheet the settings screen uses.
        return LeftMenuOfficeHeader(
          info: liturgy.offlineHeaderInfo,
          selectedRegion: liturgy.offlineRegion,
          regionLabel: liturgy.offlineRegionLabel,
          onRegionTap: () => showLocationSelector(
            context,
            currentLocationId: liturgy.offlineRegion,
            onLocationSelected: (id) => liturgy.selectOfflineLocation(id),
          ),
        );
      }

      final String region = liturgy.region;
      final OfficeHeaderInfo info = liturgy.informationsJson == null
          ? OfficeHeaderInfo(region: region)
          : OfficeHeaderInfo.fromApi(liturgy.informationsJson!, region: region);
      return LeftMenuOfficeHeader(
        info: info,
        selectedRegion: region,
        onRegionSelected: (r) => liturgy.updateRegion(r),
      );
    }

    return DrawerHeader(
      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
      child: Column(
        children: <Widget>[
          Image.asset(
            'assets/icons/ic_launcher_android_round.png',
            height: 90,
            width: 90,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              "AELF",
              style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PageState>(builder: (context, pageState, child) {
      final bg = Theme.of(context).drawerTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface;
      return Container(
        color: bg,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _header(context, pageState),
            for (var entry in appSections.asMap().entries)
              if (_showSection(entry.value.name,
                  context.watch<FeatureFlagsState>().offlineLiturgyEnabled))
                MaterialDrawerItem(
                  listTile: ListTile(
                    title: Text(entry.value.title,
                        style: Theme.of(context).textTheme.bodyLarge),
                    selected: pageState.activeAppSection == entry.key,
                    onTap: () {
                      if (entry.value.name != 'bible') {
                        context
                            .read<LiturgyState>()
                            .updateLiturgyType(entry.value.name);
                      }
                      context.read<PageState>().changeSectionAll(
                            section: entry.key,
                            searchVisible: entry.value.searchVisible,
                            datePickerVisible: entry.value.datePickerVisible,
                            title: entry.value.title,
                          );
                      _pageController.jumpToPage(entry.key);
                      Scaffold.of(context).hasDrawer
                          ? Scaffold.of(context).closeDrawer()
                          : null;
                    },
                  ),
                ),
          ],
        ),
      );
    });
  }
}
