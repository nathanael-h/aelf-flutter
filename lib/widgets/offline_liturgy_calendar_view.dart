import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yaml/yaml.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/flutter_data_loader.dart';

class LiturgicalCalendarView extends StatefulWidget {
  const LiturgicalCalendarView({super.key});

  @override
  State<LiturgicalCalendarView> createState() => _LiturgicalCalendarViewState();
}

class _LiturgicalCalendarViewState extends State<LiturgicalCalendarView> {
  int _depthIndex = 1;
  late int _anchorYear;
  Calendar? _calendar;
  Map<String, _FeastInfo> _feastNames = {};
  String _locationLabel = '';
  bool _calendarLoading = true;
  bool _namesLoading = true;

  static const _depthLabels = [
    'Solennités',
    'Fêtes',
    'Mémoires obligatoires',
    'Mémoires facultatives',
  ];
  // prec 1-4 = solemnities, prec 5 = feast, prec 10-11 = obligatory memorials, prec 12 = optional memorials.
  static const _depthMaxPrec = [4, 5, 11, 12];

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
    _anchorYear = _computeInitialAnchorYear(ls);
    _loadLocation(ls);
    _loadCalendar(ls);
    _loadFeastNames();
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
    final cal = await ls.buildCalendarForYear(_anchorYear);
    if (mounted) {
      setState(() {
        _calendar = cal;
        _calendarLoading = false;
      });
    }
  }

  Future<void> _loadFeastNames() async {
    final loader = FlutterDataLoader();
    final results = await Future.wait([
      loader.listFiles('calendar_data/sanctoral/'),
      loader.listFiles('calendar_data/special_days/'),
    ]);

    final entries = [
      ...results[0].map((f) =>
          MapEntry('calendar_data/sanctoral/$f', f.replaceAll('.yaml', ''))),
      ...results[1].map((f) =>
          MapEntry('calendar_data/special_days/$f', f.replaceAll('.yaml', ''))),
      // Specific ferial files that have meaningful display names (same celebration structure).
      ...const [
        'advent_1_0', 'lent_0_3', 'lent_6_4', 'lent_6_5', 'lent_6_6', 'easter_1_0',
      ].map((key) => MapEntry('calendar_data/ferial_days/$key.yaml', key)),
    ];

    final contents =
        await Future.wait(entries.map((e) => loader.loadYaml(e.key)));

    final map = <String, _FeastInfo>{};
    for (int i = 0; i < entries.length; i++) {
      final key = entries[i].value;
      final content = contents[i];
      if (content.isEmpty) continue;
      try {
        final yaml = loadYaml(content);
        if (yaml is! Map) continue;
        final celebration = yaml['celebration'];
        if (celebration is! Map) continue;
        final title = celebration['title']?.toString();
        if (title == null || title.isEmpty) continue;
        final color = celebration['color']?.toString();
        map[key] = _FeastInfo(title, color);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _feastNames = map;
        _namesLoading = false;
      });
    }
  }

  void _changeYear(int delta) {
    _anchorYear += delta;
    _loadCalendar(context.read<LiturgyState>());
  }

  _FeastInfo? _lookupFeast(String key) {
    if (_feastNames.containsKey(key)) return _feastNames[key];
    final parts = key.split('_');
    for (int i = 1; i < parts.length; i++) {
      final suffix = parts.sublist(i).join('_');
      if (_feastNames.containsKey(suffix)) return _feastNames[suffix];
    }
    return null;
  }

  String _displayName(String key) {
    final info = _lookupFeast(key);
    if (info != null) return info.title;
    if (ferialDayCheck(key)) return ferialNameResolution(key);
    return key
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // Ferial codes that must not appear even when their precedence passes the prec filter.
  bool _isExcludedFerialCode(String code) {
    // First Sunday of Advent is always shown (start of liturgical year).
    if (code == 'advent_1_0') return false;
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

  // Extracts all celebrations from the calendar, one entry per feast.
  // defaultCelebrationTitle is included only if day.precedence ∉ {6, 9, 13}
  // and the code is not an excluded ferial Sunday/octave-weekday code.
  // feastList entries are always included (filtered later by _maxPrecedence).
  List<_Celebration> _buildCelebrationList() {
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
        if (!_isExcludedFerialCode(code)) {
          final colorStr = _lookupFeast(code)?.color ?? day.liturgicalColor;
          list.add(_Celebration(date, code, day.precedence, colorStr));
        }
      }

      for (final precEntry in day.feastList.entries) {
        final prec = precEntry.key;
        for (final key in precEntry.value) {
          final colorStr = _lookupFeast(key)?.color ?? day.liturgicalColor;
          list.add(_Celebration(date, key, prec, colorStr));
        }
      }
    }

    list.removeWhere((c) => c.precedence > _maxPrecedence);
    list.sort((a, b) {
      final d = a.date.compareTo(b.date);
      return d != 0 ? d : a.precedence.compareTo(b.precedence);
    });

    return list;
  }

  // Groups celebrations by date and produces a flat render list.
  // Always: date header first, then each feast indented below.
  List<_RenderItem> _buildRenderList() {
    final celebrations = _buildCelebrationList();
    if (celebrations.isEmpty) return [];

    final grouped = <DateTime, List<_Celebration>>{};
    for (final c in celebrations) {
      grouped.putIfAbsent(c.date, () => []).add(c);
    }

    final result = <_RenderItem>[];
    final sortedDates = grouped.keys.toList()..sort();

    for (final date in sortedDates) {
      result.add(_RenderItem.header(date));
      for (final c in grouped[date]!) {
        result.add(_RenderItem.indented(date, c));
      }
    }

    return result;
  }

  Color _liturgicalColor(String colorName) => switch (colorName) {
        'white' => const Color(0xFFF0F0F0),
        'red' => const Color(0xFFC62828),
        'green' => const Color(0xFF2E7D32),
        'purple' || 'violet' => const Color(0xFF6A1B9A),
        'rose' => const Color(0xFFE91E63),
        'black' => const Color(0xFF212121),
        _ => Colors.grey,
      };

  String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday]} ${d.day} ${_months[d.month]} ${d.year}';

  Widget _titleWidget(String name, int prec, BuildContext ctx) {
    if (prec <= 4) {
      return Text(
        name.toUpperCase(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }
    if (prec <= 5) {
      return Text(
        name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }
    final tag = prec <= 11 ? 'mém. obl.' : 'mém. fac.';
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(ctx).style.copyWith(fontSize: 14),
        children: [
          TextSpan(text: name),
          TextSpan(
            text: '  ($tag)',
            style: TextStyle(
              fontSize: 12,
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
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 2),
      child: Text(
        _formatDate(item.date),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Theme.of(ctx).colorScheme.onSurface,
        ),
      ),
    );
  }

  // Indented feast row for days with multiple feasts.
  Widget _buildIndentedRow(_RenderItem item, BuildContext ctx) {
    final c = item.celebration!;
    final name = _namesLoading ? '…' : _displayName(c.key);
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 16, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _colorCircle(c.colorStr),
          ),
          const SizedBox(width: 6),
          Expanded(child: _titleWidget(name, c.precedence, ctx)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final renderList = _buildRenderList();
    final theme = Theme.of(context);

    return Column(
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
                label: _depthLabels[_depthIndex],
                onChanged: (v) => setState(() => _depthIndex = v.round()),
              ),
              Text(
                _depthLabels[_depthIndex],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
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
                  : ListView.builder(
                      itemCount: renderList.length,
                      itemBuilder: (ctx, i) {
                        final item = renderList[i];
                        if (item.isHeader) return _buildDateHeader(item, ctx);
                        return _buildIndentedRow(item, ctx);
                      },
                    ),
        ),
      ],
    );
  }
}

class _Celebration {
  final DateTime date;
  final String key;
  final int precedence;
  final String colorStr;

  const _Celebration(this.date, this.key, this.precedence, this.colorStr);
}

class _RenderItem {
  final DateTime date;
  final _Celebration? celebration;
  final bool indented;

  _RenderItem.header(this.date) : celebration = null, indented = false;
  _RenderItem.indented(this.date, this.celebration) : indented = true;

  bool get isHeader => celebration == null;
}

class _FeastInfo {
  final String title;
  final String? color;
  const _FeastInfo(this.title, [this.color]);
}
