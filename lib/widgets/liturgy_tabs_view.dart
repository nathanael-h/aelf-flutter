import 'dart:developer';

import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'package:provider/provider.dart';

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
    log("_tabController.hashCode:" + _tabController.hashCode.toString());
    double? zoomBeforePinch = context.read<CurrentZoom>().value;

    return Column(
      children: [
        Container(
            color: Theme.of(context).primaryColor,
            width: MediaQuery.of(context).size.width,
            child: Center(
                child: TabBar(
                    indicatorColor: Theme.of(context).tabBarTheme.labelColor,
                    labelColor: Theme.of(context).tabBarTheme.labelColor,
                    unselectedLabelColor:
                        Theme.of(context).tabBarTheme.unselectedLabelColor,
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
          child: GestureDetector(
            onScaleUpdate: (ScaleUpdateDetails scaleUpdateDetails) {
              dev.log("onScaleUpdate detected, in liturgy_tabs_view");
              double _newZoom = zoomBeforePinch! * scaleUpdateDetails.scale;
              // Sometimes when removing fingers from screen, after a pinch or zoom gesture
              // the gestureDetector reports a scale of 1.0, and the _newZoom is set to 100%
              // which is not what I want. So a simple trick I found is to ignore this 'perfect'
              // 1.0 value.
              if (scaleUpdateDetails.scale == 1.0) {
                dev.log("scaleUpdatDetails.scale == 1.0");
              } else {
                context.read<CurrentZoom>().updateZoom(_newZoom);
                dev.log(
                    "onScaleUpdate: pinch scaling factor: zoomBeforePinch: $zoomBeforePinch; ${scaleUpdateDetails.scale}; new zoom: $_newZoom");
              }
            },
            onScaleEnd: (ScaleEndDetails scaleEndDetails) {
              dev.log("onScaleEnd detected, in liturgy_tabs_view");
              zoomBeforePinch = context.read<CurrentZoom>().value;
            },
            child: SafeArea(
              child: SelectionArea(
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.noScaling),
                  child: TabBarView(
                      controller: _tabController,
                      children: widget.tabsMap['_tabChildren']),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
