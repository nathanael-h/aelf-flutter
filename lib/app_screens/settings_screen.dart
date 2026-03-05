import 'package:aelf_flutter/utils/text_management.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/widgets/location_selector_widget.dart';
import 'package:aelf_flutter/utils/location_service.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsMenu extends StatefulWidget {
  static const routeName = '/settingsScreen';
  const SettingsMenu({Key? key}) : super(key: key);

  @override
  SettingsMenuState createState() => SettingsMenuState();
}

enum _Regions {
  france,
  belgique,
  luxembourg,
  suisse,
  canada,
  monaco,
  afrique,
  romain,
  lyon
}

class SettingsMenuState extends State<SettingsMenu> {
  String _locationDisplayName = 'Chargement...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  /// Loads the display name for the current liturgy location
  Future<void> _loadCurrentLocation() async {
    try {
      final locationId = await LocationService.getSelectedLocation();
      final displayName =
          await LocationService.getLocationDisplayName(locationId);

      if (mounted) {
        setState(() {
          _locationDisplayName = displayName ?? locationId;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationDisplayName = 'Erreur';
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Handles location selection from the modern hierarchical selector
  Future<void> _onLocationSelected(String locationId) async {
    await LocationService.setSelectedLocation(locationId);
    await _loadCurrentLocation();

    if (mounted) {
      context.read<LiturgyState>().updateRegion(locationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Localisation mise à jour'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Updates the legacy region setting
  void _updateRegion(String newRegion) {
    context.read<LiturgyState>().updateRegion(newRegion);
  }

  @override
  Widget build(BuildContext context) {
    // We use selectors or specific watches to avoid global rebuilds
    final String currentRegion = context.watch<LiturgyState>().region;
    final bool isOfflineEnabled =
        context.watch<FeatureFlagsState>().offlineLiturgyEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSectionHeader(context, 'Localisation'),

              // --- LEGACY REGION SELECTOR ---
              Container(
                margin: const EdgeInsets.fromLTRB(54, 8, 0, 8),
                child: ExpansionTile(
                  title: Text('Régions',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  subtitle: Text(
                    capitalizeFirstLowerElse(currentRegion),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  children: _Regions.values.map((region) {
                    return RadioListTile<String>(
                      title: Text(region == _Regions.romain
                          ? 'Autre (Calendrier romain)'
                          : capitalizeFirstLowerElse(region.name)),
                      value: region.name,
                      groupValue: currentRegion,
                      onChanged: (val) => _updateRegion(val!),
                    );
                  }).toList(),
                ),
              ),

              const Divider(indent: 54),

              _buildSectionHeader(context, 'Affichage'),

              // --- TEXT ZOOM SECTION ---
              // Using a nested Consumer to ensure only this part rebuilds during slider movement
              Consumer<CurrentZoom>(
                builder: (context, currentZoom, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(70, 0, 0, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Taille du texte",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Agrandissement : ${currentZoom.value.toStringAsFixed(0)}%",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                                fontSize: 14,
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(46, 0, 20, 0),
                        child: Slider(
                          min: 60,
                          max: 300,
                          value: currentZoom.value,
                          onChanged: (newValue) =>
                              currentZoom.updateZoom(newValue),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // --- FONT SETTINGS ---
              SwitchListTile(
                contentPadding: const EdgeInsets.only(left: 54),
                title: const Text('Police avec sérif (Cardo)'),
                subtitle: const Text(
                    'Police classique adaptée aux textes liturgiques'),
                value: context.watch<ThemeNotifier>().serifFont,
                onChanged: (bool value) =>
                    context.read<ThemeNotifier>().toggleSerifFont(),
              ),

              const Divider(indent: 54),

              // --- FEATURE FLAGS / OFFLINE ---
              SwitchListTile(
                contentPadding: const EdgeInsets.only(left: 54),
                title: const Text('Activer liturgie hors-ligne'),
                subtitle: const Text(
                    'Essayer les futures versions des offices sans connexion'),
                value: isOfflineEnabled,
                onChanged: (bool value) async {
                  await context
                      .read<FeatureFlagsState>()
                      .setOfflineLiturgyEnabled(value);
                  if (mounted) {
                    _showSnackBar(
                        context,
                        value
                            ? 'Liturgie hors-ligne activée'
                            : 'Liturgie hors-ligne désactivée');
                  }
                },
              ),

              // Modern Location Selector (Visible only if offline is enabled)
              if (isOfflineEnabled)
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 54, right: 20),
                  leading: const Icon(Icons.location_on),
                  title: const Text('Localisation liturgie hors-ligne'),
                  subtitle: Text(
                    _isLoadingLocation
                        ? 'Chargement...'
                        : capitalizeFirst(_locationDisplayName),
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final currentLocation =
                        await LocationService.getSelectedLocation();
                    if (mounted) {
                      showLocationSelector(
                        context,
                        onLocationSelected: _onLocationSelected,
                        currentLocationId: currentLocation,
                      );
                    }
                  },
                ),

              // --- OTHER SETTINGS ---
              SwitchListTile(
                contentPadding: const EdgeInsets.only(left: 54),
                title: const Text('Versets imprécatoires'),
                subtitle: const Text(
                    "Affiche les versets entre crochets dans les psaumes"),
                value: context.watch<LiturgyState>().useImprecatoryVerses,
                onChanged: (bool value) {
                  context.read<LiturgyState>().updateImprecatoryVerses(value);
                  _showSnackBar(context,
                      'Versets Imprécatoires: ${value ? "ON" : "OFF"}');
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// UI Helper for section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(70, 20, 0, 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// UI Helper for snackbars
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
