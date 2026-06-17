/// Preprocesses a raw SVG psalm score string to match the app's visual style.
///
/// Three substitutions are applied:
/// - font-family: "Linux Libertine" → LibertinusSerif or SourceSans3
/// - color injected on root `<svg>` element → body text colour (resolves currentColor)
/// - rgba red notation → explicit fill + color attributes set to [redColor]
String preprocessPsalmSvg(
  String svg, {
  required bool darkMode,
  required bool serifFont,
  required String redColor,
}) {
  final fontFamily = serifFont ? 'LibertinusSerif' : 'SourceSans3';
  final textColor = darkMode ? '#EFE9DE' : '#5D451A';

  return svg
      .replaceAll('font-family="Linux Libertine"', 'font-family="$fontFamily"')
      .replaceAll(
        'color="rgba(100.0000%, 0.0000%, 0.0000%, 100.0000%)"',
        'fill="$redColor" color="$redColor"',
      )
      .replaceAll('currentColor', textColor);
}
