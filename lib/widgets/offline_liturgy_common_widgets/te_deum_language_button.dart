import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_pill.dart';

/// A language-toggle button shown next to the Te Deum title, switching
/// [LiturgyState.teDeumLatin] between French and Latin. The Te Deum has no
/// Greek version, so unlike `CanticleLanguageButton` this is a plain
/// two-way toggle with its own preference, independent of the evangelic
/// canticles' rotation and of the psalms' original-language switch.
class TeDeumLanguageButton extends StatelessWidget {
  final double zoom;

  const TeDeumLanguageButton({super.key, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<LiturgyState>().teDeumLatin;

    return LanguageTogglePill(
      active: active,
      onTap: () => context.read<LiturgyState>().toggleTeDeumLatin(),
      zoom: zoom,
    );
  }
}
