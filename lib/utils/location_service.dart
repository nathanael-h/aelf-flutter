import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String keySelectedLocation = 'keySelectedLocation';

// ==================== DATA MODELS ====================

class LocationData {
  final List<Continent> continents;

  LocationData({required this.continents});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      continents: (json['continents'] as List)
          .map((c) => Continent.fromJson(c))
          .toList(),
    );
  }
}

class Continent {
  final String id;
  final String nameEn;
  final String nameFr;
  final List<Country> countries;

  Continent({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.countries,
  });

  factory Continent.fromJson(Map<String, dynamic> json) {
    return Continent(
      id: json['id'],
      nameEn: json['name_en'],
      nameFr: json['name_fr'],
      countries:
          (json['countries'] as List).map((c) => Country.fromJson(c)).toList(),
    );
  }
}

class Country {
  final String id;
  final String nameEn;
  final String nameFr;
  final List<Diocese> dioceses;

  Country({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.dioceses,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'],
      nameEn: json['name_en'],
      nameFr: json['name_fr'],
      dioceses:
          (json['dioceses'] as List).map((d) => Diocese.fromJson(d)).toList(),
    );
  }
}

class Diocese {
  final String id;
  final String nameEn;
  final String nameFr;

  Diocese({
    required this.id,
    required this.nameEn,
    required this.nameFr,
  });

  factory Diocese.fromJson(Map<String, dynamic> json) {
    return Diocese(
      id: json['id'],
      nameEn: json['name_en'],
      nameFr: json['name_fr'],
    );
  }
}

// ==================== SERVICE ====================

/// Service to load and manage locations
class LocationService {
  static LocationData? _cachedLocationData;

  /// Load locations from JSON file
  static Future<LocationData> loadLocations() async {
    if (_cachedLocationData != null) {
      return _cachedLocationData!;
    }

    final String jsonString = await rootBundle.loadString(
      'packages/offline_liturgy/assets/locations.json',
    );
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    _cachedLocationData = LocationData.fromJson(jsonData);
    return _cachedLocationData!;
  }

  /// Save selected location (diocese ID)
  static Future<void> setSelectedLocation(String locationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySelectedLocation, locationId);
  }

  /// Get selected location (diocese ID)
  static Future<String> getSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String location = prefs.getString(keySelectedLocation) ?? 'romain';
    return location;
  }

  /// Get the full path of a location (Continent > Country > Diocese)
  static Future<String?> getLocationDisplayName(String locationId) async {
    final locationData = await loadLocations();

    for (var continent in locationData.continents) {
      for (var country in continent.countries) {
        for (var diocese in country.dioceses) {
          if (diocese.id == locationId) {
            return '${continent.nameFr} > ${country.nameFr} > ${diocese.nameFr}';
          }
        }
      }
    }
    return null;
  }
}
