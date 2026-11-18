import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';

/// A small "Latin" toggle shown next to an evangelic canticle that has a
/// Latin variant, switching [LiturgyState.useLatinCanticle] — a single
/// shared, persisted preference for all three canticles (Benedictus,
/// Magnificat, Nunc dimittis). Same visual family as
/// [BiblicalReferenceButton]: a small `TextButton.icon`, zoom-aware.
class LatinToggleButton extends StatelessWidget {
  final double zoom;

  const LatinToggleButton({super.key, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    final useLatin = context.watch<LiturgyState>().useLatinCanticle;
    final color = Theme.of(context).colorScheme.secondary;

    return TextButton.icon(
      onPressed: () =>
          context.read<LiturgyState>().updateLatinCanticle(!useLatin),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(Icons.translate, size: 13 * zoom / 100, color: color),
      label: Text(
        'Latin',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 12 * zoom / 100,
          fontWeight: useLatin ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
