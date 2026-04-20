import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';

/// Displays the standard office header: title, liturgical color bar, rank
/// label, and optional description box. All text sizes scale with [CurrentZoom].
class OfficeHeaderDisplay extends StatelessWidget {
  const OfficeHeaderDisplay({
    super.key,
    this.officeDescription,
    this.liturgicalColor,
    this.precedence,
    this.celebrationDescription,
    this.additionalInfo,
  });

  final String? officeDescription;
  final String? liturgicalColor;
  final int? precedence;
  final String? celebrationDescription;
  final String? additionalInfo;

  @override
  Widget build(BuildContext context) {
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final subtleColor = Theme.of(context).textTheme.bodySmall?.color;
    final borderColor = Theme.of(context).dividerColor;

    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            YamlTextWidget(
              paragraphs: YamlTextParser.parseText(officeDescription ?? ''),
              textStyle: TextStyle(
                fontSize: 18 * zoom / 100,
                fontWeight: FontWeight.bold,
                color: bodyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (liturgicalColor != null && liturgicalColor!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 6,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: getLiturgicalColor(liturgicalColor),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            if (additionalInfo != null)
              Padding(
                padding: EdgeInsets.only(
                  bottom: 8,
                  right: MediaQuery.of(context).size.width * 0.05,
                ),
                child: Text(
                  additionalInfo!,
                  style: TextStyle(
                    fontSize: 12 * zoom / 100,
                    fontStyle: FontStyle.italic,
                    color: subtleColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              )
            else
              const SizedBox(height: 8),
            if (precedence != null)
              Text(
                getCelebrationTypeLabel(precedence!),
                style: TextStyle(
                  fontSize: 14 * zoom / 100,
                  fontStyle: FontStyle.italic,
                  color: subtleColor,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            if (celebrationDescription != null &&
                celebrationDescription!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: YamlTextWidget(
                  paragraphs: YamlTextParser.parseText(celebrationDescription!),
                  textStyle: TextStyle(
                    fontSize: 14 * zoom / 100,
                    height: 1.4,
                    color: bodyColor,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        );
      },
    );
  }
}
