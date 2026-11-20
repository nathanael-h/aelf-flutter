import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';

const Map<CanticleLanguage, String> _languageLabels = {
  CanticleLanguage.french: 'Français',
  CanticleLanguage.latin: 'Latin',
  CanticleLanguage.greek: 'Grec',
};

/// A small button shown next to an evangelic canticle that has a Latin or
/// Greek variant, cycling [LiturgyState.canticleLanguage] through
/// French/Latin/Greek — a single shared, persisted preference for all three
/// canticles (Benedictus, Magnificat, Nunc dimittis). Same visual family as
/// [BiblicalReferenceButton]: a small `TextButton.icon`, zoom-aware.
class CanticleLanguageButton extends StatelessWidget {
  final double zoom;

  const CanticleLanguageButton({super.key, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    final canticleLanguage = context.watch<LiturgyState>().canticleLanguage;
    final color = Theme.of(context).colorScheme.secondary;

    return TextButton.icon(
      onPressed: () => context.read<LiturgyState>().cycleCanticleLanguage(),
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
        _languageLabels[canticleLanguage]!,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 12 * zoom / 100,
          fontWeight: canticleLanguage == CanticleLanguage.french
              ? FontWeight.w500
              : FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
