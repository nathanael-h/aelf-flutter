import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_middle_of_day_view.dart';

class SexteView extends StatelessWidget {
  const SexteView({
    super.key,
    required this.middleOfDayList,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, CelebrationContext> middleOfDayList;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  Widget build(BuildContext context) {
    return MiddleOfDayOfficeView(
      middleOfDayList: middleOfDayList,
      date: date,
      dataLoader: dataLoader,
      hymnSelector: (data) => data.hymnSexte,
      hourOfficeSelector: (data) => data.sexte,
    );
  }
}
