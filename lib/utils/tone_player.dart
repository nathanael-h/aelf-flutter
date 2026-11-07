import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:aelf_flutter/utils/tone_renderer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

/// Where the PCM goes: [FlutterPcmOutput] in the app, a fake in tests.
abstract class PcmOutput {
  Future<void> setup({required int sampleRate});

  /// [onFeed] is called with the number of frames still queued, once when the
  /// queue runs low and once when it is empty (remaining = 0).
  Future<void> listen(
      {required int threshold, required void Function(int remaining) onFeed});

  Future<void> feed(Int16List samples);

  /// Asks for a first [listen] callback if nothing is queued.
  void start();

  Future<void> release();
}

/// Mono 16-bit output through flutter_pcm_sound (Android, iOS, macOS).
class FlutterPcmOutput implements PcmOutput {
  @override
  Future<void> setup({required int sampleRate}) async {
    // By default the plugin prints every buffer it feeds and every request
    // for more, a line every few tens of milliseconds: errors only.
    await FlutterPcmSound.setLogLevel(LogLevel.error);
    await FlutterPcmSound.setup(
      sampleRate: sampleRate,
      channelCount: 1,
      // Plays even when the iPhone is in silent mode: the user asked for it.
      iosAudioCategory: IosAudioCategory.playback,
    );
  }

  @override
  Future<void> listen(
      {required int threshold,
      required void Function(int remaining) onFeed}) async {
    FlutterPcmSound.setFeedCallback(onFeed);
    await FlutterPcmSound.setFeedThreshold(threshold);
  }

  @override
  Future<void> feed(Int16List samples) => FlutterPcmSound.feed(PcmArrayInt16(
      bytes: samples.buffer
          .asByteData(samples.offsetInBytes, samples.lengthInBytes)));

  @override
  void start() => FlutterPcmSound.start();

  @override
  Future<void> release() => FlutterPcmSound.release();
}

/// Plays the MIDI of the psalm tone scores with the piano SoundFont, one at a
/// time: starting a tone stops the previous one.
class TonePlayer extends ChangeNotifier with WidgetsBindingObserver {
  TonePlayer({
    PcmOutput? output,
    Future<ByteData> Function()? loadSoundFont,
    bool? available,
  })  : _output = output ?? FlutterPcmOutput(),
        _loadSoundFont =
            loadSoundFont ?? (() => rootBundle.load('assets/sounds/piano.sf2')),
        isAvailable = available ?? isSupportedPlatform {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Platforms where flutter_pcm_sound is available.
  static bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  static const sampleRate = 44100;

  /// Frames rendered at each feed (~46 ms), and the queue level under which
  /// the output asks for more (~93 ms): a stop is heard within ~0.15 s.
  static const blockFrames = 2048;
  static const feedThreshold = 4096;

  /// Whether tones can be played here: the play buttons are hidden otherwise.
  final bool isAvailable;

  final PcmOutput _output;
  final Future<ByteData> Function() _loadSoundFont;
  Future<ToneRenderer>? _renderer;
  ToneRenderer? _ready;
  Uint8List? _current;
  bool _disposed = false;

  /// Whether [midi] is the tone being played.
  bool isPlaying(Uint8List midi) =>
      _current != null && listEquals(_current, midi);

  /// Plays [midi], or stops it if it is the tone being played.
  Future<void> toggle(Uint8List midi) async {
    if (isPlaying(midi)) {
      stop();
      return;
    }
    final ToneRenderer renderer;
    try {
      renderer = await (_renderer ??= _init());
    } catch (error) {
      _renderer = null;
      debugPrint('TonePlayer: cannot start audio: $error');
      return;
    }
    if (_disposed) return;
    renderer.start(midi);
    _current = midi;
    notifyListeners();
    _output.start();
  }

  /// Stops the tone being played (what is already queued, ~0.15 s, ends).
  void stop() {
    if (_current == null) return;
    _ready?.stop();
    _current = null;
    notifyListeners();
  }

  Future<ToneRenderer> _init() async {
    final renderer =
        ToneRenderer(await _loadSoundFont(), sampleRate: sampleRate);
    await _output.setup(sampleRate: sampleRate);
    await _output.listen(threshold: feedThreshold, onFeed: _onFeed);
    return _ready = renderer;
  }

  void _onFeed(int remaining) {
    final renderer = _ready;
    if (renderer == null || _current == null) return;
    final block = renderer.render(blockFrames);
    if (block != null) {
      _output.feed(block);
    } else if (remaining == 0) {
      // The tone and its resonance are over and the queue is empty.
      _current = null;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      stop();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _ready?.stop();
    _current = null;
    if (_ready != null) _output.release();
    super.dispose();
  }
}
