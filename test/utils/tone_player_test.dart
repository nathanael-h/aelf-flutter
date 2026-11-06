import 'dart:io';
import 'dart:typed_data';

import 'package:aelf_flutter/utils/tone_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tone_test_helpers.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeOutput output;
  late TonePlayer player;
  late int notifications;
  final soundFont = File('assets/sounds/piano.sf2').readAsBytesSync();

  setUp(() {
    output = FakeOutput();
    player = TonePlayer(
      output: output,
      loadSoundFont: () async => ByteData.sublistView(soundFont),
      available: true,
    );
    notifications = 0;
    player.addListener(() => notifications++);
  });

  tearDown(() => player.dispose());

  test('nothing is set up before the first tone', () {
    expect(output.setups, 0);
    expect(player.isPlaying(melody([60])), isFalse);
  });

  test('a tone plays to its end, then the button comes back', () async {
    final midi = scoreMidiOf('PSALM_109');
    await player.toggle(midi);
    expect(player.isPlaying(midi), isTrue);
    expect(output.setups, 1);
    expect(output.fed, isNotEmpty, reason: 'start asks for a first block');

    output.drain();
    expect(player.isPlaying(midi), isFalse);
    final frames = output.fed.fold<int>(0, (n, block) => n + block.length);
    expect(frames / TonePlayer.sampleRate, closeTo(5.33 + 1, 0.15));
    expect(notifications, 2, reason: 'started, then ended');
  });

  test('a second press on the playing tone stops it', () async {
    final midi = scoreMidiOf('PSALM_109');
    await player.toggle(midi);
    await player.toggle(midi);
    expect(player.isPlaying(midi), isFalse);
    final fedBefore = output.fed.length;
    output.drain();
    expect(output.fed.length, fedBefore, reason: 'nothing more is fed');
  });

  test('another tone replaces the one being played', () async {
    final first = scoreMidiOf('PSALM_109');
    final second = melody([62, 64]);
    await player.toggle(first);
    await player.toggle(second);
    expect(player.isPlaying(first), isFalse);
    expect(player.isPlaying(second), isTrue);
    expect(output.setups, 1, reason: 'the audio is set up once');
  });

  test('the tone is identified by its content', () async {
    await player.toggle(melody([60]));
    expect(player.isPlaying(melody([60])), isTrue);
    expect(player.isPlaying(melody([61])), isFalse);
  });

  test('going to the background stops the tone', () async {
    final midi = scoreMidiOf('PSALM_109');
    await player.toggle(midi);
    player.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(player.isPlaying(midi), isFalse);
  });

  test('a failing audio set-up leaves the player idle', () async {
    final failing = TonePlayer(
      output: output,
      loadSoundFont: () async => throw Exception('no asset'),
      available: true,
    );
    await failing.toggle(melody([60]));
    expect(failing.isPlaying(melody([60])), isFalse);
    failing.dispose();
  });

  test('the output is released with the player', () async {
    final local = TonePlayer(
      output: output,
      loadSoundFont: () async => ByteData.sublistView(soundFont),
      available: true,
    );
    await local.toggle(melody([60]));
    local.dispose();
    expect(output.released, isTrue);
  });
}
