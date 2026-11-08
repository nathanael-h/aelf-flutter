import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/score_midi.dart';
import 'package:aelf_flutter/utils/svg_preprocessor.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/utils/tone_player.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';

const double _svgScale = 1;

/// Icon size of the play / stop button next to a score: fixed, whatever the
/// size of the score and the text zoom, but never wider than the margin it
/// stands in.
const double _toneIconSize = 20;

/// Height of the page indicator under several scores: its spacing (8) plus
/// its largest dot (10).
const double _pageIndicatorHeight = 18;

/// The width a score is drawn at: its natural width times [_svgScale],
/// shrunk to [maxWidth] when wider.
double _svgTargetWidth(String svg, double maxWidth) {
  final widthMatch = RegExp(r'<svg[^>]*\swidth="([0-9.]+)"').firstMatch(svg);
  double? natural =
      widthMatch != null ? double.tryParse(widthMatch.group(1)!) : null;
  if (natural == null) {
    final vbMatch =
        RegExp(r'viewBox="[0-9.]+ [0-9.]+ ([0-9.]+)').firstMatch(svg);
    natural = vbMatch != null ? double.tryParse(vbMatch.group(1)!) : null;
  }
  if (natural == null) return maxWidth;
  return (natural * _svgScale).clamp(0, maxWidth);
}

/// Displays one or more psalm tone SVG scores below an antiphon.
///
/// A single SVG is shown directly. Multiple SVGs are presented in a
/// horizontal [PageView] with a dot-indicator for navigation.
///
/// A score that carries the MIDI of its psalmody gets a small play button in
/// the left margin, where R/ and V/ stand, vertically centred on the score (a
/// stop button while it plays), where [TonePlayer] can play it. Several
/// scores share one button, for the page shown: turning the page stops the
/// tone. The score itself does not react to taps, so that a tone is never
/// started by mistake.
class PsalmToneWidget extends StatefulWidget {
  const PsalmToneWidget({super.key, required this.svgData});

  final List<String> svgData;

  @override
  State<PsalmToneWidget> createState() => _PsalmToneWidgetState();
}

class _PsalmToneWidgetState extends State<PsalmToneWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<Uint8List?> _midis = _readMidis();

  List<Uint8List?> _readMidis() => widget.svgData.map(scoreMidi).toList();

  @override
  void didUpdateWidget(PsalmToneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.svgData, widget.svgData)) _midis = _readMidis();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _score(String svg, double maxWidth) => Align(
        alignment: Alignment.centerLeft,
        child: SvgPicture.string(
          svg,
          width: _svgTargetWidth(svg, maxWidth),
          fit: BoxFit.contain,
        ),
      );

  /// The left margin of a score: its play button when it carries a MIDI and
  /// tones can be played here, lifted by [bottomInset] to stay centred on
  /// the score.
  LiturgyRowLeft _margin(Uint8List? midi, {Key? key, double bottomInset = 0}) {
    if (midi == null || !context.read<TonePlayer>().isAvailable) {
      return LiturgyRowLeft.indent;
    }
    return LiturgyRowLeft.widget(Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ToneButton(key: key, midi: midi),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Measured here rather than inside LiturgyRow, whose IntrinsicHeight
    // cannot query a LayoutBuilder.
    return LayoutBuilder(
        builder: (context, constraints) =>
            _buildScores(context, constraints.maxWidth));
  }

  Widget _buildScores(BuildContext context, double availableWidth) {
    final zoom = context.watch<CurrentZoom>().value;
    final classicDisplay = context.watch<ThemeNotifier>().classicDisplay;
    final brightness = Theme.of(context).brightness;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final redHex =
        '#${secondaryColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color ??
        Theme.of(context).colorScheme.onSurface;
    final textColorCss = 'rgba('
        '${(bodyColor.r * 255.0).round().clamp(0, 255)}, '
        '${(bodyColor.g * 255.0).round().clamp(0, 255)}, '
        '${(bodyColor.b * 255.0).round().clamp(0, 255)}, '
        '${bodyColor.a.toStringAsFixed(3)})';

    final processedSvgs = widget.svgData
        .map((svg) => preprocessPsalmSvg(
              svg,
              textColor: textColorCss,
              serifFont: classicDisplay,
              redColor: redHex,
            ))
        .toList();

    if (processedSvgs.isEmpty) return const SizedBox.shrink();

    final dotColor =
        brightness == Brightness.dark ? Colors.white54 : Colors.black38;
    final dotActiveColor = secondaryColor;

    // The width LiturgyRow leaves to its content: minus the verse indent on
    // the left and its 15 px right padding. Sizing a score from the screen
    // width instead would let it be shrunk by the actual constraints while
    // LiturgyRow's IntrinsicHeight keeps its natural height, leaving a gap.
    final maxWidth = availableWidth - liturgyRowIndentWidth(zoom) - 15;

    if (processedSvgs.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: LiturgyRow(
          left: _margin(_midis[0]),
          builder: (context, _) => _score(processedSvgs[0], maxWidth),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: LiturgyRow(
        // Keyed by page: the button of the page left is disposed, which
        // stops its tone.
        left: _margin(_midis[_currentPage],
            key: ValueKey(_currentPage), bottomInset: _pageIndicatorHeight),
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                itemCount: processedSvgs.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _score(processedSvgs[index], maxWidth),
              ),
            ),
            const SizedBox(height: _pageIndicatorHeight - 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                processedSvgs.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 10 : 6,
                  height: _currentPage == index ? 10 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? dotActiveColor : dotColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Discreet play button next to a score: plays its [midi] through
/// [TonePlayer], and becomes a stop button while it plays.
///
/// It takes the width of the margin it stands in, so that its tap area is
/// wider than its icon.
class ToneButton extends StatefulWidget {
  const ToneButton({super.key, required this.midi});

  final Uint8List midi;

  @override
  State<ToneButton> createState() => _ToneButtonState();
}

class _ToneButtonState extends State<ToneButton> {
  late TonePlayer _player;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _player = context.read<TonePlayer>();
  }

  @override
  void dispose() {
    // A score that leaves the screen stops its tone. After the frame: stopping
    // notifies the other buttons, which cannot rebuild while the tree is
    // being finalized.
    final player = _player;
    final midi = widget.midi;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (player.isPlaying(midi)) player.stop();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = context.watch<TonePlayer>().isPlaying(widget.midi);
    final color = Theme.of(context).colorScheme.secondary;
    final iconSize = _toneIconSize.clamp(
        0.0, liturgyRowIndentWidth(context.watch<CurrentZoom>().value));
    return SizedBox(
      width: double.infinity,
      height: iconSize + 12,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: iconSize,
        color: playing ? color : color.withValues(alpha: 0.6),
        tooltip: playing ? 'Arrêter' : 'Écouter le ton',
        icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
        onPressed: () => _player.toggle(widget.midi),
      ),
    );
  }
}
