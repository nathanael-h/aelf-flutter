import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The memorials and feasts the user celebrates as a local solemnity (e.g.
/// the titular of the place): one at a time, for every office of its day —
/// and for the evening before, whose Vespers and Compline become its
/// First Vespers and its eve's Compline (see LiturgyState).
///
/// Kept across launches, so that a solemnity begun at First Vespers still
/// is one the next morning, but for [lifetime] only: a local solemnity is
/// an occasional choice, not a setting.
class LocalSolemnitiesState extends ChangeNotifier {
  LocalSolemnitiesState({DateTime Function()? now})
      : _now = now ?? DateTime.now {
    _load();
  }

  static const _prefsKey = 'localSolemnities';
  static const lifetime = Duration(hours: 36);

  final DateTime Function() _now;
  // Day (y-m-d) -> its local solemnity, and when it was chosen
  final Map<String, ({String code, DateTime chosenAt})> _byDay = {};

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  bool _isExpired(DateTime chosenAt) => _now().difference(chosenAt) > lifetime;

  /// 4 for the local solemnity of [date], else null — a [PrecedenceOverride]
  /// for the offices' detection.
  int? precedenceOverride(DateTime date, String celebrationCode) {
    final entry = _byDay[_dayKey(date)];
    if (entry == null ||
        entry.code != celebrationCode ||
        _isExpired(entry.chosenAt)) {
      return null;
    }
    return 4;
  }

  bool isLocalSolemnity(CelebrationContext celebration) =>
      precedenceOverride(celebration.date, celebration.celebrationCode) != null;

  /// Makes [celebration] the local solemnity of its day, in place of the
  /// one chosen before, whatever its day: at an evening office, today's and
  /// tomorrow's celebrations can't both be solemnities.
  void raise(CelebrationContext celebration) {
    _byDay.clear();
    _byDay[_dayKey(celebration.date)] =
        (code: celebration.celebrationCode, chosenAt: _now());
    _changed();
  }

  /// Brings [celebration] back to its own rank.
  void lower(CelebrationContext celebration) {
    final key = _dayKey(celebration.date);
    if (_byDay[key]?.code != celebration.celebrationCode) return;
    _byDay.remove(key);
    _changed();
  }

  void _changed() {
    _byDay.removeWhere((_, entry) => _isExpired(entry.chosenAt));
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == null) return;
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      for (final MapEntry(:key, :value) in decoded.entries) {
        final entry = value as Map<String, dynamic>;
        final chosenAt = DateTime.parse(entry['chosenAt'] as String);
        if (_isExpired(chosenAt)) continue;
        _byDay.putIfAbsent(
            key, () => (code: entry['code'] as String, chosenAt: chosenAt));
      }
      if (_byDay.isNotEmpty) notifyListeners();
    } catch (e) {
      debugPrint('LocalSolemnitiesState: unreadable saved state ($e)');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey,
        jsonEncode({
          for (final MapEntry(:key, :value) in _byDay.entries)
            key: {
              'code': value.code,
              'chosenAt': value.chosenAt.toIso8601String(),
            },
        }));
  }
}
