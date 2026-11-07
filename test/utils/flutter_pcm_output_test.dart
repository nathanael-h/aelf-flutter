import 'package:aelf_flutter/utils/tone_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The calls FlutterPcmOutput makes to the flutter_pcm_sound plugin.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the plugin only logs its errors, set before the audio', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_pcm_sound/methods'), (call) async {
      calls.add(call);
      return null;
    });

    await FlutterPcmOutput().setup(sampleRate: 44100);

    expect(calls.map((c) => c.method), ['setLogLevel', 'setup']);
    // LogLevel.error, for the Dart and the native side alike.
    expect(calls.first.arguments, {'log_level': 1});
  });
}
