import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_icon.dart';

/// A language-toggle button shown next to a psalm or Old/New Testament
/// canticle that has an original-language variant (Hebrew or Greek —
/// never both on the same text), switching
/// [LiturgyState.useOriginalPsalmLanguage] — a single preference shared by
/// every psalm/canticle, independent of [LiturgyState.canticleLanguage],
/// which only affects the evangelic canticles. Same icon-only appearance
/// as [CanticleLanguageButton] (see [LanguageToggleIcon]), and same visual
/// family as [BiblicalReferenceButton]: a small `TextButton`, zoom-aware.
/// Only shown in "mode développé" ([FeatureFlagsState.advancedModeEnabled]),
/// like the other advanced-mode-only controls.
class OriginalLanguageToggleButton extends StatelessWidget {
  final double zoom;

  const OriginalLanguageToggleButton({super.key, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<FeatureFlagsState>().advancedModeEnabled) {
      return const SizedBox.shrink();
    }
    final useOriginal = context.watch<LiturgyState>().useOriginalPsalmLanguage;
    final color = Theme.of(context).colorScheme.secondary;

    return TextButton(
      onPressed: () => context
          .read<LiturgyState>()
          .updateOriginalPsalmLanguage(!useOriginal),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: LanguageToggleIcon(active: useOriginal, color: color, zoom: zoom),
    );
  }
}
