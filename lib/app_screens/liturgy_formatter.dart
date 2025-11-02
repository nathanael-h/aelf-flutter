import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/text_management.dart';

import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/liturgy_tabs_view.dart';
import 'package:aelf_flutter/parsers/liturgy_parser_service.dart';
import 'package:aelf_flutter/app_screens/liturgy_widget_builder.dart';

/// Widget principal pour formatter et afficher la liturgie
///
/// Cette version refactorisée délègue le parsing à des services spécialisés
/// et la construction des widgets à des builders dédiés.
class LiturgyFormatter extends StatefulWidget {
  const LiturgyFormatter({Key? key}) : super(key: key);

  @override
  LiturgyFormatterState createState() => LiturgyFormatterState();
}

class LiturgyFormatterState extends State<LiturgyFormatter>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _buildCount = 0;

  /// Retourne l'index actuel du TabController de manière sûre
  int get _currentIndex => _tabController?.index ?? 0;

  @override
  void initState() {
    super.initState();
    _initializeTabController(length: 1, index: 0);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    log("TabController disposed");
    super.dispose();
  }

  /// Initialise le TabController avec les paramètres donnés
  void _initializeTabController({required int length, int? index}) {
    _tabController?.dispose();
    _tabController = TabController(
      vsync: this,
      length: length,
      initialIndex: index ?? 0,
    );
  }

  /// Prépare les données des onglets à partir du JSON
  Map<String, dynamic> _prepareTabsData(Map? aelfJson) {
    // Parser les données
    final parseResult = LiturgyParserService.parse(aelfJson);

    // Déterminer l'index initial (ne pas dépasser la longueur)
    final int initialIndex =
        _currentIndex < parseResult.length ? _currentIndex : 0;

    // Créer le TabController
    _initializeTabController(
      length: parseResult.length,
      index: initialIndex,
    );

    // Construire les widgets
    final List<Widget> tabChildren = LiturgyWidgetBuilder.buildTabChildren(
      context: context,
      tabData: parseResult.tabData,
      originalJson: aelfJson,
      tabController: _tabController,
      massPositions: parseResult.massPositions,
    );

    return {
      '_tabMenuTitles': parseResult.tabTitles,
      '_tabChildren': tabChildren,
      '_tabController': _tabController,
    };
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    log("Building LiturgyFormatter (build #$_buildCount)");

    return Consumer<LiturgyState>(
      builder: (context, liturgyState, child) {
        log("Displaying liturgy: ${liturgyState.date} "
            "${liturgyState.liturgyType} ${liturgyState.region}");

        final tabsMap = _prepareTabsData(liturgyState.aelfJson);

        return Scaffold(
          body: LiturgyTabsView(tabsMap: tabsMap),
        );
      },
    );
  }
}

/// Constante pour la taille de police des versets
const double verseFontSize = 16;
