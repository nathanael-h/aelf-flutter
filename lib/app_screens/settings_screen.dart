import 'package:aelf_flutter/utils/text_management.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/widgets/location_selector_widget.dart';
import 'package:aelf_flutter/utils/location_service.dart';
import 'package:aelf_flutter/utils/geolocalisation_service.dart';
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
  romain
}

class SettingsMenuState extends State<SettingsMenu> {
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
      final tree = await context.read<LiturgyState>().locationTree;
      final displayName =
          LocationService.getLocationDisplayName(locationId, tree);
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

  Future<void> _onLocationSelected(String locationId) async {
    await LocationService.setSelectedLocation(locationId);
    await _loadCurrentLocation();
    if (mounted) {
      final state = context.read<LiturgyState>();
      state.updateOfflineRegion(locationId);
      final onlineRegion = await state.inferOnlineRegion(locationId);
      if (mounted) {
        state.updateRegion(onlineRegion);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localisation mise à jour'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateRegion(String newRegion) {
    context.read<LiturgyState>().updateRegion(newRegion);
  }

  @override
  Widget build(BuildContext context) {
    final bool isOfflineEnabled =
        context.watch<FeatureFlagsState>().offlineLiturgyEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text(
                        'FONCTIONNALITÉ BÊTA',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      title: const Text('Lancer la nouvelle version de AELF'),
                      subtitle: const Text(
                          'Essayer les futures versions des offices sans connexion, avec plein de nouvelles fonctions.'),
                      value: isOfflineEnabled,
                      onChanged: (bool value) async {
                        await context
                            .read<FeatureFlagsState>()
                            .setOfflineLiturgyEnabled(value);
                        if (mounted) {
                          _showSnackBar(
                              context,
                              value
                                  ? 'Nouvelle version activée'
                                  : 'Nouvelle version désactivée');
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _buildSectionHeader(context, 'Affichage'),
            _buildAffichageSection(context, isOfflineEnabled),
            if (isOfflineEnabled) ...[
              _buildSectionHeader(context, 'Psalmodie'),
              _buildPsalmodieSection(context),
            ],
            _buildSectionHeader(context, 'Localisation'),
            _buildLocalisationSection(context, isOfflineEnabled),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAffichageSection(BuildContext context, bool isOfflineEnabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<CurrentZoom>(
          builder: (context, currentZoom, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(54, 8, 0, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Taille du texte',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Agrandissement : ${currentZoom.value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                  child: Slider(
                    min: 60,
                    max: 300,
                    value: currentZoom.value,
                    onChanged: (v) => currentZoom.updateZoom(v),
                  ),
                ),
              ],
            );
          },
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 54),
          title: const Text('Police avec sérif (Libertinus)'),
          subtitle:
              const Text('Police classique adaptée aux textes liturgiques'),
          value: context.watch<ThemeNotifier>().serifFont,
          onChanged: (bool value) =>
              context.read<ThemeNotifier>().toggleSerifFont(),
        ),
        if (isOfflineEnabled) ...[
          const Divider(indent: 54),
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 54),
            title: const Text('Mode défilement'),
            subtitle: const Text(
                'Affiche tout le contenu en une seule page scrollable'),
            value: context.watch<LiturgyState>().useScrollMode,
            onChanged: (bool value) =>
                context.read<LiturgyState>().updateScrollMode(value),
          ),
        ],
      ],
    );
  }

  Widget _buildLocalisationSection(
      BuildContext context, bool isOfflineEnabled) {
    final String currentRegion = context.watch<LiturgyState>().region;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isOfflineEnabled)
          Container(
            margin: const EdgeInsets.fromLTRB(54, 8, 0, 8),
            child: ExpansionTile(
              title: Text('Régions',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)),
              subtitle: Text(
                capitalizeFirstLowerElse(currentRegion),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              children: [
                RadioGroup<String>(
                  groupValue: currentRegion,
                  onChanged: (val) {
                    if (val != null) _updateRegion(val);
                  },
                  child: Column(
                    children: _Regions.values.map((region) {
                      return RadioListTile<String>(
                        title: Text(region == _Regions.romain
                            ? 'Autre (Calendrier romain)'
                            : capitalizeFirstLowerElse(region.name)),
                        value: region.name,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        if (isOfflineEnabled) ...[
          ListTile(
            contentPadding: const EdgeInsets.only(left: 54, right: 20),
            leading: const Icon(Icons.location_on),
            title: const Text('Localisation'),
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
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 54),
            title: const Text('Détecter ma position automatiquement'),
            subtitle: const Text(
                'Utilise le GPS pour suggérer la localisation liturgique au démarrage'),
            value: context.watch<FeatureFlagsState>().offlineGeolocationEnabled,
            onChanged: (bool value) async {
              await context
                  .read<FeatureFlagsState>()
                  .setOfflineGeolocationEnabled(value);
              if (value && context.mounted) {
                await GeolocalisationService.detectAndPropose(context);
              }
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Text(
                      'Modification manuelle des fêtes changeantes',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Builder(builder: (context) {
                    final state = context.watch<LiturgyState>();
                    final epiphany = state.epiphanyDateOverride ??
                        state.locationEpiphanyDate;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 16, right: 16),
                      title: const Text("Date de l'Épiphanie"),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SegmentedButton<String>(
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                selectedForegroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              segments: const [
                                ButtonSegment(
                                    value: 'day', label: Text('6 janvier')),
                                ButtonSegment(
                                    value: 'sunday', label: Text('Dimanche')),
                              ],
                              selected: {epiphany},
                              onSelectionChanged: (Set<String> selection) {
                                context
                                    .read<LiturgyState>()
                                    .updateEpiphanyDate(selection.first);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Builder(builder: (context) {
                    final state = context.watch<LiturgyState>();
                    final ascension = state.ascensionDateOverride ??
                        state.locationAscensionDate;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 16, right: 16),
                      title: const Text("Date de l'Ascension"),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SegmentedButton<String>(
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                selectedForegroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              segments: const [
                                ButtonSegment(
                                    value: 'thursday', label: Text('Jeudi')),
                                ButtonSegment(
                                    value: 'sunday', label: Text('Dimanche')),
                              ],
                              selected: {ascension},
                              onSelectionChanged: (Set<String> selection) {
                                context
                                    .read<LiturgyState>()
                                    .updateAscensionDate(selection.first);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Builder(builder: (context) {
                    final state = context.watch<LiturgyState>();
                    final corpus = state.corpusDominiDateOverride ??
                        state.locationCorpusDominiDate;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 16, right: 16),
                      title: const Text('Date du Corpus Domini'),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SegmentedButton<String>(
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                selectedForegroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              segments: const [
                                ButtonSegment(
                                    value: 'thursday', label: Text('Jeudi')),
                                ButtonSegment(
                                    value: 'sunday', label: Text('Dimanche')),
                              ],
                              selected: {corpus},
                              onSelectionChanged: (Set<String> selection) {
                                context
                                    .read<LiturgyState>()
                                    .updateCorpusDominiDate(selection.first);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPsalmodieSection(BuildContext context) {
    final state = context.watch<LiturgyState>();
    final psalmSvgEnabled = state.psalmSvgEnabled;
    final source = state.psalmSvgSource;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 54),
          title: const Text('Afficher les versets imprécatoires'),
          subtitle:
              const Text('Affiche les versets entre crochets dans les psaumes'),
          value: context.watch<LiturgyState>().useImprecatoryVerses,
          onChanged: (bool value) {
            context.read<LiturgyState>().updateImprecatoryVerses(value);
            _showSnackBar(
                context, 'Versets Imprécatoires: ${value ? "ON" : "OFF"}');
          },
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 54),
          title: const Text('Tons des psaumes'),
          subtitle: const Text('Affiche la notation musicale du ton psalmique'),
          value: psalmSvgEnabled,
          onChanged: (bool value) =>
              context.read<LiturgyState>().updatePsalmSvgEnabled(value),
        ),
        if (psalmSvgEnabled) ...[
          _buildSubSectionHeader(context, 'Répertoire'),
          RadioGroup<String>(
            groupValue: source,
            onChanged: (val) {
              if (val != null) {
                context.read<LiturgyState>().updatePsalmSvgSource(val);
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  contentPadding: const EdgeInsets.only(left: 54),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text('Séminaire de Paris'),
                  value: 'seminaire-paris',
                ),
                RadioListTile<String>(
                  contentPadding: const EdgeInsets.only(left: 54),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text("Notre-Dame de l’Emmanuel"),
                  value: 'seminaire-emmanuel',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: Theme.of(context).colorScheme.secondary,
          thickness: 1.5,
          height: 32,
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 0, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubSectionHeader(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(70, 12, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
