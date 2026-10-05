import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';

/// Maps two-finger pinches on its content to [CurrentZoom] updates.
///
/// Pinches are detected with a raw [Listener] rather than a
/// [GestureDetector]: a scale recognizer has to win the gesture arena
/// against the scroll views, the [TabBarView] and the [SelectionArea] below
/// it, and it loses as soon as the first finger moves a few pixels before
/// the second one lands (which is the norm on Android, where the touch slop
/// is small). Instead, as soon as two fingers are down, scrolling is locked
/// for the whole subtree through [ScrollConfiguration], which also cancels
/// any drag the first finger may already have started.
///
/// While the fingers move, the content is only magnified visually with a
/// [Transform] around the initial focal point, which costs no layout. The
/// actual font size is applied once, when the pinch ends, rounded to
/// [_zoomStep].
///
/// Two modes are available:
/// - The default constructor just relays the gesture to [CurrentZoom], for
///   content that manages its own scrolling (e.g. a `TabBarView` made of
///   several independent tabs).
/// - [PinchZoomSelectionArea.scrollAnchored] additionally owns a
///   [ScrollController] (handed to [builder]) and, when the new font size is
///   applied, corrects its offset during that same layout so the content
///   under the fingers stays under the fingers, instead of drifting as the
///   text above it changes size. It also wraps the content in a themed,
///   non-interactive [RawScrollbar] so the reader can see where they are in
///   the text.
///
/// [selectable] wraps the content in a [SelectionArea]; turn it off when the
/// content already provides its own.
class PinchZoomSelectionArea extends StatefulWidget {
  final Widget? child;
  final Widget Function(
      BuildContext context, ScrollController scrollController)? builder;

  final bool selectable;

  const PinchZoomSelectionArea(
      {super.key, required Widget this.child, this.selectable = true})
      : builder = null;

  const PinchZoomSelectionArea.scrollAnchored(
      {super.key, required this.builder, this.selectable = true})
      : child = null;

  @override
  State<PinchZoomSelectionArea> createState() => _PinchZoomSelectionAreaState();
}

/// Zoom levels reached by pinching are rounded to this step (in %), so the
/// text settles on stable values.
const double _zoomStep = 5;

/// Pinches whose scale stays this close to 1 (e.g. a two-finger tap) leave
/// the zoom untouched.
const double _minScaleChange = 0.02;

class _PinchZoomSelectionAreaState extends State<PinchZoomSelectionArea> {
  /// Local positions of the pointers currently down on the content.
  final Map<int, Offset> _pointers = {};

  /// Distance between the two pinching fingers when the pinch started.
  double? _initialSpan;
  double? _zoomBeforePinch;

  /// Point the visual preview is scaled around, fixed at the pinch start.
  Offset _focalPoint = Offset.zero;

  /// Visual scale applied to the content while pinching (1 otherwise).
  final ValueNotifier<double> _previewScale = ValueNotifier(1.0);

  /// True from the moment a second finger lands until every finger is
  /// lifted, so that a finger left on screen after a pinch does not start
  /// scrolling.
  bool _scrollLocked = false;
  _AnchoredScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (widget.builder != null) {
      _scrollController = _AnchoredScrollController();
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _previewScale.dispose();
    super.dispose();
  }

  bool get _isPinching => _initialSpan != null;

  List<Offset> get _pinchPositions => _pointers.values.take(2).toList();

