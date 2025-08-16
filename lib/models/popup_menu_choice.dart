import 'package:flutter/cupertino.dart';

class PopupMenuChoice {
  const PopupMenuChoice({this.title, this.icon, this.widget});

  final IconData? icon;
  final String? title;
  final Widget? widget;
}
