import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

/// The office drawer header names the day's celebration by reading
/// LiturgyState._activeOfflineOfficeMap, but offlineComplines is a
/// `Map<String, ComplineDefinition>` — a different shape from every other
/// office's `Map<String, CelebrationContext>` — so it needs unwrapping.
/// Missing that case entirely left the Compline header always showing the
/// bare weekday, never the day's actual feast or season.
void main() {
  final dataLoader = FileSystemDataLoader();

  ComplineDefinition compline(String title, {int? precedence}) {
    return ComplineDefinition(
      context: CelebrationContext(
        celebrationCode: title,
        celebrationTitle: title,
        date: DateTime(2027, 3, 25),
        precedence: precedence,
        isCelebrable: true,
        dataLoader: dataLoader,
      ),
      dayOfCompline: 'thursday',
    );
  }

  group('LiturgyState.complineContextMap', () {
    test('an empty Compline map stays empty', () {
      expect(LiturgyState.complineContextMap(const {}), isEmpty);
    });

    test('unwraps each ComplineDefinition to its own CelebrationContext', () {
      final complines = {
        'Jeudi Saint': compline('Jeudi Saint', precedence: 1),
      };

      final map = LiturgyState.complineContextMap(complines);

      expect(map.keys, ['Jeudi Saint']);
      expect(map['Jeudi Saint']?.celebrationTitle, 'Jeudi Saint');
      expect(map['Jeudi Saint']?.precedence, 1);
    });

    test('the result feeds resolvePrimaryCelebration like any other office',
        () {
      final complines = {
        'Jeudi Saint': compline('Jeudi Saint', precedence: 1),
      };

      final primary = LiturgyState.resolvePrimaryCelebration(
        LiturgyState.complineContextMap(complines),
        null,
      );

      expect(primary?.celebrationTitle, 'Jeudi Saint');
    });
  });
}
