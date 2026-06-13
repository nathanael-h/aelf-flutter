import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_middle_of_day_view.dart';

class NoneView extends StatelessWidget {
  const NoneView({
    super.key,
    required this.middleOfDayList,
    required this.date,
    required this.calendar,
  });

  final Map<String, CelebrationContext> middleOfDayList;
  final DateTime date;
  final Calendar calendar;

  @override
  Widget build(BuildContext context) {
    return MiddleOfDayOfficeView(
      middleOfDayList: middleOfDayList,
      date: date,
      calendar: calendar,
      hymnSelector: (data) => data.hymnNone,
      hourOfficeSelector: (data) => data.none,
      psalmodySelector: (data) => data.psalmodyNone ?? data.psalmody,
    );
  }
}
