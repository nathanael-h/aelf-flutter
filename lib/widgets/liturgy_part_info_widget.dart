import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/classes/compline_class.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:provider/provider.dart';

/// Widget to display liturgical information about the Compline
class LiturgyPartInfoWidget extends StatelessWidget {
  const LiturgyPartInfoWidget({
    super.key,
    required this.complineDefinition,
  });

  final ComplineDefinition complineDefinition;

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) => Row(
        children: [
          verseIdPlaceholder(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: spaceBetweenElements),
              child: Text(
                complineDefinition.complineDescription,
                style: TextStyle(
                  fontSize: 14 * currentZoom.value! / 100,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
