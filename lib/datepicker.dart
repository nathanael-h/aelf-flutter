import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DatePicker {
  DatePicker();

  Map<int, String> dateName = {
    -1: "Hier",
    0: "Aujourd'hui",
    1: "Demain",
  };

  DateTime selectedDate = DateTime.now();

  // date picker
  Future<Null> selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
        context: context,
        locale: const Locale('fr', 'FR'),
        initialDate: selectedDate,
        firstDate: DateTime(2016),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
    }
  }

  String getDate() {
    return "${selectedDate.toLocal()}".split(' ')[0];
  }

  DateTime nowDay() {
    // get today date - yyyyMMdd000000
    String date = DateFormat("yyyyMMddhhmmss").format(DateTime.now());
    return DateTime.parse(date.substring(0, 8));
  }

  String? internalPrettyString(bool longView) {
    // get diff between date selected and now
    int difference = selectedDate.toLocal().difference(nowDay()).inDays;

    // if day is yesterday, today or tomorow
    if (difference >= -1 && difference <= 1) {
      return dateName[difference];
    } else if (difference > -9 && difference < 9) {
      // get day name
      String dayName = longView
          ? DateFormat.EEEE('fr_FR').format(selectedDate)
          : DateFormat.E('fr_FR').format(selectedDate);
      // return day + prochain/dernier according to difference
      return "${capitalize(dayName)} ${difference > 0 ? 'prochain' : 'dernier'}";
    } else if (!isSameYear(selectedDate)) {
      // return date ex: "Lun. 1 janv. 2021/Lundi 1 janvier 2021"
      return capitalize(longView
          ? DateFormat.yMMMMEEEEd('fr_FR').format(selectedDate)
          : DateFormat.yMMMEd('fr_FR').format(selectedDate));
    }

    // default return date ex: "Lun. 1 janv./Lundi 1 janvier"
    return capitalize(longView
        ? DateFormat.MMMMEEEEd('fr_FR').format(selectedDate)
        : DateFormat.MMMEd('fr_FR').format(selectedDate));
  }

  bool isSameYear(DateTime date) {
    return (date.year == DateTime.now().year);
  }

  String? toPrettyString() {
    return internalPrettyString(true);
  }

  String? toShortPrettyString() {
    return internalPrettyString(false);
  }

  String capitalize(String s) {
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
