import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';

/// Widget to display liturgical information about the Compline
class LiturgyInfoWidget extends StatelessWidget {
  const LiturgyInfoWidget({
    super.key,
    required this.complineDefinition,
  });

  final ComplineDefinition complineDefinition;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: spaceBetweenElements),
      child: Text(
        complineDefinition.complineDescription,
        style: const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
