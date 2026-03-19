import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';

class LiturgyPartTitle extends StatelessWidget {
  final String? content;
  final Widget Function(double zoom)? trailing;

  const LiturgyPartTitle(this.content, {Key? key, this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    final sectionStyle = Theme.of(context).textTheme.headlineSmall!;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LiturgyRow(
        hideVerseIdPlaceholder: true,
        builder: (context, zoom) {
          final titleWidget = YamlTextWidget(
            paragraphs: YamlTextParser.parseText(content!),
            textStyle: TextStyle(
              fontSize: sectionStyle.fontSize! * (zoom ?? 100) / 100,
              fontWeight: sectionStyle.fontWeight,
              color: sectionStyle.color,
            ),
            paragraphSpacing: 0,
            redColor: Theme.of(context).colorScheme.secondary,
          );

          final trailingWidget = trailing != null ? trailing!(zoom ?? 100) : null;
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
