import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content.dart';
import 'package:aelf_flutter/widgets/liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:flutter/material.dart';
import '../app_screens/layout_config.dart';
import 'offline_liturgy_antiphon_display.dart';

class PsalmWidget extends StatelessWidget {
  const PsalmWidget({
    super.key,
    required this.psalmKey,
    required this.psalms,
    this.antiphon1,
    this.antiphon2,
    this.antiphon3,
  });

  final String? psalmKey;
  final Map<String, dynamic> psalms;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;

  // Getter to check if antiphon should be displayed
  bool get _hasAntiphon => antiphon1 != null;

  @override
  Widget build(BuildContext context) {
    // Check if psalm exists
    if (psalmKey == null || psalms[psalmKey] == null) {
      return const SizedBox.shrink();
    }

    final dynamic psalm = psalms[psalmKey];

    return ListView(
      padding: const EdgeInsets.all(0),
      children: _buildPsalmContent(psalm),
    );
  }

  List<Widget> _buildPsalmContent(dynamic psalm) {
    return [
      // Psalm title
      LiturgyPartContentTitle(psalm.getTitle),
      //SizedBox(height: spaceBetweenElements),

      // Psalm subtitle (conditional)
      if (psalm.getSubtitle != null) ...[
        LiturgyPartSubtitle(psalm.getSubtitle),
        //SizedBox(height: spaceBetweenElements),
      ],

      // Psalm commentary (conditional)
      if (psalm.getCommentary != null) ...[
        LiturgyPartCommentary(psalm.getCommentary),
        SizedBox(height: spaceBetweenElements),
      ],

      // Antiphon before Psalm
      if (_hasAntiphon) ...[
        _buildAntiphon(),
        SizedBox(height: spaceBetweenElements),
      ],

      // Psalm content
      LiturgyPartContent(psalm.getContent),

      // Antiphon after Psalm
      if (_hasAntiphon) ...[
        SizedBox(height: spaceBetweenElements),
        _buildAntiphon(),
      ],
    ];
  }

  Widget _buildAntiphon() {
    return AntiphonWidget(
      antiphon1: antiphon1!,
      antiphon2: antiphon2,
      antiphon3: antiphon3,
    );
  }
}
