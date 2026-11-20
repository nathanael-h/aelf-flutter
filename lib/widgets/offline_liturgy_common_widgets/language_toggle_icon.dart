import 'package:flutter/material.dart';

/// Shared icon-only appearance for every language-toggle button (Hebrew,
/// Greek, and the French/Latin/Greek canticle rotation): "Aα" (Latin/Greek)
/// next to "א" (Hebrew aleph), no text label. Identical in every context so
/// the user recognizes one button regardless of which language it switches.
/// [showHebrew] drops the aleph where Hebrew is never an actual option (the
/// evangelic canticles' rotation), to avoid suggesting a language that
/// button can't switch to.
class LanguageToggleIcon extends StatelessWidget {
  final bool active;
  final Color color;
  final double zoom;
  final bool showHebrew;

  const LanguageToggleIcon({
    super.key,
    required this.active,
    required this.color,
    this.zoom = 100,
    this.showHebrew = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14 * zoom / 100,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      color: color,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Aα', style: style),
        if (showHebrew) ...[
          SizedBox(width: 2 * zoom / 100),
          Text('א', style: style),
        ],
      ],
    );
  }
}
