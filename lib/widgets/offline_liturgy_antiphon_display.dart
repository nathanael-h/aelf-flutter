import 'package:flutter/material.dart';
import '../app_screens/layout_config.dart';

class AntiphonWidget extends StatelessWidget {
  final String antiphon1;
  final String? antiphon2; // null possible if only one antiphon

  const AntiphonWidget({
    Key? key,
    required this.antiphon1,
    this.antiphon2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasTwoAntiphons = (antiphon2 ?? "").isNotEmpty;

    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text:
                    hasTwoAntiphons ? 'Ant. 1 : ' : 'Ant. : ', // Dynamic label
                style: psalmAntiphonTitleStyle,
              ),
              TextSpan(
                text: antiphon1,
                style: psalmAntiphonStyle,
              ),
            ],
          ),
        ),
        if (hasTwoAntiphons) // Show second antiphon only if it exists
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
      ],
    );
  }
}
