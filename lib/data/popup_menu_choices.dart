import 'package:aelf_flutter/models/popup_menu_choice.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_icon.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart' show VotiveOffice;
import 'package:provider/provider.dart';

// Proper widget so a fresh element is created each time the popup opens,
// rather than reusing a global Consumer singleton.
class _DarkModeSwitch extends StatelessWidget {
  const _DarkModeSwitch();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, notifier, child) {
        return Switch(
          value: notifier.darkTheme,
          onChanged: (value) {
            notifier.toggleTheme();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _ScrollModeSwitch extends StatelessWidget {
  const _ScrollModeSwitch();

  @override
  Widget build(BuildContext context) {
    return Consumer<LiturgyState>(
      builder: (context, liturgyState, child) {
        return Switch(
          value: liturgyState.useScrollMode,
          onChanged: (value) {
            liturgyState.updateScrollMode(value);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

/// Toggles psalms and Old/New Testament canticles between French and
/// their original language (Hebrew or Greek, whichever a given text has —
/// never both) — a single preference for the whole office, replacing what
/// used to be a button next to each text. Independent of the evangelic
/// canticles' own French/Latin/Greek rotation (CanticleLanguageButton).
/// The icon ("Aα" + "א"), in the same color as every other entry's title
/// text, sits next to the switch; the entry's own title carries the label.
class _OriginalPsalmLanguageSwitch extends StatelessWidget {
  const _OriginalPsalmLanguageSwitch();

  @override
  Widget build(BuildContext context) {
    return Consumer<LiturgyState>(
      builder: (context, liturgyState, child) {
        final active = liturgyState.useOriginalPsalmLanguage;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageToggleIcon(
              active: active,
              color: Theme.of(context).textTheme.bodyMedium?.color ??
                  Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Switch(
              value: active,
              onChanged: (value) {
                liturgyState.updateOriginalPsalmLanguage(value);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

/// Builds the 3-dot menu entries. "Mode défilement" and the choice of the
/// day's offices — its own, or the Dedication's or the Office of the Dead
/// in their place (see LiturgyState.setVotiveOffice), the active one
/// highlighted — only appear once the beta offline liturgy feature is
/// enabled, mirroring its gating in the Settings screen. The "Psaumes et
/// Cantiques en langues anciennes" entry (psalms/OT-NT canticles in Hebrew
/// or Greek — see LiturgyState.useOriginalPsalmLanguage), set apart after
/// the votive offices by its own divider, additionally needs "mode
/// développé".
List<PopupMenuChoice> buildPopupMenuChoices(BuildContext context) {
  final offlineLiturgyEnabled =
      context.read<FeatureFlagsState>().offlineLiturgyEnabled;
  final advancedModeEnabled =
      context.read<FeatureFlagsState>().advancedModeEnabled;
  final liturgyState = context.read<LiturgyState>();
  PopupMenuChoice officeChoice(String title, VotiveOffice? office,
          {bool dividerBefore = false}) =>
      PopupMenuChoice(
        title: title,
        onSelected: () => liturgyState.setVotiveOffice(office),
        selected: liturgyState.votiveOffice == office,
        dividerBefore: dividerBefore,
      );

  return <PopupMenuChoice>[
    const PopupMenuChoice(
      title: 'Mode nuit',
      icon: Icons.directions_bus,
      widget: _DarkModeSwitch(),
    ),
    if (offlineLiturgyEnabled) ...[
      const PopupMenuChoice(
        title: 'Mode défilement',
        icon: Icons.swap_vert,
        widget: _ScrollModeSwitch(),
      ),
      // "Office du jour" is only the way back from a votive office, so it
      // only shows up once one is active.
      if (liturgyState.votiveOffice != null)
        officeChoice('Office du jour', null, dividerBefore: true),
      if (advancedModeEnabled) ...[
        officeChoice('Office de la Dédicace', VotiveOffice.dedication,
            dividerBefore: liturgyState.votiveOffice == null),
        officeChoice('Office des défunts', VotiveOffice.departed),
        PopupMenuChoice(
          title: 'Psaumes et Cantiques\nen langues anciennes',
          widget: const _OriginalPsalmLanguageSwitch(),
          dividerBefore: true,
        ),
      ],
    ],
    PopupMenuChoice(
        title: 'Paramètres',
        icon: Icons.directions_walk,
        widget: const Text(''),
        dividerBefore: offlineLiturgyEnabled),
    const PopupMenuChoice(
        title: 'À propos', icon: Icons.directions_walk, widget: Text('')),
  ];
}
