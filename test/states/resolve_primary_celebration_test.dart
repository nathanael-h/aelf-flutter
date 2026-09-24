import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

/// LiturgyState.resolvePrimaryCelebration() picks which celebration heads the
/// offline drawer header. It must agree with BaseOfficeViewState._loadOffice's
/// own rule for honouring the cross-office selection (SelectedCelebrationState),
/// or the header would name a different celebration than the one actually on
/// screen — see LeftMenuOfficeHeader.
void main() {
  final dataLoader = FileSystemDataLoader();

  CelebrationContext celebration({
    required String code,
    int? precedence,
    bool isCelebrable = true,
  }) {
    return CelebrationContext(
      celebrationCode: code,
      celebrationTitle: code,
      date: DateTime(2026, 9, 24),
      precedence: precedence,
      isCelebrable: isCelebrable,
      dataLoader: dataLoader,
    );
  }

  group('LiturgyState.resolvePrimaryCelebration', () {
    test('an empty office map yields nothing', () {
      expect(LiturgyState.resolvePrimaryCelebration(const {}, null), isNull);
    });

    test('with no selection, picks this office\'s own top celebration', () {
      final map = {
        'feast': celebration(code: 'feast', precedence: 5),
        'memorial': celebration(code: 'memorial', precedence: 10),
      };

      expect(LiturgyState.resolvePrimaryCelebration(map, null)?.celebrationCode,
          'feast');
    });

    test('falls back to the first entry when nothing is celebrable', () {
      final map = {
        'a': celebration(code: 'a', isCelebrable: false),
        'b': celebration(code: 'b', isCelebrable: false),
      };

      expect(LiturgyState.resolvePrimaryCelebration(map, null)?.celebrationCode,
          'a');
    });

    test('prefers the cross-office selection when it is at least as important',
        () {
      // Two concurring optional memorials, same precedence: nothing about
      // this office's own detection order should override an explicit,
      // equally-ranked choice made in another office.
      final map = {
        'memorial_a': celebration(code: 'memorial_a', precedence: 12),
        'memorial_b': celebration(code: 'memorial_b', precedence: 12),
      };

      expect(
          LiturgyState.resolvePrimaryCelebration(map, 'memorial_b')
              ?.celebrationCode,
          'memorial_b');
    });

    test('a lower-priority selection never hides a higher-priority celebration',
        () {
      final map = {
        'feast': celebration(code: 'feast', precedence: 5),
        'memorial': celebration(code: 'memorial', precedence: 10),
      };

      // Stale selection from a day where the memorial was all there was —
      // today a real feast (precedence 5) is also happening, so it wins.
      expect(
          LiturgyState.resolvePrimaryCelebration(map, 'memorial')
              ?.celebrationCode,
          'feast');
    });

    test('a selection absent from today\'s map is ignored', () {
      final map = {'feast': celebration(code: 'feast', precedence: 5)};

      expect(
          LiturgyState.resolvePrimaryCelebration(map, 'not_today')
              ?.celebrationCode,
          'feast');
    });

    test('a selection that is not celebrable today is ignored', () {
      final map = {
        'feast': celebration(code: 'feast', precedence: 5),
        'commemoration': celebration(
            code: 'commemoration', precedence: 12, isCelebrable: false),
      };

      expect(
          LiturgyState.resolvePrimaryCelebration(map, 'commemoration')
              ?.celebrationCode,
          'feast');
    });
  });
}
