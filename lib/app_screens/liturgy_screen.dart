import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_compline_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_morning_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/tools/data_loader.dart';

// Flutter implementation of DataLoader for local packages
class FlutterAssetDataLoader implements DataLoader {
  @override
  Future<String> loadJson(String relativePath) async {
    // For local packages, Flutter requires the 'packages/' prefix
    final paths = [
      'packages/offline_liturgy/assets/$relativePath',
      'assets/$relativePath',
    ];

    for (final path in paths) {
      try {
        final content = await rootBundle.loadString(path);
        print('✅ Successfully loaded from: $path');
        return content;
      } catch (e) {
        print('❌ Failed to load from: $path');
      }
    }

    print('ERROR: Could not load $relativePath from any path');
    return '';
  }
}

class LiturgyScreen extends StatefulWidget {
  LiturgyScreen() : super();

  static const routeName = '/liturgyScreen';

  @override
  LiturgyScreenState createState() => LiturgyScreenState();
}

class LiturgyScreenState extends State<LiturgyScreen>
    with TickerProviderStateMixin {
  late final DataLoader dataLoader;

  @override
  void initState() {
    super.initState();
    dataLoader = FlutterAssetDataLoader();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LiturgyState>(builder: (context, liturgyState, child) {
      switch (liturgyState.liturgyType) {
        case "complies_new":
          final complineDefinitions = liturgyState.offlineComplines;
          return ComplineView(
            complineDefinitionsList: complineDefinitions,
            dataLoader: dataLoader,
          );

        case "offline_morning":
          print('Loading offline morning prayer');

          if (liturgyState.offlineMorning.isEmpty) {
            print('offlineMorning is empty - loading...');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading morning office...'),
                ],
              ),
            );
          }

          final morningEntry = liturgyState.offlineMorning.entries.first;
          final morning = morningEntry.value;
          final celebrationName = morningEntry.key;

          print('=== DEBUG MORNING ===');
          print('Celebration: $celebrationName');
          print('Has hymn: ${morning.hymn != null}');
          print('Has psalmody: ${morning.psalmody != null}');
          print('=== END DEBUG ===');

          return MorningView(
            morning: morning,
            dataLoader: dataLoader,
          );

        default:
          return Center(child: LiturgyFormatter());
      }
    });
  }
}
