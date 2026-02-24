import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// Wraps [child] with a [GestureDetector] that maps pinch gestures to
/// [CurrentZoom] updates, following the same pattern used in LiturgyTabsView.
class PinchZoomArea extends StatefulWidget {
  final Widget child;

  const PinchZoomArea({super.key, required this.child});

  @override
  State<PinchZoomArea> createState() => _PinchZoomAreaState();
}

class _PinchZoomAreaState extends State<PinchZoomArea> {
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
      child: widget.child,
    );
  }
}
