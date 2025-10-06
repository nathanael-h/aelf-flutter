import 'package:aelf_flutter/widgets/liturgy_part_antiphon.dart';
import 'package:flutter/material.dart';

class AntiphonWidget extends StatelessWidget {
  final String antiphon1;
  final String? antiphon2; // null possible if only one antiphon
  final String? antiphon3; // null possible if no third antiphon

  const AntiphonWidget({
    Key? key,
    required this.antiphon1,
    this.antiphon2,
    this.antiphon3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasAntiphon2 = (antiphon2 ?? "").isNotEmpty;
    final bool hasAntiphon3 = (antiphon3 ?? "").isNotEmpty;
    final bool hasMultipleAntiphons = hasAntiphon2 || hasAntiphon3;
    final String antiphon1Label = hasMultipleAntiphons
        ? '<span class="red-text">Ant. 1 : </span>'
        : '<span class="red-text">Ant. : </span>';
    final String antiphon2Label = '<span class="red-text">Ant. 2 : </span>';
    final String antiphon3Label = '<span class="red-text">Ant. 2 : </span>';

    return Column(
      children: [
        LiturgyPartAntiphon(antiphon1Label + antiphon1),
        if (hasAntiphon2) // Show second antiphon only if it exists
          LiturgyPartAntiphon(antiphon2Label + antiphon2!),
        if (hasAntiphon3) // Show third antiphon only if it exists
          LiturgyPartAntiphon(antiphon3Label + antiphon3!),
      ],
    );
  }
}
