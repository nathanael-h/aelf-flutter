import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Width below which long texts get no extra side margin.
const double _compactTextWidth = 600;

/// Largest extra side margin, reached on tablets.
const double _maxSideMargin = 32;

/// Extra side margin around long texts (Bible chapters, full-screen
/// offices) for a reading area of [width]: none on phones, growing once the
/// width exceeds [_compactTextWidth] and capped at [_maxSideMargin], so
/// tablets use their width instead of a narrow centred column.
///
/// Apply it inside the scroll view (as its padding) rather than around it,
/// so the scrollbar stays on the screen edge and the margins still scroll.
double readingSideMargin(double width) =>
    ((width - _compactTextWidth) / 2).clamp(0.0, _maxSideMargin);

/// [readingSideMargin] for the office scroll views: only in full-screen
/// mode, where the office spans the whole screen; 0 otherwise.
double officeSideMargin(BuildContext context) {
  final isFullScreen =
      context.select<LiturgyState, bool>((s) => s.isFullScreen);
  return isFullScreen ? readingSideMargin(MediaQuery.sizeOf(context).width) : 0;
}
