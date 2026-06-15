import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/flutter_data_loader.dart';
import 'package:aelf_flutter/widgets/pinch_zoom_area.dart';

class LiturgicalCalendarView extends StatefulWidget {
  const LiturgicalCalendarView({super.key});

  @override
  State<LiturgicalCalendarView> createState() => _LiturgicalCalendarViewState();
}

class _LiturgicalCalendarViewState extends State<LiturgicalCalendarView> {
  int _depthIndex = 0;
  bool _showSundays = false;
  late int _anchorYear;
  Calendar? _calendar;
  Map<String, _FeastInfo> _feastNames = {};
  String _locationLabel = '';
  bool _calendarLoading = true;
  bool _namesLoading = true;

  late LiturgyState _liturgyState;

  // Track which state was used to build the current calendar.
  String? _lastRegion;
  String? _lastEpiphanyOverride;
  String? _lastAscensionOverride;
  String? _lastCorpusDominiOverride;

  // _allCelebrationsCache: full sorted list, invalidated on calendar/feastNames change.
  // _renderListCache: depth-filtered grouped list, invalidated also on depth change.
  List<_Celebration>? _allCelebrationsCache;
  List<_RenderItem>? _renderListCache;
  _SeasonBoundaries? _seasons;

  // Parsed once per app session; subsequent navigations reuse it instantly.
  static Map<String, _FeastInfo>? _feastNamesCache;

  static const _depthShortLabels = [
    'SOLENNITÉS',
    'Fêtes',
    'Mém. obl.',
    'Mém. fac.',
  ];
  // prec 1-4 = solemnities, prec 5-8 = feasts, prec 10-11 = obligatory memorials, prec 12 = optional memorials.
  static const _depthMaxPrec = [4, 8, 11, 12];

  int get _maxPrecedence => _depthMaxPrec[_depthIndex];

  static const _months = [
    '',
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.'
  ];
  static const _weekdays = [
    '',
    'lun.',
    'mar.',
    'mer.',
    'jeu.',
    'ven.',
    'sam.',
    'dim.'
  ];

  @override
  void initState() {
    super.initState();
    final ls = context.read<LiturgyState>();
    _liturgyState = ls;
    _lastRegion = ls.offlineRegion;
    _lastEpiphanyOverride = ls.epiphanyDateOverride;
    _lastAscensionOverride = ls.ascensionDateOverride;
    _lastCorpusDominiOverride = ls.corpusDominiDateOverride;
    ls.addListener(_onLiturgyStateChanged);
    _anchorYear = _computeInitialAnchorYear(ls);
    _loadLocation(ls);
    _loadCalendar(ls);
    _loadFeastNames();
  }

  @override
  void dispose() {
    _liturgyState.removeListener(_onLiturgyStateChanged);
    super.dispose();
  }

  void _onLiturgyStateChanged() {
    if (!mounted) return;
    final ls = context.read<LiturgyState>();
    if (ls.offlineRegion == _lastRegion &&
        ls.epiphanyDateOverride == _lastEpiphanyOverride &&
        ls.ascensionDateOverride == _lastAscensionOverride &&
        ls.corpusDominiDateOverride == _lastCorpusDominiOverride) {
      return;
    }
    _lastRegion = ls.offlineRegion;
    _lastEpiphanyOverride = ls.epiphanyDateOverride;
    _lastAscensionOverride = ls.ascensionDateOverride;
    _lastCorpusDominiOverride = ls.corpusDominiDateOverride;
    _loadLocation(ls);
    _loadCalendar(ls);
  }

  int _computeInitialAnchorYear(LiturgyState ls) {
    final now = DateTime.now();
    final content = ls.offlineCalendar.getDayContent(now);
    if (content != null) return content.liturgicalYear;
    if (now.month == 12) return now.year + 1;
    if (now.month == 11 && now.day >= 27) return now.year + 1;
    return now.year;
  }

  Future<void> _loadLocation(LiturgyState ls) async {
    final label = await ls.locationDisplayLabel;
    if (mounted) setState(() => _locationLabel = label);
  }

