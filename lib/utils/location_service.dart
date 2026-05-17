import 'package:shared_preferences/shared_preferences.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

const String keySelectedLocation = 'keySelectedLocation';

class LocationService {
  /// Save selected location ID to shared preferences.
  static Future<void> setSelectedLocation(String locationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySelectedLocation, locationId);
  }

  /// Retrieve selected location ID from shared preferences.
  static Future<String> getSelectedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(keySelectedLocation) ?? 'romain';
  }

  /// Return the full breadcrumb path for [locationId] (e.g. "Europe > France > Lyon"),
  /// searching recursively through [tree]. Returns null if not found.
  static String? getLocationDisplayName(
      String locationId, List<LocationNode> tree) {
    for (final node in tree) {
      final result = _searchTree(locationId, node, '');
      if (result != null) return result;
    }
    return null;
  }

  static String? _searchTree(
      String locationId, LocationNode node, String prefix) {
    final name = prefix.isEmpty
        ? node.location.frenchName
        : '$prefix > ${node.location.frenchName}';
    if (node.location.id == locationId) return name;
    for (final child in node.children) {
      final result = _searchTree(locationId, child, name);
      if (result != null) return result;
    }
    return null;
  }
}
