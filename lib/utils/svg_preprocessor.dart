/// Preprocesses a raw SVG psalm score string to match the app's visual style.
///
/// Three substitutions are applied:
/// - font-family: "Linux Libertine" → LibertinusSerif or SourceSans3
/// - rgba red notation → explicit fill + color attributes set to [redColor]
/// - currentColor → [textColor] (CSS rgba string derived from the theme's bodyMedium)
String preprocessPsalmSvg(
  String svg, {
  required String textColor,
  required bool serifFont,
  required String redColor,
}) {
  final fontFamily = serifFont ? 'LibertinusSerif' : 'SourceSans3';

  return svg
      .replaceAll('font-family="Linux Libertine"', 'font-family="$fontFamily"')
      .replaceAll(
        'color="rgba(100.0000%, 0.0000%, 0.0000%, 100.0000%)"',
        'fill="$redColor" color="$redColor"',
      )
      .replaceAll('currentColor', textColor);
}
