import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// A section title widget whose font size scales with [CurrentZoom].
/// Replaces the repeated `_buildSectionTitle` helper across office views.
class OfficeSectionTitle extends StatelessWidget {
  const OfficeSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) {
        final zoom = currentZoom.value ?? 100.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15 * zoom / 100,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
