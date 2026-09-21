import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DatePickerHelper {
  /// Constant for the French locale to ensure consistency across the app
  static const String _locale = 'fr_FR';

  /// The date currently selected by the user
  DateTime selectedDate = DateTime.now();

  /// Opens the date picker dialog, with an "Aujourd'hui" shortcut that jumps
  /// straight back to today alongside the regular calendar grid.
  /// Returns [true] if the user picked a new date, [false] otherwise.
  Future<bool> selectDate(BuildContext context) async {
    DateTime pendingDate = selectedDate;
    // Bumped only by the "Aujourd'hui" shortcut, to force CalendarDatePicker
    // to remount and re-center on today — it otherwise only reads
    // initialDate once, at its own initState.
    int resetCounter = 0;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => Localizations.override(
        context: dialogContext,
        locale: const Locale('fr', 'FR'),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            // The default TextButton color (colorScheme.primary) is the
            // app's red brand accent in light mode, but in dark mode it's a
            // near-black tone meant for the AppBar — unreadable here.
            // colorScheme.secondary carries the same red accent in light mode
            // and the equivalent readable accent (salmon) in dark mode.
            final actionStyle = TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.secondary,
            );
            return AlertDialog(
              contentPadding: const EdgeInsets.only(top: 16),
              content: SizedBox(
                width: 300,
                height: 380,
                child: CalendarDatePicker(
                  key: ValueKey(resetCounter),
                  initialDate: pendingDate,
                  firstDate: DateTime(2016),
                  lastDate: DateTime(2101),
                  onDateChanged: (date) =>
                      setDialogState(() => pendingDate = date),
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  style: actionStyle,
                  onPressed: () => setDialogState(() {
                    pendingDate = DateTime.now();
                    resetCounter++;
                  }),
                  child: const Text("Aujourd'hui"),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      style: actionStyle,
                      onPressed: () => Navigator.pop(dialogContext, null),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      style: actionStyle,
                      onPressed: () =>
                          Navigator.pop(dialogContext, pendingDate),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );

    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      return true;
    }
    return false;
  }

  /// Returns the date formatted as an ISO string (YYYY-MM-DD).
  /// This is used for API calls and internal state logic.
  String getRawDateString() {
    return DateFormat('yyyy-MM-dd').format(selectedDate);
  }

  /// Returns a human-readable string (e.g., "Aujourd'hui", "Lundi dernier").
  /// [longView] true: "Lundi prochain", false: "Lun. prochain".
  String formatToPrettyString({bool longView = true}) {
    final now = DateTime.now();

    // Strip time to compare dates only
    final DateTime dateOnly =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final DateTime nowOnly = DateTime(now.year, now.month, now.day);

    // Calculate the difference in days correctly
    final int difference = dateOnly.difference(nowOnly).inDays;

    // 1. Handle relative specific days
    final Map<int, String> relativeDays = {
      -1: "Hier",
      0: "Aujourd’hui",
      1: "Demain",
    };

    if (relativeDays.containsKey(difference)) {
      return relativeDays[difference]!;
    }

    // 2. Handle the current week range (-7 to +7 days)
    if (difference.abs() < 8) {
      String dayName = longView
          ? DateFormat.EEEE(_locale).format(selectedDate)
          : DateFormat.E(_locale).format(selectedDate);

      String suffix = difference > 0 ? 'prochain' : 'dernier';
      return "${_capitalize(dayName)} $suffix";
    }

    // 3. Handle distant dates
    String pattern;
    if (selectedDate.year != now.year) {
      // Different year: include it in the format
      pattern = longView
          ? DateFormat.yMMMMEEEEd(_locale).pattern!
          : DateFormat.yMMMEd(_locale).pattern!;
    } else {
      // Same year: keep it simple
      pattern = longView
          ? DateFormat.MMMMEEEEd(_locale).pattern!
          : DateFormat.MMMEd(_locale).pattern!;
    }

    return _capitalize(DateFormat(pattern, _locale).format(selectedDate));
  }

  /// Internal helper to capitalize the first letter and lowercase the rest
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
