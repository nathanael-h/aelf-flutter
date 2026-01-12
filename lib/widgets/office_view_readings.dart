import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/classes/readings_class.dart';
import 'package:aelf_flutter/widgets/office_view/office_view.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';

/// Office of Readings view using the unified office architecture
class ReadingsViewUnified extends StatelessWidget {
  const ReadingsViewUnified({
    super.key,
    required this.readingsDefinitions,
    required this.date,
    required this.dataLoader,
  });

  final Map<String, ReadingsDefinition> readingsDefinitions;
  final DateTime date;
  final DataLoader dataLoader;

  @override
  Widget build(BuildContext context) {
    return OfficeView(
      config: OfficeConfig.forReadings(),
      definitions: readingsDefinitions,
      date: date,
      dataLoader: dataLoader,
    );
  }
}
