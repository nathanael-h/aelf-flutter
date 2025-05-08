import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:flutter/material.dart';

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
    return Center(child: LiturgyFormatter());
  }
}
