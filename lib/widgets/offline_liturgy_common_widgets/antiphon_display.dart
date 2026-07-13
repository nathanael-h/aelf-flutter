import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_marker_icon.dart';

class AntiphonWidget extends StatelessWidget {
  final String antiphon1;
  final String? antiphon2;
  final String? antiphon3;
  final AntiphonMarker? marker1;
  final AntiphonMarker? marker2;
  final AntiphonMarker? marker3;

  const AntiphonWidget({
    super.key,
    required this.antiphon1,
    this.antiphon2,
    this.antiphon3,
    this.marker1,
    this.marker2,
    this.marker3,
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
        ),
        if ((antiphon2 ?? "").isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 3.0 * zoom / 100),
            child: _buildAntiphon(
              antiphon2!,
              marker: marker2 ?? AntiphonMarker.second,
              labelColor: labelColor,
            ),
          ),
        if ((antiphon3 ?? "").isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 3.0 * zoom / 100),
            child: _buildAntiphon(
              antiphon3!,
              marker: marker3 ?? AntiphonMarker.third,
              labelColor: labelColor,
            ),
          ),
      ],
    );
  }

  Widget _buildAntiphon(
    String antiphon, {
    required AntiphonMarker marker,
    required Color labelColor,
  }) {
    return LiturgyRow(
      left: LiturgyRowLeft.widget(AntiphonMarkerIcon(marker: marker)),
      builder: (context, zoom) => YamlTextWidget(
        paragraphs: YamlTextParser.parseText(antiphon),
        textStyle: TextStyle(
          fontSize: 13.0 * (zoom ?? 100) / 100,
          height: 1.2,
        ),
        paragraphSpacing: 4.0 * (zoom ?? 100) / 100,
        redColor: labelColor,
      ),
    );
  }
}
