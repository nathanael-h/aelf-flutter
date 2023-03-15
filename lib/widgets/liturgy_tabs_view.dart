import 'package:flutter/material.dart';

class LiturgyTabsView extends StatelessWidget {
  const LiturgyTabsView({
    Key key,
    @required TabController tabController,
    @required List<String> tabMenuTitles,
  }) : _tabController = tabController, _tabMenuTitles = tabMenuTitles, super(key: key);

  final TabController _tabController;
  final List<String> _tabMenuTitles;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            for(String title in _tabMenuTitles) ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: (MediaQuery.of(context).size.width / 3),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Tab(text: title),
              )
            )
          ]
        ),
      ),
    );
  }
}