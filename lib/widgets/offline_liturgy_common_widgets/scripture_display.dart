import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';

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
        LiturgyPartTitle(title),
        if (reference != null && reference!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              reference!,
              style: referenceStyle ??
                  TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.normal,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        SizedBox(height: spacing ?? 16.0),
        if (content != null && content!.isNotEmpty)
          Consumer<CurrentZoom>(
            builder: (context, currentZoom, child) {
              final zoom = currentZoom.value ?? 100.0;
              return LiturgyPartFormattedText(
                content!,
                textStyle: contentStyle ??
                    TextStyle(
                      fontSize: 16.0 * zoom / 100,
                      height: 1.3,
                    ),
                textAlign: TextAlign.justify,
                includeVerseIdPlaceholder: false,
              );
            },
          ),
      ],
    );
  }
}
