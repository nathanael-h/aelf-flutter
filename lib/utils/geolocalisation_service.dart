import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/location_service.dart';
import 'package:aelf_flutter/widgets/location_selector_widget.dart';

/// Outcome of a location access check.
enum GeolocationAccess { granted, serviceDisabled, denied, deniedForever }

class GeolocalisationService {
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

  /// Entry point: detect position and propose location change if different.
  /// Runs fully in background — never throws, never blocks UI.
  static Future<void> detectAndPropose(BuildContext context) async {
    try {
      final position = await _getPosition();
      if (position == null) return;

      final rawId = await _resolveLocationId(position);
      if (rawId == null) return;

      // Check whether the detected location exists in the tree
      final liturgyState = context.read<LiturgyState>();
      final tree = await liturgyState.locationTree;
      final existsInTree =
          LocationService.getLocationDisplayName(rawId, tree) != null;

      // Unknown diocese: detected a French diocese that has no YAML data yet
      final isUnknownDiocese = !existsInTree && !_stableIds.contains(rawId);
      final proposedId = isUnknownDiocese ? 'france' : rawId;

      final currentId = await LocationService.getSelectedLocation();
      // For unknown dioceses always show the prompt; otherwise only if location changed
      if (!isUnknownDiocese && currentId == proposedId) return;

      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showDetectionDialog(
              context,
              proposedId,
              showHelperMessage: isUnknownDiocese,
              rawDioceseId: isUnknownDiocese ? rawId : null,
            );
          }
        });
      }
    } catch (_) {
      // Fail silently — geolocation is optional
    }
  }

  /// Reads the current location access state. Pass [request] = true to trigger
  /// the OS permission prompt when permission is merely [denied] (never for
  /// [deniedForever], which the OS will not re-prompt for).
  static Future<GeolocationAccess> _checkAccess({bool request = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return GeolocationAccess.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return GeolocationAccess.granted;
      case LocationPermission.deniedForever:
        return GeolocationAccess.deniedForever;
      default:
        return GeolocationAccess.denied;
    }
  }

  /// Requests location access in-context — called when the user enables the
  /// geolocation setting. Shows a rationale before the OS prompt and offers an
  /// "open settings" path for blocked/disabled states. Returns true only if
  /// access is granted.
  static Future<bool> requestAccessInteractive(BuildContext context) async {
    var access = await _checkAccess();

    if (access == GeolocationAccess.serviceDisabled) {
      if (context.mounted) {
        await _showOpenSettingsDialog(
          context,
          message:
              'La localisation est désactivée sur votre appareil. Activez-la '
              'pour suggérer automatiquement votre diocèse.',
          openSettings: Geolocator.openLocationSettings,
        );
      }
      return false;
    }

    if (access == GeolocationAccess.denied) {
      if (!context.mounted) return false;
      final proceed = await _showRationaleDialog(context);
      if (proceed != true) return false;
      access = await _checkAccess(request: true);
    }

    if (access == GeolocationAccess.granted) return true;

    if (access == GeolocationAccess.deniedForever) {
      if (context.mounted) {
        await _showOpenSettingsDialog(
          context,
          message:
              "L'accès à la position est bloqué. Autorisez-le dans les réglages "
              "de l'application pour suggérer automatiquement votre diocèse.",
          openSettings: Geolocator.openAppSettings,
        );
      }
      return false;
    }

    // Plain denial after prompting.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission de localisation refusée')),
      );
    }
    return false;
  }

  static Future<Position?> _getPosition() async {
    // Non-interactive: only proceed when access is already granted, so the
    // startup path never triggers a cold OS permission prompt.
    if (await _checkAccess() != GeolocationAccess.granted) return null;

    // Prefer last known position for speed; fall back to current
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
    } catch (_) {}

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    ).timeout(const Duration(seconds: 10));
  }

  static Future<String?> _resolveLocationId(Position position) async {
    final countryCode =
        await _detectCountryCode(position.latitude, position.longitude);
    if (countryCode == null) return null;

    if (countryCode == 'FR') {
      return await _detectFrenchDiocese(
              position.latitude, position.longitude) ??
          'france';
    }
    if (_africanCountries.contains(countryCode)) return 'afrique';
    return _countryToLocationId[countryCode] ?? 'romain';
  }

  static Future<String?> _detectCountryCode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 5));
      return placemarks.firstOrNull?.isoCountryCode;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _detectFrenchDiocese(double lat, double lng) async {
    try {
      final geojsonString =
          await rootBundle.loadString('assets/geo/france_departments.geojson');
      final mappingString =
          await rootBundle.loadString('assets/geo/france_diocese_mapping.json');

      return await compute(_computeDiocese, {
        'lat': lat,
        'lng': lng,
        'geojson': geojsonString,
        'mapping': mappingString,
      });
    } catch (_) {
      return null;
    }
  }

  // Runs in an isolate to keep UI thread free
  static String? _computeDiocese(Map<String, dynamic> params) {
    final lat = (params['lat'] as num).toDouble();
    final lng = (params['lng'] as num).toDouble();
    final geojson =
        jsonDecode(params['geojson'] as String) as Map<String, dynamic>;
    final mapping =
        jsonDecode(params['mapping'] as String) as Map<String, dynamic>;

    final deptCode = _findDepartment(lat, lng, geojson);
    if (deptCode == null) return null;
    return mapping[deptCode] as String?;
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
          if (_pointInPolygon(lat, lng, (polygon as List)[0] as List))
            return code;
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

  static void _showDetectionDialog(BuildContext context, String detectedId,
      {bool showHelperMessage = false, String? rawDioceseId}) {
    final liturgyState = context.read<LiturgyState>();
    final displayedName =
        rawDioceseId != null ? _formatDioceseId(rawDioceseId) : null;

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
                          color: const Color(0xFFBF2329),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ce diocèse n\'est pas encore enregistré dans l\'application. Contactez les développeurs pour participer à l\'entrée des données ou désactivez la détection GPS pour ne plus avoir ce message.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFBF2329),
                        ),
                  ),
                ],
              )
            : FutureBuilder<String>(
                future: _getDisplayName(detectedId, liturgyState),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? detectedId,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFBF2329),
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

  /// Title color matching the rest of the dialogs (white in dark mode).
  static Color _titleColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;

  /// Explains why the app needs the position, then lets the user proceed to the
  /// OS prompt. Returns true if the user agreed to continue.
  static Future<bool?> _showRationaleDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Détecter votre position',
            style: TextStyle(color: _titleColor(ctx))),
        content: const Text(
          'Pour vous suggérer automatiquement le diocèse correspondant, '
          "l'application a besoin d'accéder à votre position. Elle reste sur "
          "votre appareil et n'est jamais partagée.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  /// Generic "we can't access location, open settings to fix it" dialog.
  static Future<void> _showOpenSettingsDialog(
    BuildContext context, {
    required String message,
    required Future<bool> Function() openSettings,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Localisation indisponible',
            style: TextStyle(color: _titleColor(ctx))),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openSettings();
            },
            child: const Text('Ouvrir les réglages'),
          ),
        ],
      ),
    );
  }

  static Future<String> _getDisplayName(String id, LiturgyState state) async {
    final tree = await state.locationTree;
    return LocationService.getLocationDisplayName(id, tree) ?? id;
  }
}
