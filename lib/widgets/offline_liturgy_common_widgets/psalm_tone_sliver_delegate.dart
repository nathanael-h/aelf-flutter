import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_widget.dart';

// Must stay in sync with _svgScale in psalm_tone_widget.dart
const double _stickyScale = 1.2;

/// Computes the pixel height a [PsalmToneWidget] will occupy for [svgData]
/// at the given [screenWidth], matching the rendering logic in [PsalmToneWidget].
double psalmToneSliverExtent(List<String> svgData, double screenWidth) {
  if (svgData.isEmpty) return 0;
  const verticalPadding = 24.0; // 12px top + 12px bottom

  if (svgData.length > 1) {
    // PageView (160) + gap (8) + dot indicator (10) + padding
    return 202 + verticalPadding;
  }

  final svg = svgData.first;
  final maxWidth = screenWidth - 20;
  final wMatch = RegExp(r'<svg[^>]*\swidth="([0-9.]+)"').firstMatch(svg);
  final hMatch = RegExp(r'<svg[^>]*\sheight="([0-9.]+)"').firstMatch(svg);
  final naturalWidth = wMatch != null ? double.tryParse(wMatch.group(1)!) : null;
  final naturalHeight = hMatch != null ? double.tryParse(hMatch.group(1)!) : null;

  if (naturalWidth == null || naturalHeight == null || naturalWidth == 0) {
    return 100 + verticalPadding;
  }

  final targetWidth = (naturalWidth * _stickyScale).clamp(0.0, maxWidth);
  return targetWidth * (naturalHeight / naturalWidth) + verticalPadding;
}

/// Pins a psalm tone SVG score just below the TabBar while the user scrolls
/// through the psalm. The next psalm's header will progressively push it off.
class PsalmToneSliverDelegate extends SliverPersistentHeaderDelegate {
  PsalmToneSliverDelegate({
    required this.svgData,
    required this.extent,
    required this.themeKey,
  });

  final List<String> svgData;
  final double extent;
  final String themeKey;
  bool _wasPinned = false;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (overlapsContent && !_wasPinned) {
      HapticFeedback.lightImpact();
    }
    _wasPinned = overlapsContent;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: PsalmToneWidget(svgData: svgData),
    );
  }

  @override
  bool shouldRebuild(PsalmToneSliverDelegate oldDelegate) =>
      svgData != oldDelegate.svgData ||
      extent != oldDelegate.extent ||
      themeKey != oldDelegate.themeKey;
}
