import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgical_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

DayContent _day(String color) => DayContent(
      liturgicalYear: 2026,
      liturgicalTime: 'ot',
      defaultCelebrationTitle: 'test',
      precedence: 13,
      liturgicalColor: color,
      breviaryWeek: null,
    );

/// A fixed March 2026 calendar: the 4th is violet, the 8th white, the 12th
/// green — enough to check the dot shown for each without touching the real
/// offline_liturgy calendar computation.
Calendar _fixtureCalendar() {
  final calendar = Calendar();
  calendar.addDayContent(DateTime(2026, 3, 4), _day('violet'));
  calendar.addDayContent(DateTime(2026, 3, 8), _day('white'));
  calendar.addDayContent(DateTime(2026, 3, 12), _day('green'));
  return calendar;
}

void main() {
  for (final (name, theme) in [('day', light), ('night', dark)]) {
    testWidgets('shows the right liturgical color dot ($name theme)',
        (tester) async {
      final calendar = _fixtureCalendar();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: LiturgicalDatePicker(
            initialDate: DateTime(2026, 3, 1),
            firstDate: DateTime(2016),
            lastDate: DateTime(2101),
            onDateChanged: (_) {},
            buildCalendarForYear: (year) async => calendar,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final liturgicalColors =
          AelfLiturgicalColors.of(theme);

      Color dotColorOn(DateTime date) {
        final key = ValueKey('liturgical-dot-${date.toIso8601String()}');
        final container = tester.widget<Container>(find.byKey(key));
        return (container.decoration as BoxDecoration).color!;
      }

      expect(dotColorOn(DateTime(2026, 3, 4)),
          liturgicalColors.resolve('violet'));
      expect(dotColorOn(DateTime(2026, 3, 8)),
          liturgicalColors.resolve('white'));
      expect(dotColorOn(DateTime(2026, 3, 12)),
          liturgicalColors.resolve('green'));

      // No fixture data for the 20th: no dot should be rendered.
      expect(
          find.byKey(ValueKey(
              'liturgical-dot-${DateTime(2026, 3, 20).toIso8601String()}')),
          findsNothing);
    });
  }

  testWidgets('tapping a day calls onDateChanged with that date',
      (tester) async {
    DateTime? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LiturgicalDatePicker(
          initialDate: DateTime(2026, 3, 1),
          firstDate: DateTime(2016),
          lastDate: DateTime(2101),
          onDateChanged: (d) => picked = d,
          buildCalendarForYear: (year) async => Calendar(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(
        ValueKey('liturgical-day-${DateTime(2026, 3, 12).toIso8601String()}')));
    await tester.pump();

    expect(picked, DateTime(2026, 3, 12));
  });

  testWidgets('month navigation is disabled past firstDate/lastDate',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LiturgicalDatePicker(
          initialDate: DateTime(2026, 3, 1),
          firstDate: DateTime(2026, 3, 1),
          lastDate: DateTime(2026, 3, 31),
          onDateChanged: (_) {},
          buildCalendarForYear: (year) async => Calendar(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final prevButton =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left));
    final nextButton =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right));

    expect(prevButton.onPressed, isNull);
    expect(nextButton.onPressed, isNull);
  });
}
