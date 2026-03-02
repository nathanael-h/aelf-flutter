import 'package:flutter/material.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/utils/bible_reference_fetcher.dart';

class ScriptureWidget extends StatelessWidget {
  final String title;
  final String? reference;
  final String? content;
  final TextStyle? titleStyle;
  final TextStyle? referenceStyle;
  final TextStyle? contentStyle;
  final double? spacing;

  const ScriptureWidget({
    super.key,
    required this.title,
    this.reference,
    this.content,
    this.titleStyle,
    this.referenceStyle,
    this.contentStyle,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiturgyPartTitle(
          title,
          trailing: (reference != null && reference!.isNotEmpty)
              ? (zoom) => GestureDetector(
                    onTap: () => refButtonPressed(reference!, context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 13 * zoom / 100,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reference!,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12 * zoom / 100,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  )
              : null,
        ),
        SizedBox(height: spacing ?? 16.0),
        if (content != null && content!.isNotEmpty)
          YamlTextFromString(
            content!,
            textStyle: contentStyle,
            textAlign: TextAlign.justify,
          ),
      ],
    );
  }
}
