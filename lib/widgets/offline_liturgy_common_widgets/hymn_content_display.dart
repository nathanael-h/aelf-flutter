import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HymnContentDisplay extends StatelessWidget {
  final String content;
  final TextStyle? baseStyle;

  const HymnContentDisplay({
    super.key,
    required this.content,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoomValue = currentZoom.value ?? 100.0;
        return YamlTextWidget(
          paragraphs: YamlTextParser.parseText(content),
          textStyle: baseStyle ??
              TextStyle(
                fontSize: 16.0 * zoomValue / 100,
                height: 1.5,
                color: bodyColor,
              ),
          paragraphSpacing: 12.0,
        );
      },
    );
  }
}
