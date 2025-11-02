import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_compline_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_morning_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiturgyScreen extends StatefulWidget {
  LiturgyScreen() : super();

  static const routeName = '/liturgyScreen';

  @override
  LiturgyScreenState createState() => LiturgyScreenState();
}

class LiturgyScreenState extends State<LiturgyScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LiturgyState>(builder: (context, liturgyState, child) {
      switch (liturgyState.liturgyType) {
        case "complies_new":
          final complineDefinitions = liturgyState.offlineComplines;
          return ComplineView(complineDefinitionsList: complineDefinitions);

        case "offline_morning":
          print('on est dans les Laudes offline');

          // Vérifier si offlineMorning contient des données
          if (liturgyState.offlineMorning.isEmpty) {
            print('offlineMorning est vide - chargement en cours...');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de l\'office du matin...'),
                ],
              ),
            );
          }

          // Récupérer le premier Morning
          final morningEntry = liturgyState.offlineMorning.entries.first;
          final morning = morningEntry.value;
          final celebrationName = morningEntry.key;

          // Debug : afficher les informations détaillées
          print('=== DEBUG MORNING ===');
          print('Célébration: $celebrationName');
          print('Morning object: $morning');
          print('Has celebration: ${morning.celebration != null}');
          print('Has invitatory: ${morning.invitatory != null}');
          print('Has hymn: ${morning.hymn != null}');
          print('Hymn: ${morning.hymn}');
          print('Has psalmody: ${morning.psalmody != null}');
          print('Psalmody length: ${morning.psalmody?.length ?? 0}');
          print('Has reading: ${morning.reading != null}');
          print('Has responsory: ${morning.responsory != null}');
          print('Has evangelicAntiphon: ${morning.evangelicAntiphon != null}');
          print('Has intercession: ${morning.intercession != null}');
          print('Has oration: ${morning.oration != null}');
          print('Oration content: ${morning.oration}');
          print('=== END DEBUG ===');

          return morningView(morning: morning);

        default:
          return Center(child: LiturgyFormatter());
      }
    });
  }
}
