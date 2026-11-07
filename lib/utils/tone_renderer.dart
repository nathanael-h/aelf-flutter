import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';

/// Renders the MIDI of a psalm tone with the piano SoundFont, block by block,
/// as 16-bit mono PCM. Pure Dart: the audio output is up to the caller.
class ToneRenderer {
  ToneRenderer(ByteData soundFont, {this.sampleRate = 44100})
      : _sequencer = MidiFileSequencer(Synthesizer.loadByteData(
            soundFont, SynthesizerSettings(sampleRate: sampleRate)));

  final int sampleRate;
  final MidiFileSequencer _sequencer;

  /// Time left for the last note to fade once the MIDI is over.
  static const resonance = Duration(seconds: 1);

  bool _playing = false;
  int _resonanceFrames = 0;

  bool get isPlaying => _playing;

  /// Starts [midi] from the beginning, replacing what was playing.
  void start(Uint8List midi) {
    _sequencer.play(MidiFile.fromByteData(ByteData.sublistView(midi)),
        loop: false);
    _resonanceFrames = sampleRate * resonance.inMilliseconds ~/ 1000;
    _playing = true;
  }

  void stop() {
    _sequencer.stop();
    _playing = false;
  }

  /// The next [frames] of sound, or null once the tone and its resonance are
  /// over (or after [stop]).
  Int16List? render(int frames) {
    if (!_playing) return null;
    if (_sequencer.endOfSequence) {
      if (_resonanceFrames <= 0) {
        stop();
        return null;
      }
      _resonanceFrames -= frames;
    }
    // MidiFileSequencer.renderMono only fills half of its buffer: render the
    // two channels and mix them here.
    final left = Float32List(frames);
    final right = Float32List(frames);
    _sequencer.render(left, right);
    return toPcm16(left, right);
  }
}

/// Mixes two channels into 16-bit samples, clamped: a peak above 1.0 must
/// saturate, not wrap around (which clicks).
Int16List toPcm16(Float32List left, Float32List right) {
  final pcm = Int16List(left.length);
  for (var i = 0; i < left.length; i++) {
    pcm[i] = ((left[i] + right[i]) * 16384).round().clamp(-32768, 32767);
  }
  return pcm;
}
