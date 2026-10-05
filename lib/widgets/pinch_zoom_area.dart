import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
/// When the new font size is applied, the scroll offset is corrected during
/// that same layout so the content under the fingers stays under the
/// fingers, instead of drifting as the text above it changes size. The
/// correction is anchored on the render box that was under the fingers, so
/// content that does not follow the zoom (psalm tone scores, fixed paddings)
/// is accounted for. Two modes are available:
/// - The default constructor is for content that builds its own vertical
///   scroll views (e.g. a `TabBarView` of independent tabs, or a `PageView`
///   of Bible chapters). The anchored controller is handed to them through
///   a [PrimaryScrollController], which vertical scroll views without an
///   explicit controller pick up on mobile platforms; the one under the
///   fingers is corrected.
/// - [PinchZoomSelectionArea.scrollAnchored] hands the controller to
///   [builder] instead, and also wraps the content in a themed,
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
  final _AnchoredScrollController _scrollController =
      _AnchoredScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
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
    // The layout is still the pre-pinch one: remember what lies under the
    // fingers before the preview transform kicks in.
    final listenerBox = context.findRenderObject() as RenderBox?;
    if (listenerBox != null) {
      _scrollController.captureAnchor(listenerBox.localToGlobal(_focalPoint));
    }
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
    _scrollController.anchorOnNextLayout(newZoom / zoomBefore);
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
        ? PrimaryScrollController(
            controller: _scrollController,
            child: _preview(widget.child!),
          )
        : RawScrollbar(
            controller: _scrollController,
            thumbColor: Theme.of(context).colorScheme.secondary,
            thickness: 4,
            radius: const Radius.circular(4),
            interactive: false,
            child: _preview(widget.builder!(context, _scrollController)),
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

/// What lay under the fingers when a pinch started, in the viewport's
/// coordinates: the deepest render box at [focalY] (if any) and where the
/// focal point sat inside it. For a paragraph that is the character under
/// the fingers ([textPosition]) plus the gap between its caret and the focal
/// point; for any other box (e.g. a psalm tone score, whose size does not
/// follow the zoom) it is the plain offset from the box top ([dy]).
typedef _ContentAnchor = ({
  ScrollContext scrollable,
  RenderBox viewport,
  double focalY,
  RenderBox? box,
  TextPosition? textPosition,
  double dy,
});

/// A [ScrollController] that can restore the content under a focal point
/// during the next layout, i.e. in the very frame where the content changes
/// size, instead of one frame later with a post-frame `jumpTo`.
///
/// Measuring the anchor box during layout must not read [RenderBox.size] of
/// a box that is not being laid out (it asserts in debug mode), hence the
/// caret offset for paragraphs and the unchanged offset for other boxes.
class _AnchoredScrollController extends ScrollController {
  _ContentAnchor? _captured;
  ({_ContentAnchor anchor, double ratio})? _pending;

  /// Records the content currently under [globalFocal]; call it while the
  /// layout is still the one the anchor must be restored from.
  ///
  /// Several scroll views may be attached (e.g. the tabs a `TabBarView`
  /// keeps alive next to the visible one): the one whose viewport contains
  /// the focal point is anchored.
  void captureAnchor(Offset globalFocal) {
    _captured = null;
    ScrollContext? scrollable;
    RenderBox? viewport;
    for (final position in positions) {
      final candidate = _viewportOf(position);
      if (candidate != null && _contains(candidate, globalFocal)) {
        scrollable = position.context;
        viewport = candidate;
        break;
      }
    }
    if (scrollable == null || viewport == null) return;
    final focalY = viewport.globalToLocal(globalFocal).dy;
    final box = _deepestBoxAt(viewport, focalY);
    TextPosition? textPosition;
    double dy = 0;
    if (box != null) {
      final local = box.globalToLocal(globalFocal);
      dy = local.dy;
      if (box is RenderParagraph) {
        textPosition = box.getPositionForOffset(local);
        dy -= box.getOffsetForCaret(textPosition, Rect.zero).dy;
      }
    }
    _captured = (
      scrollable: scrollable,
      viewport: viewport,
      focalY: focalY,
      box: box,
      textPosition: textPosition,
      dy: dy,
    );
  }

  /// Puts the captured content back under the focal point once the content
  /// has been laid out again at a zoom [ratio] times the previous one.
  void anchorOnNextLayout(double ratio) {
    final anchor = _captured;
    _captured = null;
    if (anchor == null) return;
    _pending = (anchor: anchor, ratio: ratio);
    // Drop the anchor if no layout consumed it (e.g. nothing was attached),
    // so it cannot fire on an unrelated later layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pending = null);
  }

  /// The scroll offset that puts the anchored content back under the focal
  /// point, given the layout [position] just computed; null when [position]
  /// is not the anchored scroll view.
  double? _takeTarget(ScrollPosition position) {
    final pending = _pending;
    if (pending == null) return null;
    final (:anchor, :ratio) = pending;
    // The position itself may have been replaced (e.g. when the scroll
    // lock swaps physics), but its Scrollable stays the same.
    if (!identical(position.context, anchor.scrollable)) return null;
    _pending = null;
    final pixels = position.pixels;
    final box = anchor.box;
    if (box != null &&
        box.hasSize &&
        anchor.viewport.attached &&
        _isDescendant(box, anchor.viewport)) {
      var inBox = anchor.dy;
      final textPosition = anchor.textPosition;
      if (box is RenderParagraph && textPosition != null) {
        inBox += box.getOffsetForCaret(textPosition, Rect.zero).dy;
      }
      return pixels + _topIn(box, anchor.viewport) + inBox - anchor.focalY;
    }
    // Fallback when the box is gone: assume everything above the focal
    // point scaled uniformly.
    return (pixels + anchor.focalY) * ratio - anchor.focalY;
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

/// First viewport below the Scrollable's own render object.
RenderBox? _viewportOf(ScrollPosition position) {
  final root = position.context.notificationContext?.findRenderObject();
  if (root == null) return null;
  final queue = <RenderObject>[root];
  while (queue.isNotEmpty) {
    final node = queue.removeAt(0);
    if (node is RenderAbstractViewport && node is RenderBox) {
      return node as RenderBox;
    }
    node.visitChildren(queue.add);
  }
  return null;
}

bool _contains(RenderBox box, Offset globalPoint) =>
    box.attached &&
    box.hasSize &&
    (Offset.zero & box.size).contains(box.globalToLocal(globalPoint));

/// Top of [box] in [viewport]'s coordinates, like [RenderObject.getTransformTo]
/// but treating [RenderTransform]s as identity: their transform is computed
/// from sizes, which cannot be read during layout, and the ones found in
/// scroll content (e.g. Android's stretching overscroll indicator) are
/// identity while scrolling is locked for the pinch.
double _topIn(RenderBox box, RenderBox viewport) {
  final chain = <RenderObject>[];
  for (RenderObject node = box;
      !identical(node, viewport);
      node = node.parent!) {
    chain.add(node);
  }
  final transform = Matrix4.identity();
  RenderObject parent = viewport;
  for (final child in chain.reversed) {
    if (parent is! RenderTransform) {
      parent.applyPaintTransform(child, transform);
    }
    parent = child;
  }
  return MatrixUtils.transformPoint(transform, Offset.zero).dy;
}

bool _isDescendant(RenderObject node, RenderObject ancestor) {
  for (RenderObject? n = node; n != null; n = n.parent) {
    if (identical(n, ancestor)) return true;
  }
  return false;
}

/// Boxes the anchor search does not look into: paragraphs are anchored on
/// a character instead, and boxes that scale or move their child compute
/// that transform from sizes, which cannot be read during layout
/// ([RenderTransform] is handled by [_topIn]).
bool _isAnchorLeaf(RenderBox box) =>
    box is RenderParagraph ||
    box is RenderFittedBox ||
    box is RenderRotatedBox ||
    box is RenderFractionalTranslation;

/// Deepest render box below [viewport] spanning [y] (viewport coordinates),
/// taking the first matching child at each level. Pinned/floating headers
/// are skipped: they do not move with the content.
RenderBox? _deepestBoxAt(RenderBox viewport, double y) {
  RenderBox? found;
  void descend(RenderObject node) {
    RenderObject? match;
    node.visitChildren((child) {
      if (match != null || child is RenderSliverPersistentHeader) return;
      if (child is RenderBox) {
        if (!child.hasSize || child.size.height <= 0) return;
        final top = _topIn(child, viewport);
        if (y >= top && y < top + child.size.height) match = child;
      } else if (child is RenderSliver) {
        // Slivers are only containers here; look for a box inside.
        final before = found;
        descend(child);
        if (!identical(found, before)) match = child;
      }
    });
    if (match is RenderBox) {
      final box = match as RenderBox;
      found = box;
      if (!_isAnchorLeaf(box)) descend(box);
    }
  }

  descend(viewport);
  return found;
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
    final target = hasPixels ? controller._takeTarget(this) : null;
    if (target == null) {
      return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
    }
    // The upper bound is left to the physics: lazy slivers only estimate it
    // here.
    correctPixels(math.max(minScrollExtent, target));
    super.applyContentDimensions(minScrollExtent, maxScrollExtent);
    // Ask the viewport for another layout pass at the corrected offset.
    return false;
  }
}
