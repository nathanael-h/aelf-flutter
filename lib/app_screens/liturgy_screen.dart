import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:flutter/material.dart';

class LiturgyScreen extends StatefulWidget {
  LiturgyScreen(this.liturgyType) : super();

  static const routeName = '/liturgyScreen';

  final String liturgyType;

  @override
  _LiturgyScreenState createState() => _LiturgyScreenState();
}

class _LiturgyScreenState extends State<LiturgyScreen>
    with TickerProviderStateMixin {


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return 
    Center(
      child: LiturgyFormatter()
    );
  }

}
