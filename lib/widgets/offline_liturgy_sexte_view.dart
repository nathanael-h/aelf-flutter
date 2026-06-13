import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_middle_of_day_view.dart';

class SexteView extends StatelessWidget {
  const SexteView({
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
      hymnSelector: (data) => data.hymnSexte,
      hourOfficeSelector: (data) => data.sexte,
      psalmodySelector: (data) => data.psalmodySexte ?? data.psalmody,
    );
  }
}
