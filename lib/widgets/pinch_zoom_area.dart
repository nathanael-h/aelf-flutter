import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// Wraps its content with a [GestureDetector] that maps pinch gestures to
/// [CurrentZoom] updates, following the same pattern used in LiturgyTabsView.
///
/// Two modes are available:
/// - The default constructor just relays the gesture to [CurrentZoom], for
///   content that manages its own scrolling (e.g. a `TabBarView` made of
///   several independent tabs).
/// - [PinchZoomSelectionArea.scrollAnchored] additionally owns a
///   [ScrollController] (handed to [builder]) and corrects its offset on
///   every pinch frame so the content under the fingers stays under the
///   fingers, instead of drifting as the text above it changes size. It also
///   wraps the content in a themed, non-interactive [RawScrollbar] so the
///   reader can see where they are in the text.
class PinchZoomSelectionArea extends StatefulWidget {
  final Widget? child;
  final Widget Function(
      BuildContext context, ScrollController scrollController)? builder;

  const PinchZoomSelectionArea({super.key, required Widget this.child})
      : builder = null;

  const PinchZoomSelectionArea.scrollAnchored(
      {super.key, required this.builder})
      : child = null;

  @override
  State<PinchZoomSelectionArea> createState() => _PinchZoomSelectionAreaState();
}

class _PinchZoomSelectionAreaState extends State<PinchZoomSelectionArea> {
  double? _zoomBeforePinch;
  double? _lastZoom;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (widget.builder != null) {
      _scrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  /// Keeps the content point that was under [focalY] (in this widget's own
  /// coordinate space) at the same screen position after a zoom change from
  /// [_lastZoom] to [newZoom]. Since every dimension in the office views is
  /// scaled by the same `zoom / 100` factor, the content height above any
  /// point scales by exactly `newZoom / _lastZoom`, so the new offset is a
  /// straightforward rescale around the focal point.
  void _correctScroll(double newZoom, double focalY) {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients || _lastZoom == null) {
      return;
    }
    final position = controller.position;
    final ratio = newZoom / _lastZoom!;
    final newOffset = (position.pixels + focalY) * ratio - focalY;
    controller.jumpTo(newOffset.clamp(0.0, position.maxScrollExtent));
    _lastZoom = newZoom;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (ScaleStartDetails details) {
        _zoomBeforePinch = context.read<CurrentZoom>().value;
        _lastZoom = _zoomBeforePinch;
        dev.log('PinchZoom: onScaleStart, zoom: $_zoomBeforePinch');
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        if (_zoomBeforePinch == null) return;
        if (details.scale == 1.0) return;
        context
            .read<CurrentZoom>()
            .updateZoom(_zoomBeforePinch! * details.scale);
        final clampedZoom = context.read<CurrentZoom>().value;
        dev.log('PinchZoom: scale=${details.scale}, newZoom=$clampedZoom');
        if (_scrollController != null) {
          final focalY = details.localFocalPoint.dy;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _correctScroll(clampedZoom, focalY);
          });
        }
      },
      onScaleEnd: (ScaleEndDetails details) {
        dev.log('PinchZoom: onScaleEnd');
        _zoomBeforePinch = null;
        _lastZoom = null;
      },
      child: SelectionArea(
        child: widget.child ??
            RawScrollbar(
              controller: _scrollController,
              thumbColor: Theme.of(context).colorScheme.secondary,
              thickness: 4,
              radius: const Radius.circular(4),
              interactive: false,
              child: widget.builder!(context, _scrollController!),
            ),
      ),
    );
  }
}
