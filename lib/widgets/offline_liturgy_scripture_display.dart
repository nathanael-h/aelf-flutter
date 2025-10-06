import 'package:flutter/material.dart';
import '../app_screens/layout_config.dart';
import './liturgy_part_title.dart';

class ScriptureWidget extends StatelessWidget {
  final String title;
  final String? reference;
  final String? content;
  final TextStyle? titleStyle;
  final TextStyle? referenceStyle;
  final TextStyle? contentStyle;
  final double? spacing;

  const ScriptureWidget({
    Key? key,
    required this.title,
    this.reference,
    this.content,
    this.titleStyle,
    this.referenceStyle,
    this.contentStyle,
    this.spacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and reference
        Row(
          children: [
            LiturgyPartTitle(title),
            if (reference != null && reference!.isNotEmpty)
              Expanded(
                child: Text(
                  reference!,
                  style: biblicalReferenceStyle,
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),

        // Spacing
        SizedBox(height: spacing ?? 16.0),

        // Reading content
        if (content != null && content!.isNotEmpty)
          Text(
            content!,
            style: psalmContentStyle,
          ),
      ],
    );
  }
}
