import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/location_service.dart';
import 'package:aelf_flutter/utils/settings.dart';
import 'package:aelf_flutter/widgets/location_selector_widget.dart';

/// Whether the system lets the app know the device's position.
enum GeolocationAccess {
  /// The app may ask for the position.
  allowed,

  /// Not granted yet, but the system may still ask the user.
  askable,

  /// Location is off on the device.
  serviceDisabled,

  /// The user refused the app the position: only the system settings may
  /// grant it now.
  denied,
}

/// What [GeolocalisationService.detectAndPropose] could tell the user.
enum DetectionOutcome {
  /// No fix, no network, or the position could not be resolved to a known
  /// location — the user turning the toggle on deserves to be told, rather
  /// than seeing nothing happen.
  failed,

  /// Resolved, but it matches the current selection already.
  unchanged,

  /// Resolved to a different location: the proposal dialog was shown.
  proposed,
}

class GeolocalisationService {
  /// Platforms with a reliable device position: desktop/web have none, so
  /// the toggle and every automatic check stay off there rather than
  /// offering a feature that cannot really work.
  static bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Bumped whenever the settings toggle just learned the OS access state —
  /// e.g. the user picked "don't ask again" on a re-prompt. [GeolocationAccessBanner]
  /// listens so it refreshes immediately instead of waiting for the app to
  /// next be backgrounded and resumed.
  static final ValueNotifier<int> accessChanged = ValueNotifier(0);

  static void notifyAccessChanged() => accessChanged.value++;

