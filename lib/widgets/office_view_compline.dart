import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:aelf_flutter/widgets/office_view/office_view.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';

/// Compline view using the unified office architecture
class ComplineViewUnified extends StatelessWidget {
  const ComplineViewUnified({
    super.key,
    required this.complineDefinitionsList,
    required this.dataLoader,
    required this.calendar,
    required this.date,
  });

  final Map<String, ComplineDefinition> complineDefinitionsList;
  final DataLoader dataLoader;
  final Calendar calendar;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return OfficeView(
      config: OfficeConfig.forCompline(),
      definitions: complineDefinitionsList,
      date: date,
      dataLoader: dataLoader,
      additionalData: _AdditionalData(
        calendar: calendar,
        date: date,
      ),
    );
  }
}

/// Helper class to pass additional data to office view
class _AdditionalData {
  final Calendar calendar;
  final DateTime date;

  _AdditionalData({
    required this.calendar,
    required this.date,
  });
}
