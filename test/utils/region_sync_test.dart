import 'package:aelf_flutter/utils/flutter_data_loader.dart';
import 'package:aelf_flutter/utils/region_sync.dart';
import 'package:aelf_flutter/utils/share_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

/// The offline location list is far longer than the online region list — about
/// sixty nodes (continents, countries, every French diocese) against the eight
/// regions `api.aelf.org` accepts. Picking an offline location therefore has to
/// be *translated* into an online region, because Mass has no offline
/// implementation and because the online path is what everyone sees while
/// `feature_offline_liturgy` is off.
///
/// These tests run that translation over the real location tree shipped by the
/// `offline_liturgy` package, so a new diocese or a renamed country cannot
/// silently start resolving to the wrong region — or to one the API rejects.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> locations;

  setUpAll(() async {
    final data = await LiturgyData.loadFromDataLoader(FlutterDataLoader());
    locations = Map<String, dynamic>.from(data.locationData);
  });

  String infer(String id) => inferOnlineRegionFor(id, locations);

  String? parentOf(String id) => locations[id]?.parent as String?;

  List<String> chainOf(String id) {
    final chain = <String>[];
    String? current = id;
    var guard = 0;
    while (current != null && guard++ < 16) {
      chain.add(current);
      current = parentOf(current);
    }
    return chain;
  }

  group('the real location tree', () {
    test('is substantially larger than the online region list', () {
      expect(locations, isNotEmpty);
      expect(locations.length, greaterThan(kValidOnlineRegions.length),
          reason: 'this asymmetry is the whole reason the mapping exists');
    });

    test('EVERY location resolves to a region the API accepts', () {
      // The load-bearing assertion: whatever a user picks in the location
      // sheet, the region that reaches api.aelf.org must be one of the eight.
      for (final id in locations.keys) {
        expect(kValidOnlineRegions, contains(infer(id)),
            reason: '"$id" (${chainOf(id).join(' > ')}) inferred '
                '"${infer(id)}", which api.aelf.org does not accept');
      }
    });

    test('every location also resolves to a shareable region', () {
      // ShareHelper falls back to 'romain' for an unknown region, so a
      // mismatch here would silently share the wrong calendar's page.
      for (final id in locations.keys) {
        final region = infer(id);
        expect(ShareHelper.isValidRegion(region), isTrue,
            reason: '"$id" inferred "$region", which ShareHelper rejects');
      }
    });

    test('inference is total: no location throws or hangs', () {
      for (final id in locations.keys) {
        expect(() => infer(id), returnsNormally, reason: id);
      }
    });
  });

  group('countries map to their own online region', () {
    test('each known country resolves to its API region', () {
      const expected = {
        'france': 'france',
        'belgium': 'belgique',
        'switzerland': 'suisse',
        'luxembourg': 'luxembourg',
        'canada': 'canada',
        'monaco': 'monaco',
      };
      expected.forEach((locationId, onlineRegion) {
        expect(locations, contains(locationId),
            reason: '$locationId should exist in the real tree');
        expect(infer(locationId), onlineRegion);
      });
    });

    test('the round trip is stable: region -> location id -> region', () {
      // liturgyIdFor and inferOnlineRegion are inverses for every region that
      // names a real country, which is what keeps the two selections in step
      // when the user changes either one.
      for (final region in [
        'france',
        'belgique',
        'suisse',
        'luxembourg',
        'canada',
        'monaco'
      ]) {
        final locationId = liturgyIdFor(region);
        expect(locations, contains(locationId),
            reason: '$region maps to "$locationId", absent from the tree');
        expect(infer(locationId), region,
            reason: '$region -> $locationId did not come back as $region');
      }
    });

    test('only belgique and suisse are spelled differently', () {
      expect(kOnlineRegionToLocationId, {
        'belgique': 'belgium',
        'suisse': 'switzerland',
      });
      for (final region in ['france', 'luxembourg', 'canada', 'monaco']) {
        expect(liturgyIdFor(region), region);
      }
    });
  });

  group('French dioceses inherit France', () {
    test('every diocese under france resolves to "france"', () {
      final dioceses = locations.keys
          .where((id) => id != 'france' && chainOf(id).contains('france'))
          .toList();

      expect(dioceses, isNotEmpty,
          reason: 'the tree should carry the French dioceses');
      expect(dioceses.length, greaterThan(20),
          reason: 'expected the full diocesan list, got ${dioceses.length}');

      for (final id in dioceses) {
        expect(infer(id), 'france', reason: id);
      }
    });

    test('a few by name, so a restructured tree is noticed', () {
      for (final id in ['paris', 'lyon', 'strasbourg', 'armees']) {
        expect(locations, contains(id));
        expect(infer(id), 'france', reason: id);
      }
    });
  });

  group('Africa', () {
    test('any id containing "africa" resolves to the single afrique region',
        () {
      final african =
          locations.keys.where((id) => id.contains('africa')).toList();
      expect(african, isNotEmpty);
      for (final id in african) {
        expect(infer(id), 'afrique', reason: id);
      }
    });

    test('the substring rule also catches ids that are not in the tree', () {
      expect(inferOnlineRegion('west-africa', (_) => null), 'afrique');
      expect(inferOnlineRegion('africa', (_) => null), 'afrique');
    });

    test('a child of an African node inherits afrique', () {
      expect(
        inferOnlineRegion(
            'dakar', (id) => id == 'dakar' ? 'north-africa' : null),
        'afrique',
      );
    });
  });

  group('fallback to the Roman calendar', () {
    test('a continental root with no country mapping falls back', () {
      // 'europe' and 'north-america' are real roots that name no API region.
      for (final id in ['europe', 'north-america']) {
        expect(locations, contains(id));
        expect(infer(id), 'romain', reason: id);
      }
    });

    test('"romain" is not a tree node and still resolves to itself', () {
      expect(locations, isNot(contains('romain')),
          reason: 'the Roman calendar is the default, not a location');
      expect(infer('romain'), 'romain');
    });

    test('an unknown location falls back rather than throwing', () {
      expect(infer('atlantis'), 'romain');
      expect(infer(''), 'romain');
    });

    test('the fallback is the documented default', () {
      expect(kDefaultRegion, 'romain');
      expect(kValidOnlineRegions, contains(kDefaultRegion));
    });
  });

  group('walking the chain', () {
    test('stops at the first country, ignoring anything above it', () {
      // A diocese under France must not keep walking to 'europe'.
      expect(infer('lyon'), 'france');
      expect(chainOf('lyon'), ['lyon', 'france', 'europe']);
    });

    test('a cycle cannot hang the caller', () {
      // Not reachable from the shipped data, but a malformed tree must degrade
      // rather than spin forever.
      String? cyclic(String id) => id == 'a' ? 'b' : 'a';
      expect(inferOnlineRegion('a', cyclic), 'romain');
    });

    test('a chain longer than maxDepth falls back', () {
      String? deep(String id) => 'n${int.parse(id.substring(1)) + 1}';
      expect(inferOnlineRegion('n0', deep, maxDepth: 4), 'romain');
    });

    test('a country deep in a chain is still found within maxDepth', () {
      var calls = 0;
      String? toFrance(String id) {
        calls++;
        return id == 'france' ? 'europe' : 'france';
      }

      expect(inferOnlineRegion('some_parish', toFrance), 'france');
      expect(calls, 1, reason: 'stops as soon as France is reached');
    });
  });

  group('the two region lists agree', () {
    test('every mapped online region is a valid one', () {
      for (final region in kLocationIdToOnlineRegion.values) {
        expect(kValidOnlineRegions, contains(region), reason: region);
      }
    });

    test('ShareHelper accepts exactly the valid online regions', () {
      for (final region in kValidOnlineRegions) {
        expect(ShareHelper.isValidRegion(region), isTrue,
            reason: '$region is a valid API region but ShareHelper rejects it');
      }
    });

    test('the API region list is the expected eight', () {
      expect(kValidOnlineRegions, {
        'france',
        'belgique',
        'luxembourg',
        'suisse',
        'canada',
        'monaco',
        'afrique',
        'romain',
      });
    });
  });
}