  /// What the system allows the app now — changed in its settings, it is
  /// asked again when the app comes back to the foreground.
  static Future<GeolocationAccess> access() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return GeolocationAccess.serviceDisabled;
      }
      return switch (await Geolocator.checkPermission()) {
        LocationPermission.whileInUse ||
        LocationPermission.always =>
          GeolocationAccess.allowed,
        LocationPermission.deniedForever => GeolocationAccess.denied,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine =>
          GeolocationAccess.askable,
      };
    } catch (_) {
      return GeolocationAccess.denied;
    }
  }

  /// Asks the user for the position if the system still may, and tells
  /// what it then allows.
  static Future<GeolocationAccess> requestAccess() async {
    final current = await access();
    if (current != GeolocationAccess.askable) return current;
    try {
      await Geolocator.requestPermission();
    } catch (_) {}
    return access();
  }

  /// Opens the system settings where [access] may be granted: the device's
  /// location settings when it is off, else the app's.
  static Future<void> openSettings(GeolocationAccess access) async {
    try {
      if (access == GeolocationAccess.serviceDisabled) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (_) {}
  }

  // No settings page an app may open leads to iOS's Location Services —
  // same rule as the settings screen's own warning (geolocation_setting.dart).
  static bool _canOpenSettings(GeolocationAccess access) =>
      !(defaultTargetPlatform == TargetPlatform.iOS &&
          access == GeolocationAccess.serviceDisabled);

  /// Tells the user offline geolocation is enabled but the system no longer
  /// allows it — revoked after being granted. The hourly background check
  /// stays silent on purpose, and the settings screen is only seen by
  /// someone who opens it, so this is what surfaces the problem instead of
  /// leaving the user wondering why detection stopped working.
  static void warnAccessRevoked(
      BuildContext context, GeolocationAccess access) {
    final message = access == GeolocationAccess.serviceDisabled
        ? 'La localisation a été désactivée sur l’appareil : la détection automatique de votre région est en pause.'
        : 'AELF n’a plus l’autorisation d’accéder à votre position : la détection automatique de votre région est en pause.';
    final messenger = ScaffoldMessenger.of(context);
    messenger.showMaterialBanner(MaterialBanner(
      content: Text(message),
      actions: [
        if (_canOpenSettings(access))
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              openSettings(access);
            },
            child: const Text('Ouvrir les réglages'),
          ),
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text('Fermer'),
        ),
      ],
    ));
  }

  static const _countryToLocationId = {
    'FR': 'france',
    'BE': 'belgique',
    'CH': 'suisse',
    'LU': 'luxembourg',
    'CA': 'canada',
    'MC': 'monaco',
  };

  static const _stableIds = {
    'france',
    'belgique',
    'suisse',
    'luxembourg',
    'canada',
    'monaco',
    'afrique',
    'romain',
    'europe',
    'north_america',
    'africa',
  };

  static const _africanCountries = {
    'DZ',
    'AO',
    'BJ',
    'BW',
    'BF',
    'BI',
    'CM',
    'CV',
    'CF',
    'TD',
    'KM',
    'CG',
    'CD',
    'CI',
    'DJ',
    'EG',
    'GQ',
    'ER',
    'ET',
    'GA',
    'GH',
    'GN',
    'GW',
    'KE',
    'LS',
    'LR',
    'LY',
    'MG',
    'MW',
    'ML',
    'MR',
    'MU',
    'YT',
    'MA',
    'MZ',
    'NA',
    'NE',
    'NG',
    'RE',
    'RW',
    'ST',
    'SN',
    'SC',
    'SL',
    'SO',
    'ZA',
    'SD',
    'SZ',
    'TZ',
    'GM',
    'TG',
    'TN',
    'UG',
    'EH',
    'ZM',
    'ZW',
  };

  /// What to actually offer for [known] candidates (already filtered to
  /// ones registered in the location tree): a diocese — anything not a
  /// stable country/continent id — is always paired with "France", never
  /// applied on its own, since the diocese and national calendars can
  /// genuinely differ (local feasts, etc.) and the choice is the user's.
  /// Exposed for tests; [detectAndPropose] is the only real caller.
  @visibleForTesting
  static List<String> offeredCandidates(List<String> known) {
    final offered = {...known};
    if (known.any((id) => !_stableIds.contains(id))) offered.add('france');
    return offered.toList();
  }

  /// Canonical string identifying what would currently be proposed: equal
  /// signatures mean the exact same answer(s) as last time, which is what
  /// [detectAndPropose] uses to avoid nagging the user every hour with a
  /// prompt they already saw and dismissed — only a genuine change (moved
  /// somewhere else, a diocese now registered, …) clears it. Exposed for
  /// tests; [detectAndPropose] is the only real caller.
  @visibleForTesting
  static String proposalSignature(List<String> candidateIds,
      {bool unknown = false}) {
    final sorted = [...candidateIds]..sort();
    return '${unknown ? 'unknown' : 'known'}:${sorted.join(',')}';
  }

  /// Entry point: detect position and propose a location change. A detected
  /// diocese is always offered alongside its country (e.g. Lyon *and*
  /// France) rather than applied on its own, since the two calendars can
  /// genuinely differ. Never throws, never blocks UI — but does report what
  /// it could do, so a user-initiated call (e.g. the settings toggle) can
  /// tell the user when detection failed instead of leaving them with no
  /// feedback at all.
  static Future<DetectionOutcome> detectAndPropose(BuildContext context,
      {bool userInitiated = false}) async {
    try {
      final position = await _getPosition(userInitiated: userInitiated);
      if (position == null) return DetectionOutcome.failed;

      // One candidate per detected diocese (usually one, occasionally two
      // when the diocese boundary data overlaps two adjacent dioceses near
      // their shared edge), or a single country/continent-level id when no
      // diocese applies.
      final rawIds = await _resolveLocationIds(position);
      if (rawIds.isEmpty) return DetectionOutcome.failed;

      final liturgyState = context.read<LiturgyState>();
      final tree = await liturgyState.locationTree;
      final known = <String>[];
      String? firstUnknown;
      for (final id in rawIds) {
        if (_stableIds.contains(id) ||
            LocationService.getLocationDisplayName(id, tree) != null) {
          known.add(id);
        } else {
          // A French diocese with no YAML data yet — not a valid choice.
          firstUnknown ??= id;
        }
      }

      final currentId = await LocationService.getSelectedLocation();

      if (known.isEmpty) {
        // Every candidate is an unregistered diocese.
        final rawId = firstUnknown!;
        final signature = proposalSignature([rawId], unknown: true);
        if (await _alreadyProposed(signature, userInitiated)) {
          return DetectionOutcome.unchanged;
        }
        _showDialog(
            context,
            () => showDetectionDialog(context, 'france',
                showHelperMessage: true, rawDioceseId: rawId),
            signature);
        return DetectionOutcome.proposed;
      }

      // A diocese is always offered alongside its country, not applied on
      // its own: the user may prefer the broader national calendar to the
      // diocese's (they can differ — local feasts, etc.), so this is a
      // choice, never an automatic pick. Checked against `known`, not the
      // country-widened set below, so already being on the country does
      // *not* by itself suppress a more specific diocese match.
      if (known.contains(currentId)) {
        return DetectionOutcome.unchanged;
      }
      final offered = offeredCandidates(known);
      final signature = proposalSignature(offered);
      if (await _alreadyProposed(signature, userInitiated)) {
        return DetectionOutcome.unchanged;
      }

      if (offered.length == 1) {
        final proposedId = offered.single;
        _showDialog(
            context, () => showDetectionDialog(context, proposedId), signature);
        return DetectionOutcome.proposed;
      }

      // Several plausible, registered candidates — either the diocese and
      // its country, or two overlapping dioceses (plus their country).
      final names = {
        for (final id in offered)
          id: LocationService.getLocationDisplayName(id, tree) ?? id,
      };
      _showDialog(context, () => showAmbiguousDetectionDialog(context, names),
          signature);
      return DetectionOutcome.proposed;
    } catch (_) {
      // Fail silently — geolocation is optional
      return DetectionOutcome.failed;
    }
  }

  /// True when [signature] is exactly what was last proposed, so the caller
  /// should stay silent rather than ask the same question again.
  ///
  /// [userInitiated] always answers false: the dedup exists to stop the
  /// hourly background check from nagging, never to refuse the user an
  /// answer when they just asked for one by turning the toggle on — which
  /// would also have them told "vous êtes déjà sur la localisation
  /// détectée" while sitting on a different region entirely.
  static Future<bool> _alreadyProposed(
      String signature, bool userInitiated) async {
    if (userInitiated) return false;
    return await getGeoLastProposedSignature() == signature;
  }

  /// Shows [show] after the current frame, and only then remembers
  /// [signature] as proposed: persisting it up front would burn the
  /// proposal for good on a frame where the context goes away before the
  /// dialog is ever built.
  static void _showDialog(
      BuildContext context, void Function() show, String signature) {
    if (!context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      show();
      await setGeoLastProposedSignature(signature);
    });
  }

  static Future<Position?> _getPosition({bool userInitiated = false}) async {
    // Only a user-initiated call (the settings toggle) may prompt the OS
    // permission dialog. The silent background check must never surprise
    // the user with a native prompt it didn't ask for — it just gives up if
    // access isn't already granted, and GeolocationAccessBanner tells the
    // user why.
    final currentAccess =
        userInitiated ? await requestAccess() : await access();
    if (currentAccess != GeolocationAccess.allowed) return null;

    // Prefer last known position for speed; fall back to current
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
    } catch (_) {}

    // Right after the permission is granted there is usually no last known
    // position yet, and a first ("cold") GPS fix can take longer than the
    // background check's budget — give the user-initiated toggle more time
    // to get one rather than silently giving up.
    final timeLimit = Duration(seconds: userInitiated ? 25 : 10);
    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: timeLimit,
      ),
    ).timeout(timeLimit);
  }

  /// The candidates matching [position]: usually a single id, but possibly
  /// several for a French point whose diocese-boundary data overlaps two
  /// adjacent dioceses near their shared edge.
  static Future<List<String>> _resolveLocationIds(Position position) async {
    final countryCode =
        await _detectCountryCode(position.latitude, position.longitude);
    if (countryCode == null) return const [];

    if (countryCode == 'FR') {
      final dioceses =
          await _detectFrenchDioceses(position.latitude, position.longitude);
      return dioceses.isEmpty ? const ['france'] : dioceses;
    }
    if (_africanCountries.contains(countryCode)) return const ['afrique'];
    return [_countryToLocationId[countryCode] ?? 'romain'];
  }

  static Future<String?> _detectCountryCode(double lat, double lng) async {
    try {
      final placemarks = await Geocoding()
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 5));
      return placemarks.firstOrNull?.isoCountryCode;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> _detectFrenchDioceses(
      double lat, double lng) async {
    try {
      final diocesesString =
          await rootBundle.loadString('assets/geo/france_dioceses.geojson');
      final departmentsString =
          await rootBundle.loadString('assets/geo/france_departments.geojson');
      final mappingString =
          await rootBundle.loadString('assets/geo/france_diocese_mapping.json');

      return await compute(_computeDioceses, {
        'lat': lat,
        'lng': lng,
        'dioceses': diocesesString,
        'departments': departmentsString,
        'mapping': mappingString,
      });
    } catch (_) {
      return const [];
    }
  }

  // Runs in an isolate to keep UI thread free. Returns every diocese whose
  // polygon contains the point — more than one only when the boundary data
  // of two adjacent dioceses overlaps near their shared edge.
  static List<String> _computeDioceses(Map<String, dynamic> params) {
    final lat = (params['lat'] as num).toDouble();
    final lng = (params['lng'] as num).toDouble();
    final dioceses =
        jsonDecode(params['dioceses'] as String) as Map<String, dynamic>;
    final departments =
        jsonDecode(params['departments'] as String) as Map<String, dynamic>;
    final mapping =
        jsonDecode(params['mapping'] as String) as Map<String, dynamic>;

    // Primary: OSM diocese polygons (sub-department precision, 82 dioceses)
    final found = _findInDioceses(lat, lng, dioceses);
    if (found.isNotEmpty) return found;

    // Fallback: department-level mapping (covers remaining dioceses + DOM-TOM)
    // — a flat one-to-one lookup, so it can only ever yield a single id.
    final deptCode = _findDepartment(lat, lng, departments);
    if (deptCode == null) return const [];
    final diocese = mapping[deptCode] as String?;
    return diocese == null ? const [] : [diocese];
  }

  static List<String> _findInDioceses(
      double lat, double lng, Map<String, dynamic> geojson) {
    final matches = <String>[];
    final features = geojson['features'] as List;
    for (final feature in features) {
      final diocese =
          (feature['properties'] as Map<String, dynamic>)['diocese'] as String;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;
      final coords = geometry['coordinates'] as List;

      bool inside = false;
      if (type == 'Polygon') {
        inside = _pointInPolygon(lat, lng, coords[0] as List);
      } else if (type == 'MultiPolygon') {
        for (final poly in coords) {
          if (_pointInPolygon(lat, lng, (poly as List)[0] as List)) {
            inside = true;
            break;
          }
        }
      }
      if (inside) matches.add(diocese);
    }
    return matches;
  }

  static String? _findDepartment(
      double lat, double lng, Map<String, dynamic> geojson) {
    final features = geojson['features'] as List;
    for (final feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final code = properties['code'] as String;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;

      if (type == 'Polygon') {
        final rings = geometry['coordinates'] as List;
        if (_pointInPolygon(lat, lng, rings[0] as List)) return code;
      } else if (type == 'MultiPolygon') {
        final polygons = geometry['coordinates'] as List;
        for (final polygon in polygons) {
          if (_pointInPolygon(lat, lng, (polygon as List)[0] as List)) {
            return code;
          }
        }
      }
    }
    return null;
  }

  // Ray casting algorithm: GeoJSON uses [lng, lat] coordinate order
  static bool _pointInPolygon(double lat, double lng, List ring) {
    bool inside = false;
    int j = ring.length - 1;
    for (int i = 0; i < ring.length; i++) {
      final xi = (ring[i][0] as num).toDouble(); // longitude
      final yi = (ring[i][1] as num).toDouble(); // latitude
      final xj = (ring[j][0] as num).toDouble();
      final yj = (ring[j][1] as num).toDouble();
      if (((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  static String _formatDioceseId(String id) {
    return id
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Proposes [detectedId], or tells that [rawDioceseId] — detected, with
  /// no data yet — isn't registered ([showHelperMessage]).
  @visibleForTesting
  static void showDetectionDialog(BuildContext context, String detectedId,
      {bool showHelperMessage = false, String? rawDioceseId}) {
    final liturgyState = context.read<LiturgyState>();
    final displayedName =
        rawDioceseId != null ? _formatDioceseId(rawDioceseId) : null;

    // The theme's red, paler by night: the day's is unreadable on the dark
    // dialog
    final theme = Theme.of(context);
    final red = theme.colorScheme.secondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Position détectée',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        content: displayedName != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayedName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: red,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ce diocèse n\'est pas encore enregistré dans l\'application.\nContactez les développeurs pour participer à l\'entrée des données ou désactivez la détection GPS pour ne plus avoir ce message.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              )
            : FutureBuilder<String>(
                future: _getDisplayName(detectedId, liturgyState),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? detectedId,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: red,
                      ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ignorer'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (ctx.mounted) {
                showLocationSelector(
                  ctx,
                  onLocationSelected: (id) async {
                    await LocationService.setSelectedLocation(id);
                    if (ctx.mounted) {
                      ctx.read<LiturgyState>().updateOfflineRegion(id);
                    }
                  },
                  currentLocationId: detectedId,
                );
              }
            },
            child: const Text('Choisir manuellement'),
          ),
          if (!showHelperMessage)
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await LocationService.setSelectedLocation(detectedId);
                if (ctx.mounted) {
                  ctx.read<LiturgyState>().updateOfflineRegion(detectedId);
                }
              },
              child: const Text('Utiliser'),
            ),
        ],
      ),
    );
  }

  static Future<String> _getDisplayName(String id, LiturgyState state) async {
    final tree = await state.locationTree;
    return LocationService.getLocationDisplayName(id, tree) ?? id;
  }

  /// The position maps to more than one registered location — a diocese and
  /// its country (the usual case, since the two calendars can differ), or
  /// two overlapping dioceses and their country: one button per candidate,
  /// keyed by id in [candidateNames] with its display name, rather than
  /// silently picking one.
  @visibleForTesting
  static void showAmbiguousDetectionDialog(
      BuildContext context, Map<String, String> candidateNames) {
    final theme = Theme.of(context);

    void choose(BuildContext ctx, String id) async {
      Navigator.pop(ctx);
      await LocationService.setSelectedLocation(id);
      if (ctx.mounted) ctx.read<LiturgyState>().updateOfflineRegion(id);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Position détectée',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        // Reads for both shapes this dialog takes: the usual diocese + its
        // country, and the rarer two overlapping dioceses + their country.
        content: Text(
          'Quel calendrier liturgique souhaitez-vous utiliser ?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          for (final entry in candidateNames.entries)
            FilledButton(
              onPressed: () => choose(ctx, entry.key),
              child: Text(entry.value),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (ctx.mounted) {
                showLocationSelector(
                  ctx,
                  onLocationSelected: (id) async {
                    await LocationService.setSelectedLocation(id);
                    if (ctx.mounted) {
                      ctx.read<LiturgyState>().updateOfflineRegion(id);
                    }
                  },
                  currentLocationId: candidateNames.keys.first,
                );
              }
            },
            child: const Text('Choisir manuellement'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ignorer'),
          ),
        ],
      ),
    );
  }
}
