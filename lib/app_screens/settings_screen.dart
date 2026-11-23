import 'package:aelf_flutter/utils/text_management.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/localSolemnitiesState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/widgets/location_selector_widget.dart';
import 'package:aelf_flutter/utils/location_service.dart';
import 'package:aelf_flutter/utils/geolocalisation_service.dart';
import 'package:aelf_flutter/widgets/geolocation_setting.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsMenu extends StatefulWidget {
  static const routeName = '/settingsScreen';
  const SettingsMenu({super.key});

  @override
  SettingsMenuState createState() => SettingsMenuState();
}

// Every row's title keeps starting at the screen's long-standing x=54 (see
// the `left: 54` insets and `indent: 54` dividers below): the icon sits in
// the newly-freed 16-54 gutter rather than pushing the text further right.
const double _rowLeadingWidth = 24.0;
const double _rowTitleGap = 14.0;

Widget _rowIcon(IconData icon) => Icon(icon, size: 22);

/// Two overlapping notes, since no Material icon depicts a pair of them.
Widget _twoNotesIcon() => SizedBox(
      width: _rowLeadingWidth,
      height: 22,
      child: Stack(
        children: [
          Positioned(left: 0, top: 2, child: Icon(Icons.music_note, size: 14)),
          Positioned(
              right: 0, bottom: 0, child: Icon(Icons.music_note, size: 16)),
        ],
      ),
    );

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

  /// Leaving advanced mode resets every advanced setting it gates, rather
  /// than just hiding them, so they don't resurface silently if the reader
  /// comes back to it later.
  Future<void> _onAdvancedModeChanged(BuildContext context, bool value) async {
    await context.read<FeatureFlagsState>().setAdvancedModeEnabled(value);
    if (!value) {
      context.read<LiturgyState>().resetAdvancedSettings();
      context.read<LocalSolemnitiesState>().reset();
      context.read<SelectedCelebrationState>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOfflineEnabled =
        context.watch<FeatureFlagsState>().offlineLiturgyEnabled;
    final bool advancedModeEnabled =
        context.watch<FeatureFlagsState>().advancedModeEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Mode Avancé'),
            _buildModeDeveloppeSection(context, advancedModeEnabled),
            _buildSectionHeader(context, 'Affichage'),
            _buildAffichageSection(context),
            if (isOfflineEnabled) ...[
              _buildSectionHeader(context, 'Psalmodie'),
              _buildPsalmodieSection(context, advancedModeEnabled),
              if (advancedModeEnabled) ...[
                _buildSectionHeader(context, 'Lectures'),
                _buildLecturesSection(context),
              ],
            ],
            _buildSectionHeader(context, 'Localisation'),
            _buildLocalisationSection(
                context, isOfflineEnabled, advancedModeEnabled),
            const SizedBox(height: 32),
            _buildPreviousVersionSection(context, isOfflineEnabled),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildModeDeveloppeSection(
      BuildContext context, bool advancedModeEnabled) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.only(left: 16),
      secondary: _rowIcon(Icons.bolt),
      minLeadingWidth: _rowLeadingWidth,
      horizontalTitleGap: _rowTitleGap,
      title: const Text('Activer le Mode Avancé'),
      subtitle:
          const Text('Afficher les mémoires et les choix de communs, et autres '
              'fonctionnalités avancées.'),
      value: advancedModeEnabled,
      onChanged: (bool value) => _onAdvancedModeChanged(context, value),
    );
  }

  Widget _buildAffichageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<CurrentZoom>(
          builder: (context, currentZoom, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: _rowLeadingWidth,
                          // Matches ListTile's own M2 default icon color
                          // (used by every other row's icon), since this row
                          // isn't wrapped in a ListTile to inherit it.
                          child: Icon(Icons.format_size,
                              size: 22,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.black45
                                  : null)),
                      SizedBox(width: _rowTitleGap),
                      Expanded(
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
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                    divisions: 48,
                    value: currentZoom.value,
                    onChanged: (v) => currentZoom.updateZoom(v, persist: false),
                    onChangeEnd: (_) => currentZoom.persist(),
                  ),
                ),
              ],
            );
          },
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 16),
          secondary: _rowIcon(Icons.text_format),
          minLeadingWidth: _rowLeadingWidth,
          horizontalTitleGap: _rowTitleGap,
          title: const Text('Affichage classique'),
          subtitle: Text(context.watch<ThemeNotifier>().classicDisplay
              ? 'Police avec sérif et symboles calligraphiques'
              : 'Affichage moderne : police et symboles sans sérif'),
          value: context.watch<ThemeNotifier>().classicDisplay,
          onChanged: (bool value) =>
              context.read<ThemeNotifier>().toggleClassicDisplay(),
        ),
      ],
    );
  }

  Widget _buildLocalisationSection(
      BuildContext context, bool isOfflineEnabled, bool advancedModeEnabled) {
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
            contentPadding: const EdgeInsets.only(left: 16, right: 20),
            leading: _rowIcon(Icons.public),
            minLeadingWidth: _rowLeadingWidth,
            horizontalTitleGap: _rowTitleGap,
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
          if (GeolocalisationService.isSupportedPlatform)
            const GeolocationSetting(),
          const SizedBox(height: 24),
          if (advancedModeEnabled)
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

  Widget _buildPsalmodieSection(
      BuildContext context, bool advancedModeEnabled) {
    final state = context.watch<LiturgyState>();
    final psalmSvgEnabled = state.psalmSvgEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (advancedModeEnabled)
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 16),
            secondary: SizedBox(
              width: _rowLeadingWidth,
              child: Center(
                child: Text('[…]',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color)),
              ),
            ),
            minLeadingWidth: _rowLeadingWidth,
            horizontalTitleGap: _rowTitleGap,
            title: const Text('Afficher les versets imprécatoires'),
            subtitle: const Text(
                'Affiche les versets entre crochets dans les psaumes'),
            value: context.watch<LiturgyState>().useImprecatoryVerses,
            onChanged: (bool value) {
              context.read<LiturgyState>().updateImprecatoryVerses(value);
              _showSnackBar(
                  context, 'Versets Imprécatoires: ${value ? "ON" : "OFF"}');
            },
          ),
        SwitchListTile(
          contentPadding: const EdgeInsets.only(left: 16),
          secondary: _twoNotesIcon(),
          minLeadingWidth: _rowLeadingWidth,
          horizontalTitleGap: _rowTitleGap,
          title: const Text('Tons des psaumes'),
          subtitle: const Text('Affiche la notation musicale du ton psalmique'),
          value: psalmSvgEnabled,
          onChanged: (bool value) =>
              context.read<LiturgyState>().updatePsalmSvgEnabled(value),
        ),
      ],
    );
  }

  Widget _buildLecturesSection(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.only(left: 16),
      secondary: _rowIcon(Icons.looks_two),
      minLeadingWidth: _rowLeadingWidth,
      horizontalTitleGap: _rowTitleGap,
      title: const Text('Office des lectures sur deux ans'),
      subtitle: const Text('Lecture biblique des féries selon le cycle sur '
          'deux ans, dans les offices hors ligne'),
      value: context.watch<LiturgyState>().useTwoYearReadings,
      onChanged: (bool value) =>
          context.read<LiturgyState>().updateTwoYearReadings(value),
    );
  }

  /// The way back to the previous version of the app, the online offices
  /// (the legacy mode): on when the offline liturgy is off.
  Widget _buildPreviousVersionSection(
      BuildContext context, bool isOfflineEnabled) {
    return Padding(
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
                'VERSION PRÉCÉDENTE',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              secondary: _rowIcon(Icons.restore),
              title: const Text("Revenir à la version précédente de l'appli"),
              subtitle:
                  const Text('Offices en ligne, sans les nouvelles fonctions.'),
              value: !isOfflineEnabled,
              onChanged: (bool previousVersion) async {
                await context
                    .read<FeatureFlagsState>()
                    .setOfflineLiturgyEnabled(!previousVersion);
                // The previous version downloads its coming days as soon as
                // it is enabled, not at the next launch.
                if (previousVersion && mounted) {
                  context.read<LiturgyState>().autoSaveLiturgy();
                }
                if (mounted) {
                  _showSnackBar(
                      context,
                      previousVersion
                          ? 'Version précédente activée'
                          : 'Version précédente désactivée');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
