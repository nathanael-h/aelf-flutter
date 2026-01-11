import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';

class LiturgyPartRubric extends StatelessWidget {
  final String? content;

  const LiturgyPartRubric(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retour anticipé si pas de contenu
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return LiturgyRow(
      builder: (context, zoom) => Text(
        content!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 12 * (zoom ?? 100) / 100,
        ),
      ),
    );
  }
}
