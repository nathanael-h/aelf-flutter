import 'package:flutter/cupertino.dart';

class PopupMenuChoice {
  const PopupMenuChoice({
    this.title,
    this.icon,
    this.customIconText,
    this.customIconBuilder,
    this.widget,
    this.onSelected,
    this.selected = false,
    this.dividerBefore = false,
  });

  final IconData? icon;
  // A one- or two-glyph symbol (e.g. "αא") shown instead of [icon] when no
  // Material icon fits, such as a combined Greek/Hebrew letter pair.
  final String? customIconText;
  // A hand-drawn icon for when even a plain Unicode glyph isn't safe — most
  // cross characters (✝, ✞…) render as a colored emoji on some platforms
  // regardless of variation selectors. Takes the resolved icon color.
  final Widget Function(Color? color)? customIconBuilder;
  final String? title;
  final Widget? widget;
  // Run when the entry is chosen, once the menu is closed
  final VoidCallback? onSelected;
  // The active entry of a group of choices, highlighted in the accent color
  final bool selected;
  final bool dividerBefore;
}
