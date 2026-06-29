import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';

class OfflineLiturgyPartSubtitle extends StatelessWidget {
  final String? content;
  final Widget Function(double zoom)? trailing;
  final bool hideVerseIdPlaceholder;

  const OfflineLiturgyPartSubtitle(this.content,
      {super.key, this.trailing, this.hideVerseIdPlaceholder = true});

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }
    return LiturgyRow(
      hideVerseIdPlaceholder: hideVerseIdPlaceholder,
      builder: (context, zoom) {
        final textWidget = YamlTextWidget(
          paragraphs: YamlTextParser.parseText(content!),
          textStyle: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 16 * (zoom ?? 100) / 100,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          paragraphSpacing: 0,
          redColor: Theme.of(context).colorScheme.secondary,
        );

        final trailingWidget =
            trailing != null ? trailing!(zoom ?? 100) : null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (trailingWidget != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: textWidget),
                  trailingWidget,
                ],
              )
            else
              textWidget,
            SizedBox(height: 4 * (zoom ?? 100) / 100),
          ],
        );
      },
    );
  }
}
