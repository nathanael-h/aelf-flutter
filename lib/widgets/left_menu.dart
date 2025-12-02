import 'package:aelf_flutter/data/app_sections.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/pageState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<PageState>(
      builder: (context, pageState, child) {
        final bg = Theme.of(context).drawerTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface;
        return Container(
          color: bg,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration:
                    BoxDecoration(color: Theme.of(context).primaryColor),
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
                    /*Text(
                    "punchline",
                    style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70),
                  ),*/
                  ],
                ),
              ),
              for (var entry in appSections.asMap().entries)
                if (!((entry.value.name.contains('offline') ||
                        entry.value.name.contains('complies_new')) &&
                    !context.watch<FeatureFlagsState>().offlineLiturgyEnabled))
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
                        context
                            .read<PageState>()
                            .changeActiveAppSection(entry.key);
                        context.read<PageState>().changeSearchButtonVisibility(
                            entry.value.searchVisible);
                        context
                            .read<PageState>()
                            .changeDatePickerButtonVisibility(
                                entry.value.datePickerVisible);
                        context
                            .read<PageState>()
                            .changePageTitle(entry.value.title);
                        _pageController.jumpToPage(entry.key);
                        Scaffold.maybeOf(context)?.closeDrawer();
                      },
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
