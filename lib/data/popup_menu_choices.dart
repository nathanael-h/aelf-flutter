import 'package:aelf_flutter/models/popup_menu_choice.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart' show VotiveOffice;
import 'package:provider/provider.dart';

/// A plain Latin cross, drawn rather than taken from a Unicode glyph: cross
/// characters (✝, ✞…) render as a colored emoji on several platforms no
/// matter the font or variation selector used.
Widget _crossIcon(Color? color) => SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 3, height: 20, color: color),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Container(width: 13, height: 3, color: color),
          ),
        ],
      ),
    );

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

/// Builds the 3-dot menu entries. "Mode défilement" and the choice of the
/// day's offices — its own, or the Dedication's or the Office of the Dead
/// in their place (see LiturgyState.setVotiveOffice), the active one
/// highlighted — only appear once the beta offline liturgy feature is
/// enabled, mirroring its gating in the Settings screen. The "Psaumes et
/// Cantiques en langues anciennes" entry (psalms/OT-NT canticles in Hebrew
/// or Greek — see LiturgyState.useOriginalPsalmLanguage), set apart after
/// the votive offices by its own divider, additionally needs "mode
/// développé". Like the votive offices, it's a plain toggle entry —
/// tapping it flips the preference, and it highlights (same as a selected
/// office) while active, with no separate icon or switch.
List<PopupMenuChoice> buildPopupMenuChoices(BuildContext context) {
  final offlineLiturgyEnabled =
      context.read<FeatureFlagsState>().offlineLiturgyEnabled;
  final advancedModeEnabled =
      context.read<FeatureFlagsState>().advancedModeEnabled;
  final liturgyState = context.read<LiturgyState>();
  PopupMenuChoice officeChoice(String title, VotiveOffice? office,
          {IconData? icon,
          Widget Function(Color?)? customIconBuilder,
          bool dividerBefore = false}) =>
      PopupMenuChoice(
        title: title,
        icon: icon,
        customIconBuilder: customIconBuilder,
        onSelected: () => liturgyState.setVotiveOffice(office),
        selected: liturgyState.votiveOffice == office,
        dividerBefore: dividerBefore,
      );

  return <PopupMenuChoice>[
    const PopupMenuChoice(
      title: 'Mode nuit',
      icon: Icons.dark_mode_outlined,
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
        officeChoice('Office du jour', null,
            icon: Icons.today, dividerBefore: true),
      if (advancedModeEnabled) ...[
        officeChoice('Office de la Dédicace', VotiveOffice.dedication,
            icon: Icons.church,
            dividerBefore: liturgyState.votiveOffice == null),
        officeChoice('Office des défunts', VotiveOffice.departed,
            customIconBuilder: _crossIcon),
        PopupMenuChoice(
          title: 'Psaumes et Cantiques\nen langues anciennes',
          customIconText: 'αא',
          onSelected: () => liturgyState.updateOriginalPsalmLanguage(
              !liturgyState.useOriginalPsalmLanguage),
          selected: liturgyState.useOriginalPsalmLanguage,
          dividerBefore: true,
        ),
      ],
    ],
    PopupMenuChoice(
        title: 'Paramètres',
        icon: Icons.settings_outlined,
        widget: const Text(''),
        dividerBefore: offlineLiturgyEnabled),
    const PopupMenuChoice(
        title: 'À propos', icon: Icons.info_outline, widget: Text('')),
  ];
}
