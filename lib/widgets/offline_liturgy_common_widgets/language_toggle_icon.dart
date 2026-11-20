import 'package:flutter/material.dart';

/// Shared icon-only appearance for every language-toggle button (Hebrew,
/// Greek, and the French/Latin/Greek canticle rotation): "Aα" (Latin/Greek)
/// next to "א" (Hebrew aleph), no text label. Identical in every context so
/// the user recognizes one button regardless of which language it switches.
class LanguageToggleIcon extends StatelessWidget {
  final bool active;
  final Color color;
  final double zoom;

  const LanguageToggleIcon({
    super.key,
    required this.active,
    required this.color,
    this.zoom = 100,
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
        SizedBox(width: 2 * zoom / 100),
        Text('א', style: style),
      ],
    );
  }
}
