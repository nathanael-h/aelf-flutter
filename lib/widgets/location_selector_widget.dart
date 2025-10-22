import 'package:flutter/material.dart';
import '../utils/location_service.dart';

/// Widget to select a location from hierarchical list
class LocationSelectorWidget extends StatefulWidget {
  final Function(String) onLocationSelected;
  final String? currentLocationId;

  const LocationSelectorWidget({
    super.key,
    required this.onLocationSelected,
    this.currentLocationId,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  LocationData? _locationData;
  bool _isLoading = true;
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = widget.currentLocationId;
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final data = await LocationService.loadLocations();
      setState(() {
        _locationData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  void _selectLocation(String locationId) {
    setState(() {
      _selectedLocationId = locationId;
    });
    widget.onLocationSelected(locationId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locationData == null) {
      return const Center(
          child: Text('Erreur de chargement des localisations'));
    }

    return ListView(
      children: _locationData!.continents.map((continent) {
        return _buildContinentTile(continent);
      }).toList(),
    );
  }

  Widget _buildContinentTile(Continent continent) {
    final hasCountries = continent.countries.isNotEmpty;
    final isSelected = _selectedLocationId == continent.id;

    return Column(
      children: [
        // Continent selector (clickable)
        ListTile(
          leading: Icon(
            isSelected ? Icons.check_circle : Icons.public,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
          title: Text(
            continent.nameFr,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
          onTap: () => _selectLocation(continent.id),
        ),
        // Countries expansion
        if (hasCountries)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.expand_more, size: 20),
              title: const Text(
                'Pays',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              children: continent.countries.map((country) {
                return _buildCountryTile(country);
              }).toList(),
            ),
          ),
        if (!hasCountries)
          Padding(
            padding: const EdgeInsets.only(left: 56, top: 8, bottom: 8),
            child: Text(
              'Aucun pays disponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildCountryTile(Country country) {
    final hasDioceses = country.dioceses.isNotEmpty;
    final isSelected = _selectedLocationId == country.id;

    return Column(
      children: [
        // Country selector (clickable)
        ListTile(
          leading: Icon(
            isSelected ? Icons.check_circle : Icons.flag,
            color: isSelected ? Theme.of(context).primaryColor : null,
            size: 20,
          ),
          title: Text(
            country.nameFr,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
          onTap: () => _selectLocation(country.id),
        ),
        // Dioceses expansion
        if (hasDioceses)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.expand_more, size: 18),
              title: const Text(
                'Diocèses',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
              children: country.dioceses.map((diocese) {
                return _buildDioceseTile(diocese);
              }).toList(),
            ),
          ),
        if (!hasDioceses)
          Padding(
            padding: const EdgeInsets.only(left: 72, top: 8, bottom: 8),
            child: Text(
              'Aucun diocèse disponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDioceseTile(Diocese diocese) {
    final isSelected = _selectedLocationId == diocese.id;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.location_city,
        color: isSelected ? Theme.of(context).primaryColor : null,
        size: 20,
      ),
      title: Text(
        diocese.nameFr,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      onTap: () => _selectLocation(diocese.id),
      contentPadding: const EdgeInsets.only(left: 72),
    );
  }
}

/// Show location selector in a bottom sheet
Future<void> showLocationSelector(
  BuildContext context, {
  required Function(String) onLocationSelected,
  String? currentLocationId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                const Text(
                  'Choisir une localisation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Location list
          Expanded(
            child: LocationSelectorWidget(
              onLocationSelected: onLocationSelected,
              currentLocationId: currentLocationId,
            ),
          ),
        ],
      ),
    ),
  );
}
