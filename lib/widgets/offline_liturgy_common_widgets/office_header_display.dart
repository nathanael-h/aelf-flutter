import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';

/// The bar of the liturgical color under an office's title (see
/// OfficeHeaderDisplay). In scroll mode it also closes the Office part
/// (celebration and Common selectors), right above that title, so the
/// office itself stands apart from the choices made before it.
class LiturgicalColorBar extends StatelessWidget {
  const LiturgicalColorBar({super.key, required this.color});

  final String color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 6,
      decoration: BoxDecoration(
        color: getLiturgicalColor(color),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// Displays the standard office header: title, liturgical color bar, rank
/// label, and optional description box. All text sizes scale with [CurrentZoom].
class OfficeHeaderDisplay extends StatelessWidget {
  const OfficeHeaderDisplay({
    super.key,
    this.officeDescription,
    this.liturgicalColor,
    this.typeLabel,
    this.celebrationDescription,
    this.additionalInfo,
  });

  final String? officeDescription;
  final String? liturgicalColor;
  final String? typeLabel;
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
            SizedBox(height: 12 * zoom / 100),
            LiturgyRow(
              left: LiturgyRowLeft.indent,
              builder: (context, _) => YamlTextWidget(
                paragraphs: YamlTextParser.parseText(officeDescription ?? ''),
                textStyle: TextStyle(
                  fontSize: 20 * zoom / 100,
                  fontWeight: FontWeight.bold,
                  color: bodyColor,
                  fontFeatures: const [FontFeature('smcp')],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 12 * zoom / 100),
            if (liturgicalColor != null && liturgicalColor!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 4 * zoom / 100),
                child: LiturgicalColorBar(color: liturgicalColor!),
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
              SizedBox(height: 8 * zoom / 100),
            if (typeLabel != null && typeLabel!.isNotEmpty)
              Text(
                typeLabel!,
                style: TextStyle(
                  fontSize: 14 * zoom / 100,
                  fontStyle: FontStyle.italic,
                  color: subtleColor,
                ),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 8 * zoom / 100),
            if (celebrationDescription != null &&
                celebrationDescription!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12 * zoom / 100),
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
              SizedBox(height: 4 * zoom / 100),
            ],
          ],
        );
      },
    );
  }
}
