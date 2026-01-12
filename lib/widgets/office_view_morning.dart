import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/classes/morning_class.dart';
import 'package:aelf_flutter/widgets/office_view/office_view.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';

/// Morning Prayer view using the unified office architecture
class MorningViewUnified extends StatelessWidget {
  const MorningViewUnified({
    super.key,
    required this.morningList,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, MorningDefinition> morningList;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  Widget build(BuildContext context) {
    return OfficeView(
      config: OfficeConfig.forMorning(),
      definitions: morningList,
      date: date,
      dataLoader: dataLoader,
    );
  }
}
