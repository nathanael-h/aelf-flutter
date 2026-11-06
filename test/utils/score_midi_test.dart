import 'dart:convert';

import 'package:aelf_flutter/utils/score_midi.dart';
import 'package:aelf_flutter/utils/svg_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

/// The psalm tone scores carry the MIDI of their psalmody in a final
/// `<metadata id="midi">` element: read for playback, removed for display.
void main() {
  final midi = [...ascii.encode('MThd'), 0, 0, 0, 6, 0, 0, 0, 1, 1, 128];
  final encoded = base64.encode(midi);
  final score = '<svg fill="currentColor"><path d="M0 0"/>'
      '<metadata id="midi">$encoded</metadata></svg>';

  group('scoreMidi', () {
    test('decodes the embedded MIDI', () {
      expect(scoreMidi(score), midi);
    });

    test('tolerates line breaks inside the base64', () {
      final wrapped = '<svg><metadata id="midi">\n'
          '${encoded.substring(0, 8)}\n${encoded.substring(8)}\n</metadata></svg>';
      expect(scoreMidi(wrapped), midi);
    });

    test('is null without MIDI', () {
      expect(scoreMidi('<svg><path d="M0 0"/></svg>'), isNull);
    });

    test('is null for data that is not a MIDI file', () {
      final notMidi = base64.encode(ascii.encode('<svg>'));
      expect(scoreMidi('<svg><metadata id="midi">$notMidi</metadata></svg>'),
          isNull);
    });

    test('is null for broken base64', () {
      expect(
          scoreMidi('<svg><metadata id="midi">abc</metadata></svg>'), isNull);
    });
  });

  test('stripScoreMetadata removes every metadata element', () {
    const old = '<svg><metadata><description id="psalmodie">a b</description>'
        '</metadata><path d="M0 0"/></svg>';
    expect(stripScoreMetadata(score),
        '<svg fill="currentColor"><path d="M0 0"/></svg>');
    expect(stripScoreMetadata(old), '<svg><path d="M0 0"/></svg>');
  });

  test('the preprocessed score has no metadata left', () {
    final processed = preprocessPsalmSvg(score,
        textColor: 'rgba(0, 0, 0, 1.000)',
        serifFont: true,
        redColor: '#AA0000');
    expect(processed, isNot(contains('metadata')));
    expect(processed, contains('fill="rgba(0, 0, 0, 1.000)"'));
  });
}
