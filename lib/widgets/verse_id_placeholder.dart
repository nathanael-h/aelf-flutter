import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// This widget is used when no verse ID is expected, to shift the following
/// widget(s) and to have it aligned with the content of verses.
///
/// If [zoom] is provided, it will be used directly (avoiding nested Consumer).
/// If [zoom] is null, it will use Consumer<CurrentZoom> to get the value.
class verseIdPlaceholder extends StatelessWidget {
  final double? zoom;

  const verseIdPlaceholder({Key? key, this.zoom}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If zoom is provided, use it directly (no Consumer needed)
    if (zoom != null) {
      return _buildPlaceholder(zoom!);
    }

    // Otherwise, use Consumer (for backward compatibility)
    return Consumer<CurrentZoom>(builder: (context, currentZoom, child) {
      final zoomValue = currentZoom.value;
      return _buildPlaceholder(zoomValue);
    });
  }

  Widget _buildPlaceholder(double zoomValue) {
    return Container(width: liturgyRowIndentWidth(zoomValue));
  }
}
