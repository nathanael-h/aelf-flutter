// Helpers shared by the psalm tone playback tests.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aelf_flutter/utils/score_midi.dart';
import 'package:aelf_flutter/utils/tone_player.dart';

/// The psalm tone scores of the offline_liturgy package in use (local
/// override or git dependency), found through the package config.
Directory psalmToneScores() {
  final config =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map;
  final package = (config['packages'] as List)
      .cast<Map>()
      .firstWhere((p) => p['name'] == 'offline_liturgy');
  final rootUri = package['rootUri'] as String;
  final root = Uri.parse('.dart_tool/')
      .resolve(rootUri.endsWith('/') ? rootUri : '$rootUri/');
  return Directory.fromUri(root.resolve('assets/svg/psalm-tones/'));
}

Uint8List scoreMidiOf(String name) =>
    scoreMidi(File('${psalmToneScores().path}$name.svg').readAsStringSync())!;

/// A one-track MIDI file playing [keys], one quarter note each.
Uint8List melody(List<int> keys) {
  final track = <int>[0, 0xC0, 0]; // piano
  for (final key in keys) {
    track.addAll([0, 0x90, key, 90, 0x83, 0x00, 0x80, key, 0]); // 384 ticks
  }
  track.addAll([0, 0xFF, 0x2F, 0]);
  return Uint8List.fromList([
    ...ascii.encode('MThd'), 0, 0, 0, 6, 0, 0, 0, 1, 0x01, 0x80, // 384 ppq
    ...ascii.encode('MTrk'), 0, 0, 0, track.length, ...track,
  ]);
}

/// Keeps what is fed, and lets the test play the part of the audio output:
/// [drain] empties the queue the way flutter_pcm_sound calls back.
class FakeOutput implements PcmOutput {
  void Function(int remaining)? onFeed;
  final fed = <Int16List>[];
  int setups = 0;
  int starts = 0;
  bool released = false;

  @override
  Future<void> setup({required int sampleRate}) async => setups++;

  @override
  Future<void> listen(
      {required int threshold,
      required void Function(int remaining) onFeed}) async {
    this.onFeed = onFeed;
  }

  @override
  Future<void> feed(Int16List samples) async => fed.add(samples);

  @override
  void start() {
    starts++;
    onFeed?.call(0);
  }

  @override
  Future<void> release() async => released = true;

  /// Low-buffer then empty-queue callbacks until nothing more is fed.
  void drain({int maxCalls = 1000}) {
    for (var i = 0; i < maxCalls; i++) {
      final before = fed.length;
      onFeed!(100);
      if (fed.length == before) {
        onFeed!(0);
        if (fed.length == before) return;
      }
    }
  }
}
