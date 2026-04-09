import 'package:aelf_flutter/models/popup_menu_choice.dart';
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

List<PopupMenuChoice> popupMenuChoices = <PopupMenuChoice>[
  const PopupMenuChoice(
    title: 'Mode nuit',
    icon: Icons.directions_bus,
    widget: _DarkModeSwitch(),
  ),
  const PopupMenuChoice(
      title: 'Paramètres', icon: Icons.directions_walk, widget: Text('')),
  const PopupMenuChoice(
      title: 'A propos', icon: Icons.directions_walk, widget: Text('')),
];
