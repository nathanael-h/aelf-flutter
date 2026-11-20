import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_icon.dart';

/// A language-toggle button shown next to an evangelic canticle that has a
/// Latin or Greek variant, cycling [LiturgyState.canticleLanguage] through
/// French/Latin/Greek — a single shared, persisted preference for all three
/// canticles (Benedictus, Magnificat, Nunc dimittis) — independent of
/// psalms and Old/New Testament canticles, whose own Hebrew/Greek
/// preference is a single menu entry rather than a per-text button (see
/// `buildPopupMenuChoices`). Same icon-only appearance (see
/// [LanguageToggleIcon]), and same visual family as
/// [BiblicalReferenceButton]: a small `TextButton`, zoom-aware.
/// Only shown in "mode développé" ([FeatureFlagsState.advancedModeEnabled]),
/// like the other advanced-mode-only controls.
class CanticleLanguageButton extends StatelessWidget {
  final double zoom;

  const CanticleLanguageButton({super.key, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<FeatureFlagsState>().advancedModeEnabled) {
      return const SizedBox.shrink();
    }
    final canticleLanguage = context.watch<LiturgyState>().canticleLanguage;
    final color = Theme.of(context).colorScheme.secondary;

    return TextButton(
      onPressed: () => context.read<LiturgyState>().cycleCanticleLanguage(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: LanguageToggleIcon(
        active: canticleLanguage != CanticleLanguage.french,
        color: color,
        zoom: zoom,
      ),
    );
  }
}
