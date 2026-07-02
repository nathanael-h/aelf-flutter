import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiturgyContentTitle extends StatelessWidget {
  const LiturgyContentTitle(
    this.title, {
    super.key,
    this.showBullet = true,
    this.trailing,
  });

  final String title;
  final bool showBullet;
  final Widget Function(double zoom)? trailing;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    final contentColor = Theme.of(context).textTheme.titleMedium?.color;
    final zoom = context.watch<CurrentZoom>().value;
    final trailingWidget = trailing != null ? trailing!(zoom) : null;

    return Padding(
      padding: EdgeInsets.only(top: 4.0 * zoom / 100, bottom: 2.0 * zoom / 100),
      child: LiturgyRow(
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBullet)
              Container(
                width: 8.0 * zoom / 100,
                height: 8.0 * zoom / 100,
                color: secondary,
                margin: const EdgeInsets.only(right: 8.0),
              ),
            Expanded(
              child: YamlTextWidget(
                paragraphs: YamlTextParser.parseText(title),
                textStyle: TextStyle(
                  fontSize: 16.0 * zoom / 100,
                  fontWeight: FontWeight.bold,
                  color: contentColor,
                ),
                paragraphSpacing: 0,
                redColor: secondary,
              ),
            ),
            if (trailingWidget != null) trailingWidget,
          ],
        ),
      ),
    );
  }
}

class LiturgyPartTitle extends StatelessWidget {
  final String? content;
  final Widget Function(double zoom)? trailing;
  final bool hideVerseIdPlaceholder;

  const LiturgyPartTitle(this.content,
      {super.key, this.trailing, this.hideVerseIdPlaceholder = true});

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    final sectionColor = Theme.of(context).colorScheme.secondary;

    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) => Padding(
        padding: EdgeInsets.only(top: 10 * currentZoom.value / 100),
        child: LiturgyRow(
          hideVerseIdPlaceholder: hideVerseIdPlaceholder,
          builder: (context, zoom) {
            final titleWidget = YamlTextWidget(
              paragraphs: YamlTextParser.parseText(content!),
              textStyle: TextStyle(
                fontSize: 20 * (zoom ?? 100) / 100,
                fontWeight: FontWeight.bold,
                color: sectionColor,
                fontFeatures: const [FontFeature('smcp')],
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
