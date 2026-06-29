import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiturgyPartContentTitle extends StatelessWidget {
  final String? content;
  final Widget Function(double zoom)? trailing;
  final bool hideVerseIdPlaceholder;

  const LiturgyPartContentTitle(this.content,
      {super.key, this.trailing, this.hideVerseIdPlaceholder = true});

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    final contentColor = Theme.of(context).textTheme.titleMedium?.color;

    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) => Padding(
        padding: EdgeInsets.only(
          top: 10 * currentZoom.value / 100,
          bottom: 2 * currentZoom.value / 100,
        ),
        child: LiturgyRow(
          hideVerseIdPlaceholder: hideVerseIdPlaceholder,
          builder: (context, zoom) {
            final titleWidget = YamlTextWidget(
              paragraphs: YamlTextParser.parseText(content!),
              textStyle: TextStyle(
                fontSize: 16 * (zoom ?? 100) / 100,
                fontWeight: FontWeight.bold,
                color: contentColor,
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
      ),
    );
  }
}
