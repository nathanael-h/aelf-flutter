import 'dart:developer';

import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class LiturgyTabsView extends StatefulWidget {
  Map<String, dynamic> tabsMap;
  LiturgyTabsView({Key? key, required this.tabsMap}) : super(key: key);
  @override
  State<LiturgyTabsView> createState() => _LiturgyTabsViewState();
}

class _LiturgyTabsViewState extends State<LiturgyTabsView>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  Widget build(BuildContext context) {
    _tabController = widget.tabsMap['_tabController'];
    log("_tabController.hashCode:${_tabController.hashCode}");

    return Column(
      children: [
        Container(
            color: Theme.of(context).primaryColor,
            width: MediaQuery.of(context).size.width,
            child: Center(
                child: TabBar(
                    indicatorColor: Theme.of(context).tabBarTheme.labelColor ??
                        Theme.of(context).colorScheme.secondary,
                    labelColor: Theme.of(context).tabBarTheme.labelColor ??
                        Theme.of(context).colorScheme.secondary,
                    unselectedLabelColor:
                        Theme.of(context).tabBarTheme.unselectedLabelColor ??
                            Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.7),
                    labelPadding: EdgeInsets.symmetric(horizontal: 0),
                    isScrollable: true,
                    controller: _tabController,
                    tabs: <Widget>[
                  for (String title in widget.tabsMap['_tabMenuTitles'])
                    ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: (MediaQuery.of(context).size.width / 3),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Tab(text: title),
                        ))
                ]))),
        Expanded(
          child: SafeArea(
            child: PinchZoomSelectionArea(
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.noScaling),
                child: TabBarView(
                    controller: _tabController,
                    children: widget.tabsMap['_tabChildren']),
              ),
            ),
          ),
        )
      ],
    );
  }
}
