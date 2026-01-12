import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/office_view_compline.dart';
import 'package:aelf_flutter/widgets/office_view_morning.dart';
import 'package:aelf_flutter/widgets/office_view_readings.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/utils/flutter_data_loader.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/tools/data_loader.dart';

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
    dataLoader = FlutterDataLoader();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LiturgyState>(builder: (context, liturgyState, child) {
      switch (liturgyState.liturgyType) {
        case "complies_new":
          final complineDefinitions = liturgyState.offlineComplines;
          return ComplineViewUnified(
            complineDefinitionsList: complineDefinitions,
            dataLoader: dataLoader,
            calendar: liturgyState.offlineCalendar,
            date: DateTime.parse(liturgyState.date),
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

          final morningDefinition = liturgyState.offlineMorning;

          return MorningViewUnified(
            morningList: morningDefinition,
            date: DateTime.parse(liturgyState.date),
            dataLoader: dataLoader,
          );

        case "offline_readings":
          print('Loading offline readings prayer');

          if (liturgyState.offlineReadings.isEmpty) {
            print('offlineReadings is empty - loading...');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading readings office...'),
                ],
              ),
            );
          }

          // Using the unified office architecture
          return ReadingsViewUnified(
            readingsDefinitions: liturgyState.offlineReadings,
            date: DateTime.parse(liturgyState.date),
            dataLoader: dataLoader,
          );

        default:
          return Center(child: LiturgyFormatter());
      }
    });
  }
}
