import 'dart:io';
import 'dart:typed_data';

import 'package:aelf_flutter/utils/tone_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tone_test_helpers.dart';

/// Renders [midi] to the end; returns the samples.
List<int> renderAll(ToneRenderer renderer, Uint8List midi) {
  renderer.start(midi);
  final samples = <int>[];
  for (var block = renderer.render(2048);
      block != null;
      block = renderer.render(2048)) {
    samples.addAll(block);
  }
  return samples;
}

int peak(Iterable<int> samples) =>
    samples.fold(0, (max, s) => s.abs() > max ? s.abs() : max);

void main() {
  late ToneRenderer renderer;

  setUpAll(() {
    final soundFont = File('assets/sounds/piano.sf2').readAsBytesSync();
    renderer = ToneRenderer(ByteData.sublistView(soundFont));
  });

  test('a score is rendered to the end, then its resonance', () {
    final samples = renderAll(renderer, scoreMidiOf('PSALM_109'));
    // PSALM_109 (tone D38): bes c bes, a quarter rest, bes g bes8 c8 bes —
    // \breve played as quarters: 8 quarter notes at 90 = 5.33 s.
    final seconds = samples.length / renderer.sampleRate;
    expect(seconds, closeTo(5.33 + 1, 0.15));
    expect(peak(samples), greaterThan(1000), reason: 'not silent');
    expect(peak(samples), lessThan(32767), reason: 'no clipping');
    expect(renderer.isPlaying, isFalse);
  });

  test('every key of the psalm tones has a sound', () {
    // The tones span B2 (47) to D5 (74); the bank keeps A2–E5 and widens its
    // outer zones.
    for (final key in [40, 45, 47, 52, 60, 67, 74, 76, 84]) {
      final samples = renderAll(renderer, melody([key]));
      expect(peak(samples.take(renderer.sampleRate ~/ 2)), greaterThan(1000),
          reason: 'key $key is silent');
    }
  });

  test('stop ends the rendering at once', () {
    renderer.start(scoreMidiOf('PSALM_109'));
    expect(renderer.render(2048), isNotNull);
    renderer.stop();
    expect(renderer.isPlaying, isFalse);
    expect(renderer.render(2048), isNull);
  });

  test('start replaces the tone being played', () {
    renderer.start(scoreMidiOf('PSALM_109'));
    renderer.render(44100);
    final samples = renderAll(renderer, melody([60]));
    expect(samples.length / renderer.sampleRate, closeTo(0.67 + 1, 0.15));
  });

  test('rendering is much faster than real time', () {
    final watch = Stopwatch()..start();
    final samples = renderAll(renderer, scoreMidiOf('NT_10'));
    watch.stop();
    final audio = samples.length / renderer.sampleRate;
    expect(watch.elapsedMilliseconds / 1000, lessThan(audio / 4));
  });

  test('samples above full scale saturate instead of wrapping around', () {
    final pcm = toPcm16(Float32List.fromList([1.5, -1.5, 0.5]),
        Float32List.fromList([1.5, -1.5, 0.5]));
    expect(pcm, [32767, -32768, 16384]);
  });
}
