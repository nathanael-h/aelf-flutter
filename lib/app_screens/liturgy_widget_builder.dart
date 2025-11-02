import 'package:flutter/material.dart';
import 'package:aelf_flutter/models/liturgy_tab_data.dart';
import 'package:aelf_flutter/widgets/liturgy_part_column.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:provider/provider.dart';

/// Builder pour créer les widgets UI à partir des données parsées
class LiturgyWidgetBuilder {
  /// Construit les widgets pour les onglets
  static List<Widget> buildTabChildren({
    required BuildContext context,
    required List<LiturgyTabData> tabData,
    required Map? originalJson,
    TabController? tabController,
    List<int>? massPositions,
  }) {
    int menuIndex = 0;

    return tabData.asMap().entries.map((entry) {
      // ignore: unused_local_variable
      final int index = entry.key;
      final LiturgyTabData data = entry.value;

      // Cas spécial : menu de sélection des messes
      if (data.content == "__MASS_MENU__") {
        final widget = _buildMassMenu(
          context: context,
          aelfJson: originalJson,
          tabController: tabController,
          massPositions: massPositions,
          currentMenuIndex: menuIndex,
        );
        menuIndex++;
        return widget;
      }

      // Cas spécial : onglet d'informations avec zoom
      if (data.title == "Informations") {
        return _buildInformationTab(context, data);
      }

      // Cas spécial : onglet de chargement
      if (data.title == "Chargement") {
        return const Center(child: CircularProgressIndicator());
      }

      // Cas standard : LiturgyPartColumn
      return LiturgyPartColumn(
        title:
            data.displayTitle, // Utilise contentTitle si présent, sinon title
        subtitle: data.subtitle,
        repeatSubtitle: data.repeatSubtitle,
        intro: data.intro,
        introRef: data.introRef,
        ref: data.ref,
        content: data.content,
      );
    }).toList();
  }

  /// Construit le menu de sélection des messes
  static Widget _buildMassMenu({
    required BuildContext context,
    required Map? aelfJson,
    TabController? tabController,
    List<int>? massPositions,
    required int currentMenuIndex,
  }) {
    if (aelfJson == null || !aelfJson.containsKey("messes")) {
      return const Center(child: Text("Erreur: données non disponibles"));
    }

    final masses = aelfJson["messes"];

    // Vérifier que masses est bien une List
    if (masses is! List) {
      return const Center(child: Text("Erreur: format de données invalide"));
    }

    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.only(top: 100),
          alignment: Alignment.center,
          child: Column(
            children: List.generate(masses.length, (index) {
              // Déterminer si c'est la messe actuellement sélectionnée
              final bool isSelected = index == currentMenuIndex;
              return GestureDetector(
                onTap: tabController != null &&
                        massPositions != null &&
                        index < massPositions.length
                    ? () {
                        // Naviguer vers la messe sélectionnée
                        tabController.animateTo(massPositions[index]);
                      }
                    : null,
                child: _buildMassMenuItem(
                  context: context,
                  massName: masses[index]["nom"] ?? "Messe ${index + 1}",
                  isSelected: isSelected,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Construit un élément du menu des messes
  static Widget _buildMassMenuItem({
    required BuildContext context,
    required String massName,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.all(30.0),
      padding: const EdgeInsets.all(10.0),
      alignment: Alignment.topCenter,
      width: MediaQuery.of(context).size.width - 40,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
        ),
        color: isSelected ? Theme.of(context).colorScheme.secondary : null,
      ),
      child: Text(
        massName,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).scaffoldBackgroundColor
              : Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 20,
        ),
      ),
    );
  }

  /// Construit l'onglet d'informations avec gestion du zoom
  static Widget _buildInformationTab(
      BuildContext context, LiturgyTabData data) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 600,
        padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 25),
        child: Consumer<CurrentZoom>(
          builder: (context, currentZoom, child) => Text(
            data.content,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18 * (currentZoom.value ?? 100) / 100),
          ),
        ),
      ),
    );
  }
}
