import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/utils/geolocalisation_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The settings' switch detecting the position at startup, with what the
/// system allows: off and greyed while it forbids it — the user's choice
/// kept for when it allows it again — with why, and the way to the system
/// settings. Turned on, it asks the system for the position first.
class GeolocationSetting extends StatefulWidget {
  const GeolocationSetting({super.key});

  @override
  State<GeolocationSetting> createState() => _GeolocationSettingState();
}

class _GeolocationSettingState extends State<GeolocationSetting>
    with WidgetsBindingObserver {
  // Null until known
  GeolocationAccess? _access;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the system settings, where the access may have changed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadAccess();
  }

  Future<void> _loadAccess() async {
    final access = await GeolocalisationService.access();
    if (mounted) setState(() => _access = access);
  }

  bool get _blocked =>
      _access == GeolocationAccess.serviceDisabled ||
      _access == GeolocationAccess.denied;

  Future<void> _onChanged(bool value) async {
    final flags = context.read<FeatureFlagsState>();
    if (value) {
      final access = await GeolocalisationService.requestAccess();
      if (mounted) setState(() => _access = access);
      if (access != GeolocationAccess.allowed) return;
    }
    await flags.setOfflineGeolocationEnabled(value);
    if (value && mounted) {
      await GeolocalisationService.detectAndPropose(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = Theme.of(context).colorScheme.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 54),
          title: const Text('Détecter ma position automatiquement'),
          subtitle: const Text(
              'Utilise la position de l’appareil pour suggérer la localisation liturgique au démarrage'),
          value: !_blocked &&
              context.watch<FeatureFlagsState>().offlineGeolocationEnabled,
          onChanged: _blocked ? null : _onChanged,
        ),
        if (_blocked)
          Padding(
            padding: const EdgeInsets.only(left: 54, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _access == GeolocationAccess.serviceDisabled
                      ? 'La localisation est désactivée sur l’appareil.'
                      : 'AELF n’a pas l’autorisation d’accéder à votre position.',
                  style: TextStyle(fontSize: 14, color: red),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: red,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () =>
                      GeolocalisationService.openSettings(_access!),
                  child: const Text('Ouvrir les réglages'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
