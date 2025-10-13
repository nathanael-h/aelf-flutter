import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import '../parsers/psalm_parser.dart';
import '../app_screens/layout_config.dart';
import '../widgets/offline_liturgy_antiphon_display.dart';
import './liturgy_part_title.dart';

class CanticleWidget extends StatelessWidget {
  final String canticleType; // "magnificat", "benedictus", or "nunc_dimittis"
  final String antiphon1;
  final String? antiphon2; // Optional second antiphon

  const CanticleWidget({
    super.key,
    required this.canticleType,
    required this.antiphon1,
    this.antiphon2,
  });

  String _getPsalmKey() {
    switch (canticleType.toLowerCase()) {
      case 'magnificat':
        return 'NT_1';
      case 'benedictus':
        return 'NT_2';
      case 'nunc_dimittis':
        return 'NT_3';
      default:
        throw ArgumentError('Invalid canticle type: $canticleType');
    }
  }

  @override
  Widget build(BuildContext context) {
    final psalmKey = _getPsalmKey();
    final psalm = psalms[psalmKey];

    if (psalm == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        // Title and reference row
        Row(
          children: [
            LiturgyPartTitle('${psalm.title!} (${psalm.biblicalReference!})'),
            Expanded(
              child: Text(
                psalm.shortReference!,
                style: biblicalReferenceStyle,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        SizedBox(height: spaceBetweenElements),

        // First antiphon
        AntiphonWidget(
          antiphon1: antiphon1,
          antiphon2: antiphon2,
          antiphon3: null,
        ),
        SizedBox(height: spaceBetweenElements),

        // Canticle content
        SizedBox(height: spaceBetweenElements),
        PsalmFromHtml(htmlContent: psalm.getContent),

        // Second antiphon
        SizedBox(height: spaceBetweenElements),
        AntiphonWidget(
          antiphon1: antiphon1,
          antiphon2: antiphon2,
          antiphon3: null,
        ),
      ],
    );
  }
}
