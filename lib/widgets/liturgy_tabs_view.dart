import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class LiturgyTabsView extends StatefulWidget {
  LiturgyTabsView(aelfJson, {Key key}) : super(key: key);
  var aelfJson;
  @override
  State<LiturgyTabsView> createState() => _LiturgyTabsViewState();
}

class _LiturgyTabsViewState extends State<LiturgyTabsView> with TickerProviderStateMixin {
  
  TabController _tabController;
  var aelfJson;

  @override
  void initState() {
    super.initState();
    aelfJson = widget.aelfJson;
    _tabController = TabController(vsync: this, length: 2);
  }

 @override
 void dispose() {
   _tabController.dispose();
   super.dispose();
 }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).primaryColor,
          //width: MediaQuery.of(context).size.width,
          child: Center(
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'a'),
                Tab(text: 'a2')
              ],
            )
          )
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Text("data"),
              Text("data2")
            ]
          ),
        )
      ],
    );
  }
}
