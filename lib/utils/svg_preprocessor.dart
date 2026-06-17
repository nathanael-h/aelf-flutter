/// Preprocesses a raw SVG psalm score string to match the app's visual style.
///
/// Three substitutions are applied:
/// - font-family: "Linux Libertine" → LibertinusSerif or SourceSans3
/// - currentColor → body text colour for the current brightness mode
/// - rgba red notation → app red colour for the current brightness mode
String preprocessPsalmSvg(
  String svg, {
  required bool darkMode,
  required bool serifFont,
}) {
  final fontFamily = serifFont ? 'LibertinusSerif' : 'SourceSans3';
  final textColor = darkMode ? '#EFE9DE' : '#5D451A';
  final redColor = darkMode ? '#f9787e' : '#BF2329';

  return svg
      .replaceAll('font-family="Linux Libertine"', 'font-family="$fontFamily"')
      .replaceAll('currentColor', textColor)
      .replaceAll(
        'color="rgba(100.0000%, 0.0000%, 0.0000%, 100.0000%)"',
        'color="$redColor"',
      );
}
