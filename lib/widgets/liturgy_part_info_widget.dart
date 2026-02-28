import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:offline_liturgy/tools/date_tools.dart';

/// Widget to display liturgical information about the Compline
class LiturgyPartInfoWidget extends StatelessWidget {
  const LiturgyPartInfoWidget({
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

    if (additionalInfo == null) return const SizedBox.shrink();
    final info = additionalInfo;

    return LiturgyRow(
      builder: (context, zoom) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          info,
          style: TextStyle(
            fontSize: 12 * (zoom ?? 100) / 100,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}
