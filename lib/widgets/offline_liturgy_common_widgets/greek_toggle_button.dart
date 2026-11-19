import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';

/// A small "Αα" toggle shown next to an Old/New Testament canticle that
/// has a Greek variant, switching [LiturgyState.useGreekPsalm] —
/// independent of [LiturgyState.canticleLanguage] (the evangelic
/// canticles' own French/Latin/Greek rotation) and of
/// [LiturgyState.useHebrewPsalm]. Same visual family as
/// [BiblicalReferenceButton]: a small `TextButton.icon`, zoom-aware.
class GreekToggleButton extends StatelessWidget {
  final double zoom;

  const GreekToggleButton({super.key, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    final useGreek = context.watch<LiturgyState>().useGreekPsalm;
    final color = Theme.of(context).colorScheme.secondary;

    return TextButton.icon(
      onPressed: () =>
          context.read<LiturgyState>().updateGreekPsalm(!useGreek),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Text(
        'Αα',
        style: TextStyle(fontSize: 13 * zoom / 100, color: color),
      ),
      label: Text(
        'Grec',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 12 * zoom / 100,
          fontWeight: useGreek ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
