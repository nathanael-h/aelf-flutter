import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import '../app_screens/layout_config.dart';

/// Widget to display liturgical information about the Compline
class LiturgyInfoWidget extends StatelessWidget {
  const LiturgyInfoWidget({
    super.key,
    required this.complineDefinition,
    required this.celebrationName,
  });

  final ComplineDefinition complineDefinition;
  final String celebrationName;

  String _buildLiturgyDescription() {
    final celebrationType = complineDefinition.celebrationType;
    final liturgicalTime =
        liturgicalTimeLabels[complineDefinition.liturgicalTime] ?? '';
    final dayOfWeek = dayOfWeekLabels[complineDefinition.dayOfWeek] ?? '';
    final feastName = liturgyLabels[celebrationName] ?? celebrationName;

    // For Solemnity Eve
    if (celebrationType == 'SolemnityEve') {
      return 'Complies de la veille de la solennité de $feastName';
    }

    // For Solemnity
    if (celebrationType == 'Solemnity') {
      return 'Complies de la solennité de $feastName';
    }

    // For Holy Week days
    if (celebrationType == 'holy_thursday') {
      return 'Complies du Jeudi Saint';
    }
    if (celebrationType == 'holy_friday') {
      return 'Complies du Vendredi Saint';
    }
    if (celebrationType == 'holy_saturday') {
      return 'Complies du Samedi Saint';
    }

    // For normal ferial days
    return 'Complies du $dayOfWeek du $liturgicalTime';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _buildLiturgyDescription(),
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}
