import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_formatted_text.dart';

class AntiphonWidget extends StatelessWidget {
  final String antiphon1;
  final String? antiphon2;
  final String? antiphon3;
  final String? label1;
  final String? label2;
  final String? label3;

  const AntiphonWidget({
    super.key,
    required this.antiphon1,
    this.antiphon2,
    this.antiphon3,
    this.label1,
    this.label2,
    this.label3,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.secondary;
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value ?? 100.0;
        final hasMultiple =
            (antiphon2 ?? "").isNotEmpty || (antiphon3 ?? "").isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAntiphon(antiphon1,
                label: label1 ?? (hasMultiple ? 'Ant. 1' : 'Ant.'),
                zoom: zoom,
                labelColor: labelColor),
            if ((antiphon2 ?? "").isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _buildAntiphon(antiphon2!,
                    label: label2 ?? 'Ant. 2',
                    zoom: zoom,
                    labelColor: labelColor),
              ),
            if ((antiphon3 ?? "").isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _buildAntiphon(antiphon3!,
                    label: label3 ?? 'Ant. 3',
                    zoom: zoom,
                    labelColor: labelColor),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAntiphon(String antiphon,
      {required String label,
      required double zoom,
      required Color labelColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 45.0),
          margin: const EdgeInsets.only(right: 8.0),
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 13.0 * zoom / 100,
              height: 1.4,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          child: LiturgyPartFormattedText(
            antiphon,
            textStyle: TextStyle(
              fontSize: 13.0 * zoom / 100,
              height: 1.4,
            ),
            includeVerseIdPlaceholder: false,
            paragraphSpacing: 8.0,
          ),
        ),
      ],
    );
  }
}
