/// Keeping the online and offline region selections in step.
///
/// The app carries two region notions and they are not the same size:
///
/// * **Online regions** — the eight values `api.aelf.org` accepts. Anything
///   else in a request URL returns no liturgy.
/// * **Offline locations** — the `offline_liturgy` package's location tree,
///   currently ~60 nodes: continents, countries, and every French diocese with
///   its own proper calendar.
///
/// A user picking an offline location must still get a working online liturgy,
/// because Mass has no offline implementation and because the online path is
/// what everyone sees while `feature_offline_liturgy` is off. That is what
/// [inferOnlineRegion] is for: it walks a location up its parent chain until
/// it reaches a country the API knows, and falls back to the Roman calendar
/// when it reaches the top without finding one.
///
/// These are pure so they can be exercised against the real location tree —
/// see `test/utils/region_sync_test.dart`, which asserts every node in it
/// resolves to a region the API actually accepts.
library;

/// The regions `api.aelf.org` accepts, and the only values that may reach
/// `LiturgyState._getAELFLiturgyOnWeb`.
const Set<String> kValidOnlineRegions = {
  'france',
  'belgique',
  'luxembourg',
  'suisse',
  'canada',
  'monaco',
  'afrique',
  'romain',
};

/// App region ids → `offline_liturgy` location ids, where the two spellings
/// differ. Everything not listed uses the same id on both sides.
const Map<String, String> kOnlineRegionToLocationId = {
  'belgique': 'belgium',
  'suisse': 'switzerland',
};

/// `offline_liturgy` country location ids → the matching online region.
const Map<String, String> kLocationIdToOnlineRegion = {
  'france': 'france',
  'belgium': 'belgique',
  'switzerland': 'suisse',
  'luxembourg': 'luxembourg',
  'canada': 'canada',
  'monaco': 'monaco',
};

/// Where both sides land when nothing more specific applies: the Roman
/// calendar, which every region falls back to.
const String kDefaultRegion = 'romain';

/// The `offline_liturgy` location id for an app region id.
String liturgyIdFor(String offlineRegion) =>
    kOnlineRegionToLocationId[offlineRegion] ?? offlineRegion;

/// The online region to use for an offline [locationId].
///
/// Walks up the location tree via [parentOf] — which returns a node's parent id
/// or null at a root — and returns:
///
/// * the mapped region as soon as a known country is reached (so every French
///   diocese resolves to `france`);
/// * `afrique` for any id containing "africa", matching the API's single
///   Africa-wide region;
/// * [kDefaultRegion] on reaching a root with no match, for an unknown id, or
///   if the chain is longer than [maxDepth] — a malformed tree with a cycle
///   must not hang the caller.
String inferOnlineRegion(
  String locationId,
  String? Function(String id) parentOf, {
  int maxDepth = 16,
}) {
  String? current = locationId;
  var depth = 0;

  while (current != null && depth++ < maxDepth) {
    final mapped = kLocationIdToOnlineRegion[current];
    if (mapped != null) return mapped;
    if (current.contains('africa')) return 'afrique';
    current = parentOf(current);
  }

  return kDefaultRegion;
}

/// [inferOnlineRegion] over an `offline_liturgy` location map.
///
/// Typed loosely so this file keeps no compile dependency on the package: the
/// values only need a `parent` field, which `LocationData` has.
String inferOnlineRegionFor(
        String locationId, Map<String, dynamic> locations) =>
    inferOnlineRegion(locationId, (id) => locations[id]?.parent as String?);
