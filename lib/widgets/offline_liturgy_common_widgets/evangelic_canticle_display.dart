import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';

class CanticleWidget extends StatelessWidget {
  final String antiphon1;
  final String? antiphon2;
  final String? antiphonLabel2;
  final Psalm psalm;

  const CanticleWidget({
    super.key,
    required this.antiphon1,
    required this.psalm,
    this.antiphon2,
    this.antiphonLabel2,
  });

  @override
  Widget build(BuildContext context) {
    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);

    // On prépare le bloc d'antienne avec son padding
    final Widget antiphonBlock = Padding(
      padding: kContentPadding,
      child: AntiphonWidget(
        antiphon1: antiphon1,
        antiphon2: antiphon2,
        label2: antiphonLabel2,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Titre avec padding
        Padding(
          padding: kContentPadding,
          child: LiturgyPartTitle(psalm.title ?? ''),
        ),

        SizedBox(height: spaceBetweenElements),

        // Antienne d'ouverture
        antiphonBlock,

        SizedBox(height: spaceBetweenElements),

        // Corps du texte (NT_1) : Pas de padding supplémentaire
        PsalmFromMarkdown(content: psalm.getContent),

        SizedBox(height: spaceBetweenElements),

        // Antienne de fermeture
        antiphonBlock,
      ],
    );
  }
}
