import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:flutter/material.dart';

class LiturgyPartRubric extends StatelessWidget {
  final String? content;

  const LiturgyPartRubric(this.content, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return LiturgyRow(
      builder: (context, zoom) => YamlTextWidget(
        paragraphs: YamlTextParser.parseText(content!),
        textStyle: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 12 * (zoom ?? 100) / 100,
          height: 1.4,
        ),
      ),
    );
  }
}
