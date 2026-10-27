import 'package:flutter/cupertino.dart';

class PopupMenuChoice {
  const PopupMenuChoice({
    this.title,
    this.icon,
    this.widget,
    this.onSelected,
    this.selected = false,
    this.dividerBefore = false,
  });

  final IconData? icon;
  final String? title;
  final Widget? widget;
  // Run when the entry is chosen, once the menu is closed
  final VoidCallback? onSelected;
  // The active entry of a group of choices, highlighted in the accent color
  final bool selected;
  final bool dividerBefore;
}
