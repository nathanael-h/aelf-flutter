import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';

/// A small "א" (aleph) toggle shown next to a psalm that has a Hebrew
/// variant, switching [LiturgyState.useHebrewPsalm] — independent of
/// [LiturgyState.canticleLanguage], which only affects the evangelic
/// canticles. Same visual family as [BiblicalReferenceButton]: a small
/// `TextButton.icon`, zoom-aware.
class HebrewToggleButton extends StatelessWidget {
  final double zoom;

  const HebrewToggleButton({super.key, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    final useHebrew = context.watch<LiturgyState>().useHebrewPsalm;
    final color = Theme.of(context).colorScheme.secondary;

    return TextButton.icon(
      onPressed: () =>
          context.read<LiturgyState>().updateHebrewPsalm(!useHebrew),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Text(
        'א',
        style: TextStyle(fontSize: 15 * zoom / 100, color: color),
      ),
      label: Text(
        'Hébreu',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 12 * zoom / 100,
          fontWeight: useHebrew ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
