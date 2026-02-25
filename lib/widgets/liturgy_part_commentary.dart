import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiturgyPartCommentary extends StatelessWidget {
  final String? content;

  const LiturgyPartCommentary(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value ?? 100.0;
        return LiturgyPartFormattedText(
          content!,
          textStyle: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 12 * zoom / 100,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.4,
          ),
          includeVerseIdPlaceholder: true,
        );
      },
    );
  }
}
