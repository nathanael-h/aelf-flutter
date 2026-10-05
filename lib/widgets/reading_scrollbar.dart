import 'package:flutter/material.dart';

/// Thin scrollbar in the secondary colour shown along long texts (offices,
/// Bible chapters) so the reader can see where they are.
///
/// It is not interactive: it only follows the scroll notifications of its
/// direct child scroll view. That also lets it go without a [controller]
/// when the scroll view uses a [PrimaryScrollController] shared by several
/// scroll views (e.g. the pages of a `PageView`), which an interactive
/// scrollbar would reject.
class ReadingScrollbar extends StatelessWidget {
  const ReadingScrollbar({super.key, this.controller, required this.child});

  final ScrollController? controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      controller: controller,
      thumbColor: Theme.of(context).colorScheme.secondary,
      thickness: 4,
      radius: const Radius.circular(4),
      interactive: false,
      child: child,
    );
  }
}
