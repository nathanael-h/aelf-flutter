import 'package:aelf_flutter/models/popup_menu_choice.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';
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

/// Builds the 3-dot menu entries. "Mode défilement" only appears once the
/// beta offline liturgy feature is enabled, mirroring its gating in the
/// Settings screen.
List<PopupMenuChoice> buildPopupMenuChoices(BuildContext context) {
  final offlineLiturgyEnabled =
      context.read<FeatureFlagsState>().offlineLiturgyEnabled;

  return <PopupMenuChoice>[
    const PopupMenuChoice(
      title: 'Mode nuit',
      icon: Icons.directions_bus,
      widget: _DarkModeSwitch(),
    ),
    if (offlineLiturgyEnabled)
      const PopupMenuChoice(
        title: 'Mode défilement',
        icon: Icons.swap_vert,
        widget: _ScrollModeSwitch(),
      ),
    const PopupMenuChoice(
        title: 'Paramètres', icon: Icons.directions_walk, widget: Text('')),
    const PopupMenuChoice(
        title: 'À propos', icon: Icons.directions_walk, widget: Text('')),
  ];
}
