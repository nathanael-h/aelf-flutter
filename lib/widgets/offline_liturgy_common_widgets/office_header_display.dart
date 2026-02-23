import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/liturgical_colors.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';

/// Displays the standard office header: title, liturgical color bar, rank
/// label, and optional description box. All text sizes scale with [CurrentZoom].
class OfficeHeaderDisplay extends StatelessWidget {
  const OfficeHeaderDisplay({
    super.key,
    this.officeDescription,
    this.liturgicalColor,
    this.precedence,
    this.celebrationDescription,
  });

  final String? officeDescription;
  final String? liturgicalColor;
  final int? precedence;
  final String? celebrationDescription;

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value ?? 100.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              officeDescription ?? '',
              style: TextStyle(
                fontSize: 18 * zoom / 100,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (liturgicalColor != null && liturgicalColor!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 6,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: getLiturgicalColor(liturgicalColor),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            Text(
              getCelebrationTypeLabel(precedence ?? 13),
              style: TextStyle(
                fontSize: 14 * zoom / 100,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
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
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  celebrationDescription!,
                  style: TextStyle(
                    fontSize: 14 * zoom / 100,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              SizedBox(height: spaceBetweenElements),
            ],
          ],
        );
      },
    );
  }
}
