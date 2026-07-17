import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_marker_icon.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';

class AntiphonWidget extends StatelessWidget {
  final String antiphon1;
  final String? antiphon2;
  final String? antiphon3;
  final AntiphonMarker? marker1;
  final AntiphonMarker? marker2;
  final AntiphonMarker? marker3;
  final String? reference1;
  final String? reference2;
  final String? reference3;

  const AntiphonWidget({
    super.key,
    required this.antiphon1,
    this.antiphon2,
    this.antiphon3,
    this.marker1,
    this.marker2,
    this.marker3,
    this.reference1,
    this.reference2,
    this.reference3,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.secondary;
    final zoom = context.watch<CurrentZoom>().value;
    final hasMultiple =
        (antiphon2 ?? "").isNotEmpty || (antiphon3 ?? "").isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAntiphon(
          antiphon1,
          marker: marker1 ??
              (hasMultiple ? AntiphonMarker.first : AntiphonMarker.single),
          labelColor: labelColor,
          reference: reference1,
        ),
        if ((antiphon2 ?? "").isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 3.0 * zoom / 100),
            child: _buildAntiphon(
              antiphon2!,
              marker: marker2 ?? AntiphonMarker.second,
              labelColor: labelColor,
              reference: reference2,
            ),
          ),
        if ((antiphon3 ?? "").isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 3.0 * zoom / 100),
            child: _buildAntiphon(
              antiphon3!,
              marker: marker3 ?? AntiphonMarker.third,
              labelColor: labelColor,
              reference: reference3,
            ),
          ),
      ],
    );
  }

  Widget _buildAntiphon(
    String antiphon, {
    required AntiphonMarker marker,
    required Color labelColor,
    String? reference,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((reference ?? "").isNotEmpty)
          LiturgyRow(
            left: LiturgyRowLeft.widget(const SizedBox.shrink()),
            builder: (context, zoom) => Align(
              alignment: Alignment.centerRight,
              child: BiblicalReferenceButton(
                reference: reference!,
                zoom: zoom ?? 100,
              ),
            ),
          ),
        LiturgyRow(
          left: LiturgyRowLeft.widget(
            AntiphonMarkerIcon(marker: marker),
            alignment: Alignment.topCenter,
          ),
          builder: (context, zoom) => YamlTextWidget(
            paragraphs: YamlTextParser.parseText(antiphon),
            textStyle: TextStyle(
              fontSize: 13.0 * (zoom ?? 100) / 100,
              height: 1.2,
            ),
            paragraphSpacing: 4.0 * (zoom ?? 100) / 100,
            redColor: labelColor,
            rightIndentMultiplier: 0.75,
          ),
        ),
      ],
    );
  }
}
