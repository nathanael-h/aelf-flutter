import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/utils/flutter_data_loader.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';

/// Drop-in replacement for [CalendarDatePicker] with the same
/// [initialDate]/[firstDate]/[lastDate]/[onDateChanged] contract, plus a
/// small dot under each day showing that day's liturgical color.
///
/// [buildCalendarForYear] is [LiturgyState.buildCalendarForYear] in
/// practice — injected rather than read from a `Provider` so this widget
/// stays easy to test on its own. [loadFeastColors] is injected for the same
/// reason: its default reads a real asset, which a widget test's fake-async
/// zone cannot reliably await (platform-channel I/O only completes under
/// [WidgetTester.runAsync]'s real zone) — a test instead passes its own,
/// synchronous map.
class LiturgicalDatePicker extends StatefulWidget {
  const LiturgicalDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    required this.buildCalendarForYear,
    this.loadFeastColors = _defaultLoadFeastColors,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;
  final Future<Calendar> Function(int year) buildCalendarForYear;

  /// The actually-celebrated feast on a day can carry its own liturgical
  /// colour, different from the day's root/season one — e.g. the
  /// Immaculate Conception (white) during Advent (violet). This gives that
  /// per-feast colour, by code, straight from the same precomputed
  /// `index.json` the drawer's calendar list already reads for its own
  /// colour dots.
  final Future<Map<String, String?>> Function() loadFeastColors;

  // Parsed once per app session — no need to re-read/re-parse the index
  // every time the date picker is opened.
  static Map<String, String?>? _feastColorsCache;

  static Future<Map<String, String?>> _defaultLoadFeastColors() async {
    final cached = _feastColorsCache;
    if (cached != null) return cached;

    final raw = await FlutterDataLoader().loadJson('calendar_data/index.json');
    final map = <String, String?>{};
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in decoded.entries) {
        map[e.key] = (e.value as Map<String, dynamic>)['color'] as String?;
      }
    }
    return _feastColorsCache = map;
  }

  @override
  State<LiturgicalDatePicker> createState() => _LiturgicalDatePickerState();
}

class _LiturgicalDatePickerState extends State<LiturgicalDatePicker> {
  late DateTime _selected;
  late DateTime _visibleMonth; // always day 1 of the shown month

  Calendar? _calendar;
  int? _calendarYear;
  bool _loading = false;

  // Populated from widget.loadFeastColors() — see LiturgicalDatePicker's
  // own doc comment.
  Map<String, String?>? _feastColors;

