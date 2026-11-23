import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_pill.dart';

/// A language-toggle button shown next to an evangelic canticle that has a
/// Latin or Greek variant, cycling [LiturgyState.canticleLanguage] through
/// French/Latin/Greek — a single shared, persisted preference for all three
/// canticles (Benedictus, Magnificat, Nunc dimittis) — independent of
/// psalms and Old/New Testament canticles, whose own Hebrew/Greek
/// preference is a single menu entry rather than a per-text button (see
/// `buildPopupMenuChoices`), and of the Te Deum's own toggle (see
/// `TeDeumLanguageButton`).
/// Unlike the psalms/OT-NT canticles preference, this one is shown
/// regardless of "mode développé" / "mode simplifié".
class CanticleLanguageButton extends StatelessWidget {
  final double zoom;

  const CanticleLanguageButton({super.key, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    final canticleLanguage = context.watch<LiturgyState>().canticleLanguage;

    return LanguageTogglePill(
      active: canticleLanguage != CanticleLanguage.french,
      onTap: () => context.read<LiturgyState>().cycleCanticleLanguage(),
      zoom: zoom,
    );
  }
}