  Future<void> _loadCalendar(LiturgyState ls) async {
    if (!mounted) return;
    setState(() => _calendarLoading = true);
    final requested = _anchorYear;
    final cal = await ls.buildCalendarForYear(_anchorYear);
    if (!mounted || requested != _anchorYear) return;
    if (mounted) {
      setState(() {
        _calendar = cal;
        _calendarLoading = false;
        _seasons = _computeSeasonBoundaries();
        _invalidateAll();
      });
    }
  }

  Future<void> _loadFeastNames() async {
    if (_feastNamesCache != null) {
      if (mounted) {
        setState(() {
          _feastNames = _feastNamesCache!;
          _namesLoading = false;
          _invalidateAll();
        });
      }
      return;
    }

    final raw = await FlutterDataLoader().loadJson('calendar_data/index.json');
    final map = <String, _FeastInfo>{};
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in decoded.entries) {
        final v = e.value as Map<String, dynamic>;
        final title = v['title'] as String?;
        if (title == null || title.isEmpty) continue;
        map[e.key] = _FeastInfo(title, v['color'] as String?);
      }
    }

    _feastNamesCache = map;
    if (mounted) {
      setState(() {
        _feastNames = map;
        _namesLoading = false;
        _invalidateAll();
      });
    }
  }

  void _invalidateAll() {
    _allCelebrationsCache = null;
    _renderListCache = null;
  }

  void _invalidateRenderList() {
    _renderListCache = null;
  }

  void _changeYear(int delta) {
    _anchorYear += delta;
    _loadCalendar(context.read<LiturgyState>());
  }

  _FeastInfo? _lookupFeast(String key) {
    final info = _feastNames[key];
    if (info != null) return info;
    // For special Advent days (advent-Z_week_day, Dec 17-24), look up the
    // underlying ferial week code advent_week_day (e.g. advent-20_3_0 → advent_3_0).
    if (key.startsWith('advent-')) {
      final parts = key.replaceFirst('advent-', '').split('_');
      if (parts.length == 3) {
        final ferialInfo = _feastNames['advent_${parts[1]}_${parts[2]}'];
        if (ferialInfo != null) return ferialInfo;
      }
    }
    final parts = key.split('_');
    for (int i = 1; i < parts.length; i++) {
      final suffix = parts.sublist(i).join('_');
      final suffixInfo = _feastNames[suffix];
      if (suffixInfo != null) return suffixInfo;
    }
    return null;
  }

  String _displayName(String key) {
    final info = _lookupFeast(key);
    if (info != null) return info.title;
    return key
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // Ferial codes that must not appear even when their precedence passes the prec filter.
  bool _isExcludedFerialCode(String code) {
    // First Sunday of Advent is always shown (start of liturgical year).
    if (code == 'advent_1_0') return false;
    // Palm Sunday is always shown (start of Holy Week).
    if (code == 'lent_6_0') return false;
    // Regular Advent Sundays (advent_N_0).
    if (code.startsWith('advent_') && code.endsWith('_0')) return true;
    // Dec 17–24 codes use a hyphen format (advent-NN_week_day); exclude all of them.
    if (code.startsWith('advent-')) return true;
    // Lent Sundays.
    if (code.startsWith('lent_') && code.endsWith('_0')) return true;
    // Easter octave weekdays (easter_1_1–6) and Easter time Sundays; keep Easter Sunday.
    if (code.startsWith('easter_') && code != 'easter_1_0') {
      if (code.startsWith('easter_1_')) return true;
      if (code.endsWith('_0')) return true;
    }
    return false;
  }

  // Full calendar iteration — cached per calendar+feastNames, depth-independent.
  List<_Celebration> _buildAllCelebrations() {
    if (_calendar == null) return [];
    final start = DateTime(_anchorYear - 1, 11, 24);
    final end = DateTime(_anchorYear, 11, 29);

    final list = <_Celebration>[];

    for (final e in _calendar!.calendarData.entries) {
      final date = e.key;
      if (date.isBefore(start) || date.isAfter(end)) continue;

      final day = e.value;

      if (!const {6, 9, 13}.contains(day.precedence)) {
        final code = day.defaultCelebrationTitle;
        final colorStr = _lookupFeast(code)?.color ?? day.liturgicalColor;
        if (!_isExcludedFerialCode(code)) {
          list.add(_Celebration(date, code, day.precedence, colorStr));
        } else if (date.weekday == DateTime.sunday && ferialDayCheck(code)) {
          // Excluded Sunday of a special season: kept but gated by _showSundays.
          list.add(_Celebration(date, code, day.precedence, colorStr,
              isSundayEntry: true));
        }
      }

      for (final precEntry in day.feastList.entries) {
        final prec = precEntry.key;
        for (final key in precEntry.value) {
          final colorStr = _lookupFeast(key)?.color ?? day.liturgicalColor;
          list.add(_Celebration(date, key, prec, colorStr));
        }
      }

      // Celebrable OT Sundays (prec 6, excluded by the set above):
      // shown only when the default is a ferial code and no solemnity (prec ≤ 3) is present.
      if (date.weekday == DateTime.sunday &&
          day.liturgicalTime == 'ot' &&
          ferialDayCheck(day.defaultCelebrationTitle) &&
          !day.feastList.keys.any((p) => p <= 3)) {
        final code = day.defaultCelebrationTitle;
        final colorStr = _lookupFeast(code)?.color ?? day.liturgicalColor;
        list.add(_Celebration(date, code, day.precedence, colorStr,
            isSundayEntry: true));
      }
    }

    list.sort((a, b) {
      final d = a.date.compareTo(b.date);
      return d != 0 ? d : a.precedence.compareTo(b.precedence);
    });

    return list;
  }

  // Applies depth filter on the cached full list — cheap on depth change.
  List<_Celebration> _buildCelebrationList() {
    final all = _allCelebrationsCache ??= _buildAllCelebrations();
    return all
        .where((c) =>
            (c.isSundayEntry && _showSundays) ||
            (!c.isSundayEntry && c.precedence <= _maxPrecedence))
        .toList();
  }

  // Groups into a flat render list. Input is already date-sorted, so a single
  // pass with a last-date sentinel is enough — no intermediate map needed.
  List<_RenderItem> _buildRenderList() {
    final celebrations = _buildCelebrationList();
    if (celebrations.isEmpty) return [];

    final result = <_RenderItem>[];
    DateTime? lastDate;

    for (final c in celebrations) {
      if (lastDate == null || c.date != lastDate) {
        result.add(_RenderItem.header(c.date));
        lastDate = c.date;
      }
      result.add(_RenderItem.indented(c.date, c));
    }

    return result;
  }

  // FIXME: partial code duplication with ./lib/utils/liturgical_colors.dart getLiturgicalColor()
  Color _liturgicalColor(String colorName) => switch (colorName) {
        'white' => const Color(0xFFF0F0F0),
        'red' => const Color(0xFFC62828),
        'green' => const Color(0xFF2E7D32),
        'purple' || 'violet' => const Color(0xFF6A1B9A),
        'rose' => const Color(0xFFE91E63),
        'black' => const Color(0xFF212121),
        _ => Colors.grey,
      };

  _SeasonBoundaries _computeSeasonBoundaries() {
    if (_calendar == null) return const _SeasonBoundaries();

    bool hasCode(DayContent day, String code) {
      if (day.defaultCelebrationTitle == code) return true;
      for (final keys in day.feastList.values) {
        if (keys.contains(code)) return true;
      }
      return false;
    }

    DateTime? christmas;
    DateTime? baptism;
    DateTime? lent;
    DateTime? easter;
    DateTime? pentecost;
    final adventDates = <DateTime>[];

    for (final e in _calendar!.calendarData.entries) {
      final date = e.key;
      final day = e.value;
      if (hasCode(day, 'advent_1_0')) adventDates.add(date);
      if (christmas == null && hasCode(day, 'roman/nativity')) christmas = date;
      if (baptism == null && hasCode(day, 'roman/baptism')) baptism = date;
      if (lent == null && hasCode(day, 'lent_0_3')) lent = date;
      if (easter == null && hasCode(day, 'easter_1_0')) easter = date;
      if (pentecost == null && hasCode(day, 'roman/pentecost')) {
        pentecost = date;
      }
    }

    adventDates.sort();
    return _SeasonBoundaries(
      advent: adventDates.isNotEmpty ? adventDates.first : null,
      christmas: christmas,
      baptism: baptism,
      lent: lent,
      easter: easter,
      pentecost: pentecost,
      nextAdvent: adventDates.length > 1 ? adventDates.last : null,
    );
  }

  Color _seasonBarColor(DateTime date) {
    final s = _seasons;
    if (s == null) return Colors.transparent;

    if (s.nextAdvent != null && !date.isBefore(s.nextAdvent!)) {
      return _liturgicalColor('purple');
    }
    if (s.pentecost != null &&
        !date.isBefore(s.pentecost!.add(const Duration(days: 1)))) {
      return _liturgicalColor('green');
    }
    if (s.easter != null && !date.isBefore(s.easter!)) {
      return _liturgicalColor('white');
    }
    if (s.lent != null && !date.isBefore(s.lent!)) {
      return _liturgicalColor('purple');
    }
    if (s.baptism != null &&
        !date.isBefore(s.baptism!.add(const Duration(days: 1)))) {
      return _liturgicalColor('green');
    }
    if (s.christmas != null && !date.isBefore(s.christmas!)) {
      return _liturgicalColor('white');
    }
    if (s.advent != null && !date.isBefore(s.advent!)) {
      return _liturgicalColor('purple');
    }
    return Colors.transparent;
  }

  String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday]} ${d.day} ${_months[d.month]} ${d.year}';

  Widget _titleWidget(String name, int prec, BuildContext ctx,
      {bool isSundayEntry = false}) {
    if (prec <= 4) {
      const style = TextStyle(fontSize: 11, fontWeight: FontWeight.bold);
      return Text.rich(
        TextSpan(children: _buildNameSpans(name, style, uppercase: true)),
      );
    }
    if (prec <= 8 || isSundayEntry) {
      const style = TextStyle(fontSize: 11, fontWeight: FontWeight.bold);
      return Text.rich(
        TextSpan(children: _buildNameSpans(name, style)),
      );
    }
    final isOptional = prec > 11;
    final tag = isOptional ? 'mém. fac.' : 'mém. obl.';
    final baseStyle = DefaultTextStyle.of(ctx).style.copyWith(
          fontSize: 11,
          fontStyle: isOptional ? FontStyle.italic : FontStyle.normal,
        );
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          ..._buildNameSpans(name, baseStyle),
          TextSpan(
            text: '  ($tag)',
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(ctx).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorCircle(String colorStr) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _liturgicalColor(colorStr),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
      );

  Widget _buildDateHeader(_RenderItem item, BuildContext ctx) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: _seasonBarColor(item.date), width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 12, bottom: 2),
        child: Text(
          _formatDate(item.date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(ctx).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildIndentedRow(_RenderItem item, BuildContext ctx) {
    final c = item.celebration!;
    final name = _namesLoading ? '…' : _displayName(c.key);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: _seasonBarColor(item.date), width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 16, top: 2, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _colorCircle(c.colorStr),
            ),
            const SizedBox(width: 6),
            Expanded(
                child: _titleWidget(name, c.precedence, ctx,
                    isSundayEntry: c.isSundayEntry)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final renderList = _renderListCache ??= _buildRenderList();

    final theme = Theme.of(context);
    final zoom = context.watch<CurrentZoom>().value;

    return PinchZoomSelectionArea(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(zoom / 100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Text(
                _locationLabel.isEmpty ? '…' : _locationLabel,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ),
            // Year navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeYear(-1),
                  ),
                  Expanded(
                    child: Text(
                      'Année liturgique $_anchorYear',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeYear(1),
                  ),
                ],
              ),
            ),
            // Sunday toggle
            InkWell(
              onTap: () => setState(() {
                _showSundays = !_showSundays;
                _invalidateRenderList();
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    Checkbox(
                      value: _showSundays,
                      onChanged: (v) => setState(() {
                        _showSundays = v ?? false;
                        _invalidateRenderList();
                      }),
                    ),
                    Text(
                      'Afficher les dimanches',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            // Depth slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Slider(
                    value: _depthIndex.toDouble(),
                    min: 0,
                    max: 3,
                    divisions: 3,
                    onChanged: (v) => setState(() {
                      _depthIndex = v.round();
                      _invalidateRenderList();
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (i) {
                      final active = i <= _depthIndex;
                      final activeColor = SliderTheme.of(context).thumbColor;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _depthIndex = i;
                          _invalidateRenderList();
                        }),
                        child: Text(
                          _depthShortLabels[i],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 8,
                            color: active
                                ? activeColor
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight:
                                i <= 1 ? FontWeight.w600 : FontWeight.normal,
                            fontStyle:
                                i == 3 ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const Divider(height: 1),
            // Celebration list
            Expanded(
              child: _calendarLoading
                  ? const Center(child: CircularProgressIndicator())
                  : renderList.isEmpty
                      ? const Center(child: Text('Aucune fête à afficher'))
                      : SelectionContainer.disabled(
                          child: ListView.builder(
                            itemCount: renderList.length,
                            itemBuilder: (ctx, i) {
                              final item = renderList[i];
                              if (item.isHeader) {
                                return _buildDateHeader(item, ctx);
                              }
                              return _buildIndentedRow(item, ctx);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

List<InlineSpan> _buildNameSpans(String raw, TextStyle style,
    {bool uppercase = false}) {
  if (!raw.contains('^')) {
    return [TextSpan(text: uppercase ? raw.toUpperCase() : raw, style: style)];
  }
  final regex = RegExp(r'\^([a-zA-ZéèêâàîïôûùÉÈÊÂÀÎÏÔÛÙ0-9]+)');
  final spans = <InlineSpan>[];
  int last = 0;
  for (final m in regex.allMatches(raw)) {
    if (m.start > last) {
      final t = raw.substring(last, m.start);
      spans.add(TextSpan(text: uppercase ? t.toUpperCase() : t, style: style));
    }
    spans.add(WidgetSpan(
      alignment: PlaceholderAlignment.top,
      child: Transform.translate(
        offset: Offset(0, -(style.fontSize ?? 11.0) * 0.2),
        child: Text(
          m.group(1)!.toLowerCase(),
          textWidthBasis: TextWidthBasis.longestLine,
          style: style.copyWith(
            fontSize: (style.fontSize ?? 11.0) * 0.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ));
    last = m.end;
  }
  if (last < raw.length) {
    final t = raw.substring(last);
    spans.add(TextSpan(text: uppercase ? t.toUpperCase() : t, style: style));
  }
  return spans;
}

class _Celebration {
  final DateTime date;
  final String key;
  final int precedence;
  final String colorStr;
  final bool isSundayEntry;

  const _Celebration(this.date, this.key, this.precedence, this.colorStr,
      {this.isSundayEntry = false});
}

class _RenderItem {
  final DateTime date;
  final _Celebration? celebration;

  _RenderItem.header(this.date) : celebration = null;
  _RenderItem.indented(this.date, this.celebration);

  bool get isHeader => celebration == null;
}

class _FeastInfo {
  final String title;
  final String? color;
  const _FeastInfo(this.title, [this.color]);
}

class _SeasonBoundaries {
  final DateTime? advent;
  final DateTime? christmas;
  final DateTime? baptism;
  final DateTime? lent;
  final DateTime? easter;
  final DateTime? pentecost;
  final DateTime? nextAdvent;

  const _SeasonBoundaries({
    this.advent,
    this.christmas,
    this.baptism,
    this.lent,
    this.easter,
    this.pentecost,
    this.nextAdvent,
  });
}
