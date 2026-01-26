import 'package:aelf_flutter/utils/text_management.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/widgets/location_selector_widget.dart';
import 'package:aelf_flutter/utils/location_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsMenu extends StatefulWidget {
  static const routeName = '/settingsScreen';
  @override
  SettingsMenuState createState() => SettingsMenuState();
}

enum _regions {
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
  String _region = 'romain';
  String _locationDisplayName = 'Chargement...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final locationId = await LocationService.getSelectedLocation();
      final displayName =
          await LocationService.getLocationDisplayName(locationId);

      setState(() {
        _locationDisplayName = displayName ?? locationId;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationDisplayName = 'Erreur';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _onLocationSelected(String locationId) async {
    await LocationService.setSelectedLocation(locationId);
    await _loadCurrentLocation();

    // Update region in LiturgyState for compatibility
    context.read<LiturgyState>().updateRegion(locationId);

    // If offline liturgy feature was enabled previously but location changed,
    // ensure feature flags state is up to date (no-op but keeps flow consistent).
    // FeatureFlagsState persists value in SharedPreferences.

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Localisation mise à jour'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateRegion(String newRegion) {
    print("Changing region to $newRegion");
    context.read<LiturgyState>().updateRegion(newRegion);
    setState(() => _region = newRegion);
  }

  @override
  Widget build(BuildContext context) {
    _region = context.watch<LiturgyState>().region;
    return Consumer<CurrentZoom>(
      builder: ((context, currentZoom, child) {
        final zoomValue = currentZoom.value ?? 100.0;
        return Scaffold(
          appBar: AppBar(
            title: Text('Paramètres'),
          ),
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.fromLTRB(70, 20, 0, 16),
                      child: Text(
                        'Localisation',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // LEGACY REGION SELECTOR (for backward compatibility)
                    Container(
                      margin: EdgeInsets.fromLTRB(54, 8, 0, 8),
                      child: RadioGroup(
                        onChanged: (String? value) {
                          _updateRegion(value!);
                        },
                        groupValue: _region,
                        child: ExpansionTile(
                          title: Text('Régions',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color)),
                          subtitle: Text(
                            capitalizeFirstLowerElse(
                                context.watch<LiturgyState>().region),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          children: [
                            RadioListTile(
                              title: Text('Autre (Calendrier romain)'),
                              value: _regions.romain.name,
                            ),
                            RadioListTile(
                              title: Text(capitalizeFirstLowerElse(
                                  _regions.afrique.name)),
                              value: _regions.afrique.name,
                            ),
                            RadioListTile(
                              title: Text(capitalizeFirstLowerElse(
                                  _regions.belgique.name)),
                              value: _regions.belgique.name,
                            ),
                            RadioListTile(
                              title: Text(capitalizeFirstLowerElse(
                                  _regions.canada.name)),
                              value: _regions.canada.name,
                            ),
                            RadioListTile(
                              title: Text(capitalizeFirstLowerElse(
                                  _regions.france.name)),
                              value: _regions.france.name,
                            ),
                            RadioListTile(
                              title: Text(capitalizeFirstLowerElse(
                                  _regions.luxembourg.name)),
                              value: _regions.luxembourg.name,
                            ),
                            RadioListTile(
                              title: Text(capitalizeFirstLowerElse(
                                  _regions.monaco.name)),
                              value: _regions.monaco.name,
                            ),
                            RadioListTile(
                              title: Text(capitalizeFirstLowerElse(
                                  _regions.suisse.name)),
                              value: _regions.suisse.name,
                            ),
                            RadioListTile(
                              title: Text(
                                  capitalizeFirstLowerElse(_regions.lyon.name)),
                              value: _regions.lyon.name,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                        margin: EdgeInsets.fromLTRB(54, 12, 0, 16),
                        child: Divider(
                            height: 1, color: Theme.of(context).dividerColor)),

                    Container(
                      margin: EdgeInsets.fromLTRB(70, 20, 0, 32),
                      child: Text(
                        'Affichage',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.fromLTRB(70, 0, 0, 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ),
                              text: "Taille du texte",
                            ),
                          ),
                          Container(margin: EdgeInsets.fromLTRB(0, 2, 0, 0)),
                          Text(
                            "Agrandissement du texte : ${zoomValue.toStringAsFixed(0)}%",
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        ],
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.fromLTRB(46, 0, 0, 0),
                      child: Slider(
                        min: 60,
                        max: 300,
                        value: zoomValue,
                        onChanged: (newValue) {
                          currentZoom.updateZoom(newValue);
                        },
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.fromLTRB(54, 0, 0, 16),
                      child: Divider(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),

                    // Feature flag toggle for offline liturgy
                    Container(
                      margin: EdgeInsets.fromLTRB(54, 0, 0, 8),
                      child: SwitchListTile(
                        title: Text('Activer liturgie hors-ligne'),
                        subtitle: Text(
                            'Permet d\'utiliser et d\'essayer une future versions des offices (Laudes, Complies) hors connexion'),
                        value: context
                            .watch<FeatureFlagsState>()
                            .offlineLiturgyEnabled,
                        onChanged: (bool value) async {
                          await context
                              .read<FeatureFlagsState>()
                              .setOfflineLiturgyEnabled(value);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value
                                    ? 'Liturgie hors-ligne activée'
                                    : 'Liturgie hors-ligne désactivée'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    // NEW HIERARCHICAL LOCATION SELECTOR (visible only when offline feature enabled)
                    if (context
                        .watch<FeatureFlagsState>()
                        .offlineLiturgyEnabled)
                      Container(
                        margin: EdgeInsets.fromLTRB(54, 0, 0, 8),
                        child: ListTile(
                          leading: Icon(Icons.location_on),
                          title:
                              Text('Localisation pour la liturgie hors-ligne',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  )),
                          subtitle: _isLoadingLocation
                              ? Text('Chargement...')
                              : Text(
                                  capitalizeFirst(_locationDisplayName),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final currentLocation =
                                await LocationService.getSelectedLocation();
                            showLocationSelector(
                              context,
                              onLocationSelected: _onLocationSelected,
                              currentLocationId: currentLocation,
                            );
                          },
                        ),
                      ),
                    // Switch to toggle the use of Ancient Language Hebrew or Greek
                    Container(
                      margin: EdgeInsets.fromLTRB(54, 0, 0, 8),
                      child: SwitchListTile(
                        title: Text('Utiliser une langue ancienne'),
                        subtitle: Text(
                            'Permet de lire le texte en Français ou dans une langue ancienne (Grec ou Hébreu)'),
                        value: context.watch<LiturgyState>().useAncientLanguage,
                        onChanged: (bool value) async {
                          context
                              .read<LiturgyState>()
                              .updateUseAncientLanguage(value);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value
                                    ? 'Langue choisie : Grec-Hébreu'
                                    : 'Langue choisie : Français'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