  double get _span {
    final positions = _pinchPositions;
    return (positions[0] - positions[1]).distance;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length == 2 && !_isPinching) _startPinch();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;
    if (_isPinching) _updatePinch();
  }

  void _onPointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_isPinching && _pointers.length < 2) _endPinch();
    if (_pointers.isEmpty && _scrollLocked) {
      setState(() => _scrollLocked = false);
    }
  }

  void _startPinch() {
    final span = _span;
    // Two fingers landing on the same spot give no usable reference.
    if (span < 1) return;
    final positions = _pinchPositions;
    _initialSpan = span;
    _focalPoint = (positions[0] + positions[1]) / 2;
    _zoomBeforePinch = context.read<CurrentZoom>().value;
    setState(() => _scrollLocked = true);
    dev.log('PinchZoom: start, zoom: $_zoomBeforePinch');
  }

  void _updatePinch() {
    final zoomBefore = _zoomBeforePinch!;
    _previewScale.value = (_span / _initialSpan!).clamp(
        CurrentZoom.minZoom / zoomBefore, CurrentZoom.maxZoom / zoomBefore);
  }

  void _endPinch() {
    final zoomBefore = _zoomBeforePinch!;
    final scale = _previewScale.value;
    _initialSpan = null;
    _zoomBeforePinch = null;
    _previewScale.value = 1.0;
    if ((scale - 1).abs() < _minScaleChange) return;

    final newZoom = ((zoomBefore * scale / _zoomStep).round() * _zoomStep)
        .clamp(CurrentZoom.minZoom, CurrentZoom.maxZoom);
    dev.log('PinchZoom: end, zoom: $zoomBefore -> $newZoom');
    if (newZoom == zoomBefore) return;
    _scrollController?.anchorOnNextLayout(
        ratio: newZoom / zoomBefore, focalY: _focalPoint.dy);
    context.read<CurrentZoom>().updateZoom(newZoom);
  }

  /// Scales [child] by [_previewScale] around [_focalPoint], without
  /// rebuilding it on every pinch frame.
  Widget _preview(Widget child) {
    return ClipRect(
      child: ValueListenableBuilder<double>(
        valueListenable: _previewScale,
        child: RepaintBoundary(child: child),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          origin: _focalPoint,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = widget.child != null
        ? _preview(widget.child!)
        : RawScrollbar(
            controller: _scrollController,
            thumbColor: Theme.of(context).colorScheme.secondary,
            thickness: 4,
            radius: const Radius.circular(4),
            interactive: false,
            child: _preview(widget.builder!(context, _scrollController!)),
          );
    final behavior = ScrollConfiguration.of(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: ScrollConfiguration(
        // Swapping in NeverScrollableScrollPhysics makes every Scrollable
        // below (explicit physics are applied on top of these) drop its drag
        // recognizers and cancel the drag in progress.
        behavior: _scrollLocked
            ? behavior.copyWith(physics: const NeverScrollableScrollPhysics())
            : behavior,
        child: widget.selectable ? SelectionArea(child: content) : content,
      ),
    );
  }
}

/// A [ScrollController] that can rescale its offset around a focal point
/// during the next layout, i.e. in the very frame where the content changes
/// size, instead of one frame later with a post-frame `jumpTo`.
class _AnchoredScrollController extends ScrollController {
  ({double ratio, double focalY})? _anchor;

  /// Keeps the content point currently at [focalY] (in viewport
  /// coordinates) at that position once the content has been laid out again
  /// with every dimension multiplied by [ratio].
  void anchorOnNextLayout({required double ratio, required double focalY}) {
    _anchor = (ratio: ratio, focalY: focalY);
    // Drop the anchor if no layout consumed it (e.g. nothing was attached),
    // so it cannot fire on an unrelated later layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _anchor = null);
  }

  ({double ratio, double focalY})? _takeAnchor() {
    final anchor = _anchor;
    _anchor = null;
    return anchor;
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition? oldPosition) {
    return _AnchoredScrollPosition(
      controller: this,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _AnchoredScrollPosition extends ScrollPositionWithSingleContext {
  final _AnchoredScrollController controller;

  _AnchoredScrollPosition({
    required this.controller,
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    final anchor = hasPixels ? controller._takeAnchor() : null;
    if (anchor == null) {
      return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
    }
    // Every dimension is scaled by the same `zoom / 100` factor, so the
    // content height above any point scales by exactly `ratio`. The upper
    // bound is left to the physics: lazy slivers only estimate it here.
    final target = math.max(minScrollExtent,
        (pixels + anchor.focalY) * anchor.ratio - anchor.focalY);
    correctPixels(target);
    super.applyContentDimensions(minScrollExtent, maxScrollExtent);
    // Ask the viewport for another layout pass at the corrected offset.
    return false;
  }
}
