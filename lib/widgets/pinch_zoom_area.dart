import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// Wraps [child] with a [GestureDetector] that maps pinch gestures to
/// [CurrentZoom] updates, following the same pattern used in LiturgyTabsView.
class PinchZoomSelectionArea extends StatefulWidget {
  final Widget child;

  const PinchZoomSelectionArea({super.key, required this.child});

  @override
  State<PinchZoomSelectionArea> createState() => _PinchZoomSelectionAreaState();
}

class _PinchZoomSelectionAreaState extends State<PinchZoomSelectionArea> {
  double? _zoomBeforePinch;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (ScaleStartDetails details) {
        _zoomBeforePinch = context.read<CurrentZoom>().value;
        dev.log('PinchZoom: onScaleStart, zoom: $_zoomBeforePinch');
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        if (_zoomBeforePinch == null) return;
        if (details.scale == 1.0) return;
        final newZoom = _zoomBeforePinch! * details.scale;
        context.read<CurrentZoom>().updateZoom(newZoom);
        dev.log('PinchZoom: scale=${details.scale}, newZoom=$newZoom');
      },
      onScaleEnd: (ScaleEndDetails details) {
        dev.log('PinchZoom: onScaleEnd');
        _zoomBeforePinch = null;
      },
      child: SelectionArea(child: widget.child),
    );
  }
}
