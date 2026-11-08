import 'dart:convert';

import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/utils/tone_player.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/tone_test_helpers.dart';

/// Records the presses instead of playing: the playback itself is covered by
/// test/utils/tone_player_test.dart.
class RecordingPlayer extends TonePlayer {
  RecordingPlayer({required bool available})
      : super(output: FakeOutput(), available: available);

  final pressed = <Uint8List>[];
  Uint8List? playing;

  @override
  bool isPlaying(Uint8List midi) =>
      playing != null && listEquals(playing, midi);

  @override
  Future<void> toggle(Uint8List midi) async {
    pressed.add(midi);
    playing = isPlaying(midi) ? null : midi;
    notifyListeners();
  }

  @override
  void stop() {
    playing = null;
    notifyListeners();
  }
}

String scoreWithMidi(Uint8List midi) =>
    '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="60" '
    'viewBox="0 0 300 60"><rect width="300" height="60"/>'
    '<metadata id="midi">${base64.encode(midi)}</metadata></svg>';

const scoreWithoutMidi = '<svg xmlns="http://www.w3.org/2000/svg" width="300" '
    'height="60" viewBox="0 0 300 60"><rect width="300" height="60"/></svg>';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final midi = melody([70, 72, 70]);
  late RecordingPlayer player;

  Future<void> pumpScores(WidgetTester tester, List<String> svgData,
      {bool available = true, double width = 400, double zoom = 100}) async {
    player = RecordingPlayer(available: available);
    final currentZoom = CurrentZoom()..updateZoom(zoom, persist: false);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: currentZoom),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider<TonePlayer>.value(value: player),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: PsalmToneWidget(svgData: svgData),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final playButton = find.byIcon(Icons.play_arrow_rounded);
  final stopButton = find.byIcon(Icons.stop_rounded);

  testWidgets('a score with a MIDI has a play button that becomes stop',
      (tester) async {
    await pumpScores(tester, [scoreWithMidi(midi)]);
    expect(playButton, findsOneWidget);
    expect(find.byTooltip('Écouter le ton'), findsOneWidget);

    await tester.tap(playButton);
    await tester.pump();
    expect(player.pressed.single, midi);
    expect(stopButton, findsOneWidget);
    expect(find.byTooltip('Arrêter'), findsOneWidget);

    await tester.tap(stopButton);
    await tester.pump();
    expect(player.pressed, hasLength(2));
    expect(playButton, findsOneWidget);
  });

  testWidgets('the button comes back when the tone ends by itself',
      (tester) async {
    await pumpScores(tester, [scoreWithMidi(midi)]);
    await tester.tap(playButton);
    await tester.pump();
    player.stop();
    await tester.pump();
    expect(playButton, findsOneWidget);
  });

  testWidgets('tapping the score itself plays nothing', (tester) async {
    await pumpScores(tester, [scoreWithMidi(midi)]);
    await tester.tap(find.byType(SvgPicture));
    await tester.pump();
    expect(player.pressed, isEmpty);
  });

  testWidgets('no button without a MIDI', (tester) async {
    await pumpScores(tester, [scoreWithoutMidi]);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('no button where tones cannot be played', (tester) async {
    await pumpScores(tester, [scoreWithMidi(midi)], available: false);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('the button stands in the left margin, centred on the score',
      (tester) async {
    await pumpScores(tester, [scoreWithMidi(midi)], width: 500);
    final score = tester.getRect(find.byType(SvgPicture));
    final button = tester.getRect(find.byType(ToneButton));
    expect(button.left, greaterThanOrEqualTo(0));
    expect(button.right, lessThanOrEqualTo(score.left + 0.5));
    expect(button.center.dy, moreOrLessEquals(score.center.dy, epsilon: 0.5));
    // The margin takes nothing from the score, drawn at its natural width.
    expect(score.width, moreOrLessEquals(300, epsilon: 0.5));
    expect(
        tester.getSize(playButton).width, moreOrLessEquals(20, epsilon: 0.5));
    expect(tester.takeException(), isNull, reason: 'no overflow');
  });

  testWidgets('a score never exceeds its column, its button keeps its size',
      (tester) async {
    await pumpScores(tester, [scoreWithMidi(midi)], width: 250);
    final score = tester.getRect(find.byType(SvgPicture));
    expect(score.right, lessThanOrEqualTo(250 - 15 + 0.5));
    expect(score.width, lessThan(300));
    expect(
        tester.getSize(playButton).width, moreOrLessEquals(20, epsilon: 0.5));
    expect(tester.takeException(), isNull, reason: 'no overflow');
  });

  testWidgets('the text zoom changes neither the score nor its button',
      (tester) async {
    await pumpScores(tester, [scoreWithMidi(midi)], width: 800, zoom: 200);
    expect(tester.getSize(find.byType(SvgPicture)).width,
        moreOrLessEquals(300, epsilon: 0.5));
    expect(
        tester.getSize(playButton).width, moreOrLessEquals(20, epsilon: 0.5));
  });

  testWidgets('at the smallest zoom the button fits in its margin',
      (tester) async {
    await pumpScores(tester, [scoreWithMidi(midi)], zoom: CurrentZoom.minZoom);
    final margin = liturgyRowIndentWidth(CurrentZoom.minZoom);
    expect(margin, lessThan(20));
    expect(tester.getSize(playButton).width,
        moreOrLessEquals(margin, epsilon: 0.5));
    expect(tester.getRect(find.byType(ToneButton)).right,
        lessThanOrEqualTo(margin + 0.5));
    expect(tester.takeException(), isNull, reason: 'no overflow');
  });

  testWidgets('a score that leaves the screen stops its tone', (tester) async {
    await pumpScores(tester, [scoreWithMidi(midi)]);
    await tester.tap(playButton);
    await tester.pump();
    expect(player.isPlaying(midi), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(player.isPlaying(midi), isFalse);
  });

  testWidgets('several scores share one button, for the page shown',
      (tester) async {
    final other = melody([67]);
    await pumpScores(tester, [scoreWithMidi(midi), scoreWithMidi(other)]);
    expect(playButton, findsOneWidget);
    final button = tester.getRect(find.byType(ToneButton));
    final page = tester.getRect(find.byType(PageView));
    expect(button.center.dy, moreOrLessEquals(page.center.dy, epsilon: 0.5));

    await tester.tap(playButton);
    await tester.pump();
    expect(player.pressed.single, midi);

    // Turning the page stops the tone of the page left.
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(player.isPlaying(midi), isFalse);

    await tester.tap(playButton);
    await tester.pump();
    expect(player.pressed.last, other);
  });
}
