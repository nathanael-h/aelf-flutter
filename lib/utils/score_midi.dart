import 'dart:convert';
import 'dart:typed_data';

/// A psalm tone score may end with the MIDI of its psalmody, base64-encoded:
/// `<metadata id="midi">…</metadata>` (built by build.py in the Psaumes
/// repository, see offline_liturgy's assets/svg).
final _midiMetadata =
    RegExp(r'<metadata id="midi">\s*([A-Za-z0-9+/=\s]+?)\s*</metadata>');

final _anyMetadata = RegExp(r'<metadata\b[^>]*>.*?</metadata>', dotAll: true);

/// The MIDI embedded in [svg], or null if it has none (or an unreadable one).
Uint8List? scoreMidi(String svg) {
  final match = _midiMetadata.firstMatch(svg);
  if (match == null) return null;
  try {
    final midi = base64.decode(match.group(1)!.replaceAll(RegExp(r'\s'), ''));
    return midi.length > 4 && ascii.decode(midi.sublist(0, 4)) == 'MThd'
        ? midi
        : null;
  } on FormatException {
    return null;
  }
}

/// [svg] without its `<metadata>` elements: flutter_svg does not know them
/// (it logs "unhandled element"), and the drawing does not need them.
String stripScoreMetadata(String svg) => svg.replaceAll(_anyMetadata, '');
