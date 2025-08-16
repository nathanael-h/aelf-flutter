import 'package:aelf_flutter/models/popup_menu_choice.dart';
import 'package:aelf_flutter/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

List<PopupMenuChoice> popupMenuChoices = <PopupMenuChoice>[
  PopupMenuChoice(
    title: 'Mode nuit',
    icon: Icons.directions_bus,
    widget: Consumer<ThemeNotifier>(
      builder: (context, notifier, child) {
        return Switch(
            value: notifier.darkTheme!,
            onChanged: (value) {
              notifier.toggleTheme();
              Navigator.of(context).pop();
            });
      },
    ),
  ),
  const PopupMenuChoice(
      title: 'Paramètres', icon: Icons.directions_walk, widget: Text('')),
  const PopupMenuChoice(
      title: 'A propos', icon: Icons.directions_walk, widget: Text('')),
];
// A Widget that extracts the necessary arguments from the ModalRoute.

// Source : https://github.com/flutter/samples/blob/master/provider_counter/lib/main.dart

//class DateProvider with ChangeNotifier {
//  DateTime value = DateTime.now();
//
//  void setDate(DateTime newDate) {
//    value = newDate;
//    notifyListeners();
//  }
//
//}
//
