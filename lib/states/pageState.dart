import 'dart:developer';

import 'package:flutter/material.dart';

class PageState extends ChangeNotifier {
  String yolo = "yolo";
  bool datePickerVisible = true;
  bool searchVisible = false;
  String title = "Titre";
  var activeAppSection;

  PageState() {
    print("PageState init 1");
  }

  void function(String yolo) {
    yolo = yolo + yolo;
    notifyListeners();
  }

  void changeSearchButtonVisibility(bool Bool) {
    log("changeSearchButtonVisibility to $Bool");
    searchVisible = Bool;
    notifyListeners();
  }

  void changeDatePickerButtonVisibility (bool Bool) {
    log("changeDatePickerButtonVisibility to $Bool");
    datePickerVisible = Bool;
  }
}
