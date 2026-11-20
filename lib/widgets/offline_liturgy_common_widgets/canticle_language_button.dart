import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_icon.dart';

/// A language-toggle button shown next to an evangelic canticle that has a
/// Latin or Greek variant, cycling [LiturgyState.canticleLanguage] through
/// French/Latin/Greek — a single shared, persisted preference for all three
/// canticles (Benedictus, Magnificat, Nunc dimittis) — independent of
/// psalms and Old/New Testament canticles, whose own Hebrew/Greek
/// preference is a single menu entry rather than a per-text button (see
/// `buildPopupMenuChoices`). Pill-shaped so it reads as a tappable control
/// rather than floating text; the cycle icon signals it rotates through
/// several languages. Drops the Hebrew glyph from [LanguageToggleIcon]
/// since Hebrew is never an actual option here.
/// Unlike the psalms/OT-NT canticles preference, this one is shown
/// regardless of "mode développé" / "mode simplifié".
class CanticleLanguageButton extends StatelessWidget {
  final double zoom;

  const CanticleLanguageButton({super.key, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    final canticleLanguage = context.watch<LiturgyState>().canticleLanguage;
    final active = canticleLanguage != CanticleLanguage.french;
    final color = Theme.of(context).colorScheme.secondary;
    final radius = BorderRadius.circular(999);

    return Material(
      color: color.withValues(alpha: active ? 0.14 : 0.07),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => context.read<LiturgyState>().cycleCanticleLanguage(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 6 * zoom / 100,
            vertical: 2 * zoom / 100,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LanguageToggleIcon(
                active: active,
                color: color,
                zoom: zoom,
                showHebrew: false,
              ),
              SizedBox(width: 2 * zoom / 100),
              Icon(Icons.sync, size: 11 * zoom / 100, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
