import 'dart:developer';

import 'package:flutter/material.dart';

class PageState extends ChangeNotifier {
  bool datePickerVisible = true;
  bool searchVisible = false;
  String title = "Titre";
  var activeAppSection;

  PageState() {
    print("PageState init 1");
  }

  void changeSearchButtonVisibility(bool Bool) {
    log("changeSearchButtonVisibility to $Bool");
    searchVisible = Bool;
    notifyListeners();
  }

  void changeDatePickerButtonVisibility(bool Bool) {
    log("changeDatePickerButtonVisibility to $Bool");
    datePickerVisible = Bool;
    notifyListeners();
  }

  void changePageTitle(String newTitle) {
    log("changePageTitle to $newTitle");
    title = newTitle;
    notifyListeners();
  }

  void changeActiveAppSection(var newAppSection) {
    log("changeActiveAppSection to $newAppSection");
    activeAppSection = newAppSection;
    notifyListeners();
  }
}
