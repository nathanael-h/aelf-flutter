import 'package:aelf_flutter/data/app_sections.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/pageState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/widgets/left_menu_header.dart';
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

  /// The native app swaps the drawer header per section: the Bible section has
  /// its own (`navigation_drawer_header_bible.xml`), the other ones show the
  /// AELF logo.
  Widget _header(BuildContext context, PageState pageState) {
    if (_sectionName(pageState.activeAppSection) == 'bible') {
      return const LeftMenuHeader(
        title: 'La Bible',
        subtitle: 'Traduction liturgique',
      );
    } else {
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
