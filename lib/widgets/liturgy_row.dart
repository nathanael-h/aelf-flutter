import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/verse_id_placeholder.dart';

/// Reusable row used across liturgy parts to display the
/// verse id placeholder and the main content area.
///
/// The builder receives the current zoom value so callers
/// can build text/styles using that value.
class LiturgyRow extends StatelessWidget {
  final Widget Function(BuildContext context, double? zoom) builder;
  final EdgeInsets? padding;
  final bool hideVerseIdPlaceholder;

  const LiturgyRow(
      {required this.builder,
      this.padding,
      this.hideVerseIdPlaceholder = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentZoom>(
      builder: (context, currentZoom, child) => Row(children: [
        Expanded(
          child: Row(
            children: [
              if (!hideVerseIdPlaceholder) verseIdPlaceholder(),
              Expanded(
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: builder(context, currentZoom.value),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: 0, right: 15),
              )
            ],
          ),
        ),
      ]),
    );
  }
}
