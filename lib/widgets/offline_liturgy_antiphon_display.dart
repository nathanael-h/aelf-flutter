import 'package:flutter/material.dart';
import '../app_screens/layout_config.dart';

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

    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: hasMultipleAntiphons
                    ? 'Ant. 1 : '
                    : 'Ant. : ', // Dynamic label
                style: psalmAntiphonTitleStyle,
              ),
              TextSpan(
                text: antiphon1,
                style: psalmAntiphonStyle,
              ),
            ],
          ),
        ),
        if (hasAntiphon2) // Show second antiphon only if it exists
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Ant. 2 : ',
                  style: psalmAntiphonTitleStyle,
                ),
                TextSpan(
                  text: antiphon2!,
                  style: psalmAntiphonStyle,
                ),
              ],
            ),
          ),
        if (hasAntiphon3) // Show third antiphon only if it exists
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Ant. 3 : ',
                  style: psalmAntiphonTitleStyle,
                ),
                TextSpan(
                  text: antiphon3!,
                  style: psalmAntiphonStyle,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
