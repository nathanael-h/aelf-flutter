import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_middle_of_day_view.dart';

class NoneView extends StatelessWidget {
  const NoneView({
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
      hymnSelector: (data) => data.hymnNone,
      hourOfficeSelector: (data) => data.none,
    );
  }
}
