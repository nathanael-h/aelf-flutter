import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_compline_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_morning_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_readings_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_tierce_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_sexte_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_none_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_vespers_view.dart';
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
  Widget build(BuildContext context) {
    return Consumer<LiturgyState>(builder: (context, liturgyState, child) {
      switch (liturgyState.liturgyType) {
        case "offline_complines":
          final complineDefinitions = liturgyState.offlineComplines;
          return ComplineView(
            complineDefinitionsList: complineDefinitions,
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

          return MorningView(
            morningList: morningDefinition,
            date: DateTime.parse(liturgyState.date),
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

          // For now, show a simple view with the readings definitions list
          // TODO: Create ReadingsOfficeService and full ReadingsView implementation
          return ReadingsView(
            readingsDefinitions: liturgyState.offlineReadings,
            date: DateTime.parse(liturgyState.date),
          );

        case "offline_tierce":
          if (liturgyState.offlineMiddleOfDay.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading tierce office...'),
                ],
              ),
            );
          }
          return TierceView(
            middleOfDayList: liturgyState.offlineMiddleOfDay,
            date: DateTime.parse(liturgyState.date),
          );

        case "offline_sexte":
          if (liturgyState.offlineMiddleOfDay.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading sexte office...'),
                ],
              ),
            );
          }
          return SexteView(
            middleOfDayList: liturgyState.offlineMiddleOfDay,
            date: DateTime.parse(liturgyState.date),
          );

        case "offline_none":
          if (liturgyState.offlineMiddleOfDay.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading none office...'),
                ],
              ),
            );
          }
          return NoneView(
            middleOfDayList: liturgyState.offlineMiddleOfDay,
            date: DateTime.parse(liturgyState.date),
          );

        case "offline_vespers":
          print('Loading offline vespers prayer');

          if (liturgyState.offlineVespers.isEmpty) {
            print('offlineVespers is empty - loading...');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading vespers office...'),
                ],
              ),
            );
          }

          return VespersView(
            vespersList: liturgyState.offlineVespers,
            date: DateTime.parse(liturgyState.date),
          );

        default:
          return Center(child: LiturgyFormatter());
      }
    });
  }
}
