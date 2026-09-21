import 'package:aelf_flutter/app_screens/liturgy_formatter.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_calendar_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_compline_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_mass_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_morning_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_readings_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_tierce_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_sexte_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_none_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_vespers_view.dart';
import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:provider/provider.dart';

/// Loading spinner for an offline_* office, or an error + retry button if
/// the underlying fetch in LiturgyState.updateLiturgy() failed. Without this,
/// a failed fetch leaves the office Map empty forever and looks identical to
/// "still loading" — see offlineLoadError in LiturgyState.
Widget _offlineOfficeLoading(LiturgyState liturgyState, String loadingLabel) {
  if (liturgyState.offlineLoadError != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
              '${liturgyLabels['error-office']!} : ${liturgyState.offlineLoadError}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: liturgyState.updateLiturgy,
            child: Text(liturgyLabels['retry']!),
          ),
        ],
      ),
    );
  }
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(loadingLabel),
      ],
    ),
  );
}

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
        case "offline_calendar":
          return const LiturgicalCalendarView();

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
            return _offlineOfficeLoading(
                liturgyState, 'Loading morning office...');
          }

          final morningDefinition = liturgyState.offlineMorning;

          return MorningView(
            morningList: morningDefinition,
            date: DateTime.parse(liturgyState.date),
            calendar: liturgyState.offlineCalendar,
          );

        case "offline_readings":
          print('Loading offline readings prayer');

          if (liturgyState.offlineReadings.isEmpty) {
            print('offlineReadings is empty - loading...');
            return _offlineOfficeLoading(
                liturgyState, 'Loading readings office...');
          }

          // For now, show a simple view with the readings definitions list
          // TODO: Create ReadingsOfficeService and full ReadingsView implementation
          return ReadingsView(
            readingsDefinitions: liturgyState.offlineReadings,
            date: DateTime.parse(liturgyState.date),
            calendar: liturgyState.offlineCalendar,
          );

        case "offline_tierce":
          if (liturgyState.offlineMiddleOfDay.isEmpty) {
            return _offlineOfficeLoading(
                liturgyState, 'Loading tierce office...');
          }
          return TierceView(
            middleOfDayList: liturgyState.offlineMiddleOfDay,
            date: DateTime.parse(liturgyState.date),
            calendar: liturgyState.offlineCalendar,
          );

        case "offline_sexte":
          if (liturgyState.offlineMiddleOfDay.isEmpty) {
            return _offlineOfficeLoading(
                liturgyState, 'Loading sexte office...');
          }
          return SexteView(
            middleOfDayList: liturgyState.offlineMiddleOfDay,
            date: DateTime.parse(liturgyState.date),
            calendar: liturgyState.offlineCalendar,
          );

        case "offline_none":
          if (liturgyState.offlineMiddleOfDay.isEmpty) {
            return _offlineOfficeLoading(
                liturgyState, 'Loading none office...');
          }
          return NoneView(
            middleOfDayList: liturgyState.offlineMiddleOfDay,
            date: DateTime.parse(liturgyState.date),
            calendar: liturgyState.offlineCalendar,
          );

        case "offline_vespers":
          if (liturgyState.offlineVespers.isEmpty) {
            print('offlineVespers is empty - loading...');
            return _offlineOfficeLoading(
                liturgyState, 'Loading vespers office...');
          }

          return VespersView(
            vespersList: liturgyState.offlineVespers,
            date: DateTime.parse(liturgyState.date),
            calendar: liturgyState.offlineCalendar,
          );

        case "offline_mass":
          if (liturgyState.offlineMass.isEmpty) {
            print('offlineMass is empty - loading...');
            return _offlineOfficeLoading(liturgyState, 'Loading mass...');
          }

          return MassView(
            massList: liturgyState.offlineMass,
            date: DateTime.parse(liturgyState.date),
            calendar: liturgyState.offlineCalendar,
          );

        default:
          return Center(child: LiturgyFormatter());
      }
    });
  }
}
