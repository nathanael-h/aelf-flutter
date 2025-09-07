import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_compline_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiturgyScreen extends StatefulWidget {
  LiturgyScreen() : super();

  static const routeName = '/liturgyScreen';

  @override
  LiturgyScreenState createState() => LiturgyScreenState();
}

class LiturgyScreenState extends State<LiturgyScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LiturgyState>(builder: (context, liturgyState, child) {
      if (liturgyState.liturgyType == "complies_new") {
        final compline = liturgyState.newOfflineLiturgy.entries.first.value;
        return complineView(compline: compline);
      } else {
        return Center(child: LiturgyFormatter());
      }
    });
  }
}
