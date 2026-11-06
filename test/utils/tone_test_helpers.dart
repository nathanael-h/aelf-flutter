// Helpers shared by the psalm tone playback tests.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aelf_flutter/utils/score_midi.dart';

/// The Emmanuel seminary scores of the offline_liturgy package in use (local
/// override or git dependency), found through the package config.
Directory emmanuelScores() {
  final config =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map;
  final package = (config['packages'] as List)
      .cast<Map>()
      .firstWhere((p) => p['name'] == 'offline_liturgy');
  final rootUri = package['rootUri'] as String;
  final root = Uri.parse('.dart_tool/')
      .resolve(rootUri.endsWith('/') ? rootUri : '$rootUri/');
  return Directory.fromUri(root.resolve('assets/svg/seminaire-emmanuel/'));
}

Uint8List scoreMidiOf(String name) =>
    scoreMidi(File('${emmanuelScores().path}$name.svg').readAsStringSync())!;

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
