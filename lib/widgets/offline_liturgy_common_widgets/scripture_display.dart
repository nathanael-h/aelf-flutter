import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';

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
    final zoom = context.watch<CurrentZoom>().value;
    Widget Function(double z)? referenceTrailing;
    if (reference != null && reference!.isNotEmpty) {
      referenceTrailing =
          (z) => BiblicalReferenceButton(reference: reference!, zoom: z);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiturgyPartContentTitle(title,
            trailing: referenceTrailing, hideVerseIdPlaceholder: false),
        SizedBox(height: spacing ?? 16.0 * zoom / 100),
        if (content != null && content!.isNotEmpty)
          LiturgyRow(
            builder: (context, zoom) => YamlTextFromString(
              content!,
              textStyle: contentStyle,
              textAlign: TextAlign.justify,
            ),
          ),
      ],
    );
  }
}
