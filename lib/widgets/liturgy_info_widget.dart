import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/tools/date_tools.dart';

/// Widget to display liturgical information about the Compline
class LiturgyInfoWidget extends StatelessWidget {
  const LiturgyInfoWidget({
    super.key,
    required this.complineDefinition,
    required this.calendar,
    required this.date,
  });

  final ComplineDefinition complineDefinition;
  final Calendar calendar;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // Display octave name for Christmas and Paschal octaves, otherwise display the regular description
    final isOctave = complineDefinition.liturgicalTime == 'christmasoctave' ||
        complineDefinition.liturgicalTime == 'paschaloctave';

    final displayText = isOctave
        ? liturgicalTimeLabels[complineDefinition.liturgicalTime] ?? complineDefinition.complineDescription
        : complineDefinition.complineDescription;

    // Get liturgical year and breviary week from calendar
    final dayContent = calendar.getDayContent(date);
    String? additionalInfo;

    if (!isOctave && dayContent != null) {
      final year = liturgicalYear(dayContent.liturgicalYear);
      final week = dayContent.breviaryWeek;
      if (week != null) {
        final weekRoman = breviaryWeekToRoman(week);
        additionalInfo = 'Année $year - Semaine $weekRoman';
      } else {
        additionalInfo = 'Année $year';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayText,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (additionalInfo != null) ...[
            const SizedBox(height: 4),
            Text(
              additionalInfo,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
