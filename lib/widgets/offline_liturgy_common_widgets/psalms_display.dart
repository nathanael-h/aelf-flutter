import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart'; // Assure-toi que le chemin est correct
import 'package:offline_liturgy/classes/psalms_class.dart';

/// Affiche un psaume avec ses antiennes et métadonnées.
/// Le SingleChildScrollView empêche l'erreur de RenderFlex overflow.
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

    // Préparation de l'antienne pour éviter la duplication de code
    Widget? antiphonBlock;
    if (antiphon1 != null && antiphon1!.isNotEmpty) {
      antiphonBlock = AntiphonWidget(
        antiphon1: antiphon1!,
        antiphon2: antiphon2,
        antiphon3: antiphon3,
      );
    }

    return SingleChildScrollView(
      // Nous gardons le scroll ici pour éviter les erreurs de dépassement
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre du psaume (ex: "Psaume 62")
          LiturgyPartContentTitle(psalm!.getTitle),

          // Sous-titre (ex: "Dieu, ma soif de toi")
          if (psalm!.getSubtitle != null)
            LiturgyPartSubtitle(psalm!.getSubtitle!),

          // Commentaire rouge/italique optionnel
          if (psalm!.getCommentary != null) ...[
            LiturgyPartCommentary(psalm!.getCommentary!),
            SizedBox(height: spaceBetweenElements),
          ],

          SizedBox(height: spaceBetweenElements),

          // Antienne avant le psaume
          if (antiphonBlock != null) ...[
            antiphonBlock,
            SizedBox(height: spaceBetweenElements),
          ],

          // Corps du psaume avec numéros de versets
          // Note : Utilise PsalmFromMarkdown si tu as renommé le widget dans psalm_parser
          PsalmFromMarkdown(content: psalm!.getContent),

          // Antienne après le psaume
          if (antiphonBlock != null) ...[
            SizedBox(height: spaceBetweenElements),
            antiphonBlock,
          ],

          // Verset final optionnel (souvent pour l'Office des Lectures)
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
      ),
    );
  }
}
