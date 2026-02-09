import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';

class CanticleWidget extends StatelessWidget {
  final String antiphon1;
  final String? antiphon2;
  final Psalm psalm;

  const CanticleWidget({
    super.key,
    required this.antiphon1,
    required this.psalm,
    this.antiphon2,
  });

  @override
  Widget build(BuildContext context) {
    // Création unique de l'antienne
    final Widget antiphonBlock = AntiphonWidget(
      antiphon1: antiphon1,
      antiphon2: antiphon2,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre principal (ex: "Cantique de Zacharie")
          LiturgyPartTitle(psalm.title ?? ''),

          SizedBox(height: spaceBetweenElements),

          // Antienne avant
          antiphonBlock,

          SizedBox(height: spaceBetweenElements),

          // Texte biblique du cantique
          // Assure-toi d'utiliser le nom de classe présent dans ton psalm_parser.dart
          PsalmFromMarkdown(content: psalm.getContent),

          SizedBox(height: spaceBetweenElements),

          // Antienne répétée à la fin
          antiphonBlock,
        ],
      ),
    );
  }
}
