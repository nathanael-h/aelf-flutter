import 'package:flutter/material.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_icon.dart';

/// Shared pill-shaped tap target for a language-toggle button: background
/// intensity when active, the language glyphs, and a cycle icon. Used by
/// `CanticleLanguageButton` (French/Latin/Greek cycle) and
/// `TeDeumLanguageButton` (French/Latin only) so both read as the same
/// control regardless of how many languages they actually cycle through.
class LanguageTogglePill extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final double zoom;
  final bool showHebrew;

  const LanguageTogglePill({
    super.key,
    required this.active,
    required this.onTap,
    this.zoom = 100,
    this.showHebrew = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    final radius = BorderRadius.circular(999);

    return Material(
      color: color.withValues(alpha: active ? 0.14 : 0.07),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
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
                showHebrew: showHebrew,
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
