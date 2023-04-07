import 'package:flutter/material.dart';

// ignore: must_be_immutable
class LiturgyTabsView extends StatefulWidget {
  Map<String, dynamic> tabsMap;
  LiturgyTabsView({
    Key key,
    @required this.tabsMap
  }) : super(key: key);
  @override
  State<LiturgyTabsView> createState() => _LiturgyTabsViewState();
}

class _LiturgyTabsViewState extends State<LiturgyTabsView> with TickerProviderStateMixin {
  
  TabController _tabController;

  @override
  Widget build(BuildContext context) {
    _tabController = widget.tabsMap['_tabController'];;

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
                  for(String title in widget.tabsMap['_tabMenuTitles']) ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: (MediaQuery.of(context).size.width / 3),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Tab(text: title),
                    )
                  )
                ]
            )
          )
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.tabsMap['_tabChildren']
          ),
        )
      ],
    );
  }
}
