import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content.dart';
import 'package:aelf_flutter/widgets/liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:flutter/material.dart';
import '../app_screens/layout_config.dart';
import 'offline_liturgy_antiphon_display.dart';

class PsalmWidget extends StatelessWidget {
  final String? psalmKey;
  final Map<String, dynamic> psalms;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;

  const PsalmWidget({
    Key? key,
    required this.psalmKey,
    required this.psalms,
    this.antiphon1,
    this.antiphon2,
    this.antiphon3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if psalm exists
    if (psalmKey == null || psalms[psalmKey] == null) {
      return const SizedBox.shrink();
    }

    final psalm = psalms[psalmKey];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiturgyPartContentTitle(psalm?.getTitle),
        SizedBox(height: spaceBetweenElements),

        // Psalm subtitle (conditional)
        if (psalm?.getSubtitle != null) LiturgyPartSubtitle(psalm.getSubtitle),

        // Psalm commentary (conditional)
        if (psalm?.getCommentary != null) ...[
          SizedBox(height: spaceBetweenElements),
          LiturgyPartCommentary(psalm.getCommentary),
          SizedBox(height: spaceBetweenElements),
        ],

        // Antiphon before Psalm
        if (antiphon1 != null)
          AntiphonWidget(
            antiphon1: antiphon1!,
            antiphon2: antiphon2,
            antiphon3: antiphon3,
          ),

        SizedBox(height: spaceBetweenElements),
        LiturgyPartContent(psalm.getContent),

        // Antiphon after Psalm
        if (antiphon1 != null) SizedBox(height: spaceBetweenElements),
        AntiphonWidget(
          antiphon1: antiphon1!,
          antiphon2: antiphon2,
          antiphon3: antiphon3,
        ),
      ],
    );
  }
}
