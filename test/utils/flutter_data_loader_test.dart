import 'package:aelf_flutter/utils/flutter_data_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A missing asset is normal here, not an error: `resolveOfficeContent` asks
/// for the French, Hebrew *and* Greek text of every psalm, and a psalm has no
/// Greek original — only the New Testament canticles do. The loader must
/// answer "nothing there" quietly.
///
/// Letting `rootBundle.loadString` throw for those does not just cost a
/// failed platform-channel round trip per miss: Flutter reports the failure
/// to `FlutterError.onError` too, and the integration suite then fails the
/// test it arrives in ("each offline office opens and renders something"),
/// after it has already completed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<FlutterErrorDetails> reported;
  late FlutterExceptionHandler? previousOnError;

  setUp(() {
    reported = [];
    previousOnError = FlutterError.onError;
    FlutterError.onError = reported.add;
  });

  tearDown(() => FlutterError.onError = previousOnError);

  test('a missing asset gives an empty string, and reports no error', () async {
    final content =
        await FlutterDataLoader().load('psalms/greek/PSALM_109.yaml');

    expect(content, isEmpty);
    expect(reported, isEmpty,
        reason: 'an expected miss must not reach FlutterError.onError, which '
            'is what fails the offline integration test');
  });

  test('an asset that does exist is still read', () async {
    final content = await FlutterDataLoader().load('psalms/PSALM_109.yaml');

    expect(content, isNotEmpty);
    expect(reported, isEmpty);
  });
}
