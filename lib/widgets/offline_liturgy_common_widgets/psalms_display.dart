import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';

/// Displays a psalm with antiphons.
/// Receives pre-hydrated Psalm data directly (no YAML loading).
class PsalmDisplayWidget extends StatelessWidget {
  const PsalmDisplayWidget({
    super.key,
    required this.psalm,
    this.antiphon1,
    this.antiphon2,
    this.antiphon3,
    this.verseAfter,
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;
  final String? verseAfter;

  bool get _hasAntiphon => antiphon1 != null;

  @override
  Widget build(BuildContext context) {
    if (psalm == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        // Psalm title
        LiturgyPartContentTitle(psalm!.getTitle),

        // Psalm subtitle (conditional)
        if (psalm!.getSubtitle != null) LiturgyPartSubtitle(psalm!.getSubtitle),

        // Psalm commentary (conditional)
        if (psalm!.getCommentary != null) ...[
          LiturgyPartCommentary(psalm!.getCommentary),
          SizedBox(height: spaceBetweenElements),
        ],

        SizedBox(height: spaceBetweenElements),

        // Antiphon before Psalm
        if (_hasAntiphon) ...[
          AntiphonWidget(
            antiphon1: antiphon1!,
            antiphon2: antiphon2,
            antiphon3: antiphon3,
          ),
          SizedBox(height: spaceBetweenElements),
        ],

        // Psalm content with verse numbers
        PsalmFromHtml(htmlContent: psalm!.getContent),

        // Antiphon after Psalm
        if (_hasAntiphon) ...[
          SizedBox(height: spaceBetweenElements),
          AntiphonWidget(
            antiphon1: antiphon1!,
            antiphon2: antiphon2,
            antiphon3: antiphon3,
          ),
        ],

        // Verse after Psalm (if provided)
        if (verseAfter != null && verseAfter!.isNotEmpty) ...[
          SizedBox(height: spaceBetweenElements),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LiturgyPartFormattedText(
              verseAfter!,
              includeVerseIdPlaceholder: false,
            ),
          ),
        ],
      ],
    );
  }
}
