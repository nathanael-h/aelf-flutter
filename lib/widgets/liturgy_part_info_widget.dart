import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:offline_liturgy/classes/calendar_class.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/tools/date_tools.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:provider/provider.dart';

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

    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) => Row(
        children: [
          verseIdPlaceholder(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: spaceBetweenElements),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14 * currentZoom.value! / 100,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (additionalInfo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      additionalInfo,
                      style: TextStyle(
                        fontSize: 12 * currentZoom.value! / 100,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
