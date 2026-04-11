import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';

class LiturgyPartContentTitle extends StatelessWidget {
  final String? content;
  final Widget Function(double zoom)? trailing;

  const LiturgyPartContentTitle(this.content, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    final contentStyle = Theme.of(context).textTheme.titleMedium!;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: LiturgyRow(
        hideVerseIdPlaceholder: true,
        builder: (context, zoom) {
          final titleWidget = YamlTextWidget(
            paragraphs: YamlTextParser.parseText(content!),
            textStyle: TextStyle(
              fontSize: contentStyle.fontSize! * (zoom ?? 100) / 100,
              fontWeight: contentStyle.fontWeight,
              color: contentStyle.color,
            ),
            paragraphSpacing: 0,
            redColor: Theme.of(context).colorScheme.secondary,
          );

          final trailingWidget =
              trailing != null ? trailing!(zoom ?? 100) : null;
          if (trailingWidget == null) return titleWidget;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: titleWidget),
              trailingWidget,
            ],
          );
        },
      ),
    );
  }
}
