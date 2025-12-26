import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiturgyPartRubric extends StatelessWidget {
  final String? content;

  const LiturgyPartRubric(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retour anticipé si pas de contenu
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Consumer<CurrentZoom>(builder: (context, currentZoom, child) {
      final fontSize = 12 * (currentZoom.value ?? 100) / 100;

      return Row(
        children: [
          verseIdPlaceholder(),
          Expanded(
            child: Text(content!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: fontSize,
                )),
          ),
        ],
      );
    });
  }
}
