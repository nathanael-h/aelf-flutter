import 'package:flutter/material.dart';

// Inspired by https://github.com/mono0926/flutter_mono_kit/blob/master/lib/widgets/list_tile_selected_background_colored_box.dart
class MaterialDrawerItem extends StatelessWidget {
  const MaterialDrawerItem({
    Key? key,
    required this.listTile,
  }) : super(key: key);

  final ListTile listTile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: ColoredBox(
        color: listTile.selected
            ? colorScheme.secondary.withValues(alpha: 0.12)
            : Colors.transparent,
        child: listTile,
      ),
    );
  }
}
