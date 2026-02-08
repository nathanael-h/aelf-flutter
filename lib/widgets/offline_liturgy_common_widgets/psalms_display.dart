import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';

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

  @override
  Widget build(BuildContext context) {
    if (psalm == null) return const SizedBox.shrink();

    // Padding standard pour les éléments textuels (titres, antiennes)
    // pour qu'ils ne collent pas aux bords, maintenant que la ListView est à 0.
    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);

    Widget? antiphonBlock;
    if (antiphon1 != null && antiphon1!.isNotEmpty) {
      antiphonBlock = Padding(
        padding: kContentPadding,
        child: AntiphonWidget(
          antiphon1: antiphon1!,
          antiphon2: antiphon2,
          antiphon3: antiphon3,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Titres avec padding
        Padding(
          padding: kContentPadding,
          child: LiturgyPartContentTitle(psalm!.getTitle),
        ),
        if (psalm!.getSubtitle != null)
          Padding(
            padding: kContentPadding,
            child: LiturgyPartSubtitle(psalm!.getSubtitle!),
          ),
        if (psalm!.getCommentary != null) ...[
          Padding(
            padding: kContentPadding,
            child: LiturgyPartCommentary(psalm!.getCommentary!),
          ),
          SizedBox(height: spaceBetweenElements),
        ],
        SizedBox(height: spaceBetweenElements),

        // Antiennes (déjà wrappées dans le padding plus haut)
        if (antiphonBlock != null) ...[
          antiphonBlock,
          SizedBox(height: spaceBetweenElements),
        ],

        // LE CORPS DU PSAUME : Pas de padding supplémentaire ici !
        // Il utilisera ses propres marges internes.
        PsalmFromMarkdown(content: psalm!.getContent),

        if (antiphonBlock != null) ...[
          SizedBox(height: spaceBetweenElements),
          antiphonBlock,
        ],

        if (verseAfter != null && verseAfter!.isNotEmpty) ...[
          SizedBox(height: spaceBetweenElements),
          Padding(
            padding: kContentPadding,
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