  static const _weekdays = [
    'lun.',
    'mar.',
    'mer.',
    'jeu.',
    'ven.',
    'sam.',
    'dim.'
  ];
  static const _months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _ensureCalendar(_visibleMonth);
    _ensureFeastColors();
  }

  Future<void> _ensureFeastColors() async {
    final map = await widget.loadFeastColors();
    if (mounted) setState(() => _feastColors = map);
  }

  /// [key]'s own colour from the index, or null when it has none or isn't
  /// indexed — falling back, like the drawer's calendar list does, through
  /// the special Advent days (`advent-20_3_0` → `advent_3_0`) and through a
  /// location-prefixed key's suffixes (`france/joan_of_arc` → `joan_of_arc`).
  String? _indexedColor(String key) {
    final colors = _feastColors;
    if (colors == null) return null;
    if (colors.containsKey(key)) return colors[key];
    if (key.startsWith('advent-')) {
      final parts = key.replaceFirst('advent-', '').split('_');
      if (parts.length == 3) {
        final ferialKey = 'advent_${parts[1]}_${parts[2]}';
        if (colors.containsKey(ferialKey)) return colors[ferialKey];
      }
    }
    final parts = key.split('_');
    for (int i = 1; i < parts.length; i++) {
      final suffix = parts.sublist(i).join('_');
      if (colors.containsKey(suffix)) return colors[suffix];
    }
    return null;
  }

  /// Precedence 1-4 (Triduum, major days, solemnities — see CLAUDE.md's
  /// precedence table): the only rank for which the dot shows the
  /// celebration's own colour instead of the day's liturgical-time one. A
  /// feast or memorial added on top of a ferial/Sunday root never changes
  /// the dot, even when it does win the office/Mass for that day.
  static const _solemnityMaxPrecedence = 4;

  /// The colour dot's colour for [day]: a solemnity's own colour (e.g.
  /// white for the Immaculate Conception during violet Advent) when one is
  /// added on top of the day — any lesser feast or memorial leaves the
  /// day's root/season colour showing, as does a plain Sunday or ferial day.
  String? _colorFor(DayContent day) {
    if (day.feastList.isEmpty) return day.liturgicalColor;
    final bestFeastPrecedence = day.feastList.keys.reduce(min);
    final isSolemnity = bestFeastPrecedence <= _solemnityMaxPrecedence &&
        bestFeastPrecedence <= day.precedence;
    if (!isSolemnity) return day.liturgicalColor;
    final code = day.feastList[bestFeastPrecedence]!.first;
    return _indexedColor(code) ?? day.liturgicalColor;
  }

  @override
  void didUpdateWidget(LiturgicalDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selected = widget.initialDate;
      _visibleMonth =
          DateTime(widget.initialDate.year, widget.initialDate.month);
      _ensureCalendar(_visibleMonth);
    }
  }

  // Mirrors LiturgicalCalendarView._computeInitialAnchorYear: a liturgical
  // year built via buildCalendarForYear(year) runs from Advent of (year-1)
  // to the Saturday after Christ the King in (year), so late-November/
  // December dates belong to the *next* liturgical year.
  int _anchorYearFor(DateTime date) {
    if (date.month == 12) return date.year + 1;
    if (date.month == 11 && date.day >= 27) return date.year + 1;
    return date.year;
  }

  Future<void> _ensureCalendar(DateTime month) async {
    final probe = DateTime(month.year, month.month, 15);
    if (_calendar?.getDayContent(probe) != null) return;

    final year = _anchorYearFor(probe);
    if (_calendarYear == year && _calendar != null) return;

    setState(() => _loading = true);
    final cal = await widget.buildCalendarForYear(year);
    if (!mounted) return;
    setState(() {
      _calendar = cal;
      _calendarYear = year;
      _loading = false;
    });
  }

  static int _monthIndex(DateTime d) => d.year * 12 + d.month;

  bool get _canGoPrev =>
      _monthIndex(_visibleMonth) > _monthIndex(widget.firstDate);
  bool get _canGoNext =>
      _monthIndex(_visibleMonth) < _monthIndex(widget.lastDate);

  void _changeMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    if (_monthIndex(next) < _monthIndex(widget.firstDate) ||
        _monthIndex(next) > _monthIndex(widget.lastDate)) {
      return;
    }
    setState(() => _visibleMonth = next);
    _ensureCalendar(next);
  }

  void _selectDay(DateTime day) {
    setState(() => _selected = day);
    widget.onDateChanged(day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final liturgicalColors = AelfLiturgicalColors.of(theme);
    final now = DateTime.now();

    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = (_visibleMonth.weekday - DateTime.monday) % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    Widget dayCell(int dayOfMonth) {
      final date =
          DateTime(_visibleMonth.year, _visibleMonth.month, dayOfMonth);
      final outOfRange =
          date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);
      final isSelected = _isSameDay(date, _selected);
      final isToday = _isSameDay(date, now);
      final dayContent = _calendar?.getDayContent(date);
      final colorName = dayContent == null ? null : _colorFor(dayContent);

      final numberStyle = TextStyle(
        color: outOfRange
            ? colorScheme.onSurface.withValues(alpha: 0.38)
            : isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
      );

      return Expanded(
        child: InkResponse(
          key: ValueKey('liturgical-day-${date.toIso8601String()}'),
          onTap: outOfRange ? null : () => _selectDay(date),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colorScheme.primary : null,
                  border: isToday && !isSelected
                      ? Border.all(color: colorScheme.primary, width: 1)
                      : null,
                ),
                child: Text('$dayOfMonth', style: numberStyle),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 10,
                height: 10,
                child: colorName == null
                    ? null
                    : Container(
                        key: ValueKey(
                            'liturgical-dot-${date.toIso8601String()}'),
                        decoration: BoxDecoration(
                          color: liturgicalColors.resolve(colorName),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.grey.shade400, width: 0.5),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _canGoPrev ? () => _changeMonth(-1) : null,
              ),
              Expanded(
                child: Text(
                  '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _canGoNext ? () => _changeMonth(1) : null,
              ),
            ],
          ),
        ),
        Row(
          children: _weekdays
              .map((w) => Expanded(
                    child: Center(
                      child: Text(w, style: theme.textTheme.bodySmall),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: List.generate(rows, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(7, (col) {
                          final cellIndex = row * 7 + col;
                          final dayOfMonth = cellIndex - leadingBlanks + 1;
                          if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
                            return const Expanded(child: SizedBox.shrink());
                          }
                          return dayCell(dayOfMonth);
                        }),
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }
}
