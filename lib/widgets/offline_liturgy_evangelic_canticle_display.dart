import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import '../app_screens/layout_config.dart';
import '../widgets/offline_liturgy_antiphon_display.dart';
import '../app_screens/liturgy_formatter.dart';

class CanticleWidget extends StatelessWidget {
  final String canticleType; // "magnificat", "benedictus", or "nunc_dimittis"
  final String antiphon1;
  final String? antiphon2; // Optional second antiphon

  const CanticleWidget({
    Key? key,
    required this.canticleType,
    required this.antiphon1,
    this.antiphon2,
  }) : super(key: key);

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
      padding: const EdgeInsets.all(16),
      children: [
        // Title and reference row
        Row(
          children: [
            Text(
              '${psalm.title!} (${psalm.biblicalReference!})',
              style: psalmTitleStyle,
            ),
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
        Html(
          data: correctAelfHTML(psalm.content),
        ),

        // Second antiphon
        AntiphonWidget(
          antiphon1: antiphon1,
          antiphon2: antiphon2,
          antiphon3: null,
        ),
      ],
    );
  }
}
