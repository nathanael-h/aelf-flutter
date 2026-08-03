import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/material.dart';

/// One liturgical celebration shown in the offices/mass drawer header: a
/// coloured square, a name and an optional degree ("Solennité", "Férie"…).
///
/// Mirrors the native `OfficeLiturgyOption` (`liturgical_color` /
/// `liturgical_degree` / `liturgical_name`) and its
/// `navigation_drawer_liturgical_options_fragment.xml` row. A day can carry
/// several (e.g. a feast concurring with a ferial), hence a list in
/// [OfficeHeaderInfo].
@immutable
class OfficeLiturgyOption {
  const OfficeLiturgyOption({
    required this.name,
    this.degree,
    this.colorName,
  });

  /// Display name, e.g. "15ème dimanche du Temps Ordinaire".
  final String name;

  /// Degree, e.g. "Solennité", "Fête", "Férie". May be null/empty.
  final String? degree;

  /// AELF colour name (French from the API, English from offline_liturgy).
  /// Resolved through [AelfLiturgicalColors.resolve].
  final String? colorName;

  /// The square's colour for the current theme, or null when unknown so the
  /// caller can hide the square (native uses a transparent "unknown" colour).
  Color? squareColor(BuildContext context) {
    final resolved =
        AelfLiturgicalColors.of(Theme.of(context)).resolve(colorName);
    return resolved.a == 0 ? null : resolved;
  }
}

/// Everything the offices/mass drawer header needs, normalized from either data
/// source so `LeftMenuOfficeHeader` stays source-agnostic:
///
/// - **API** — the liturgy `informations` block (see [OfficeHeaderInfo.fromApi]).
/// - **offline_liturgy** — a `CelebrationContext`
///   (see [OfficeHeaderInfo.fromOffline]).
///
/// Any field may be null; the widget degrades gracefully by hiding empty rows.
@immutable
class OfficeHeaderInfo {
  const OfficeHeaderInfo({
    this.day,
    this.liturgicalYear,
    this.psalterWeek,
    this.region,
    this.options = const <OfficeLiturgyOption>[],
    this.isLoading = false,
    this.isError = false,
  });

  /// Big title, e.g. "Dimanche".
  final String? day;

  /// Liturgical year label, e.g. "A" or "Impaire".
  final String? liturgicalYear;

  /// Roman psalter week, e.g. "III".
  final String? psalterWeek;

  /// Current region id (france, belgique, …, romain).
  final String? region;

  final List<OfficeLiturgyOption> options;

  /// Header still loading — native shows "Chargement…".
  final bool isLoading;

  /// Fetch/compute failed — native shows "Erreur" + a note.
  final bool isError;

  const OfficeHeaderInfo.loading() : this(isLoading: true);

  const OfficeHeaderInfo.error() : this(isError: true);

  /// The subtitle line, built exactly like the native app:
  /// "Année {year}" + " — " + "Semaine {week}", omitting missing parts.
  String get timeText {
    final parts = <String>[];
    if (liturgicalYear != null && liturgicalYear!.isNotEmpty) {
      parts.add('Année ${_capitalize(liturgicalYear!)}');
    }
    if (psalterWeek != null && psalterWeek!.isNotEmpty) {
      parts.add('Semaine $psalterWeek');
    }
    return parts.join(' — ');
  }

  /// Builds from the online `informations` block returned by
  /// `api.app.epitre.co/82/office/informations/{date}.json` (the same endpoint
  /// and JSON the native Android app consumes — see `OfficeInformations` /
  /// `OfficeLiturgyOption` there).
  ///
  /// Fields: `liturgical_day` (weekday title), `liturgical_year`,
  /// `psalter_week` (int), `zone` (region), and a `liturgy_options` list of
  /// `{liturgical_name, liturgical_degree, liturgical_color}`. The colour names
  /// are French (`vert`, `blanc`, …), resolved by [AelfLiturgicalColors.resolve].
  ///
  /// Pass the inner `informations` block, not the whole response envelope.
  factory OfficeHeaderInfo.fromApi(Map<dynamic, dynamic> informations,
      {String? region}) {
    List<OfficeLiturgyOption> parseOptions() {
      final raw = informations['liturgy_options'];
      if (raw is! List) return const <OfficeLiturgyOption>[];
      return raw
          .whereType<Map>()
          .map((o) => OfficeLiturgyOption(
                name: _capitalize((o['liturgical_name'] ?? '').toString()),
                degree: _asString(o['liturgical_degree']),
                colorName: _asString(o['liturgical_color']),
              ))
          .where((o) => o.name.isNotEmpty)
          .toList();
    }

    // psalter_week is a 1-based integer (native renders it as a Roman numeral).
    final week = informations['psalter_week'];
    final int? weekNumber = week is int ? week : int.tryParse('${week ?? ''}');

    return OfficeHeaderInfo(
      day: _capitalizeOrNull(_asString(informations['liturgical_day'])),
      liturgicalYear:
          _capitalizeOrNull(_asString(informations['liturgical_year'])),
      psalterWeek: weekNumber == null ? null : _roman(weekNumber),
      region: region ?? _asString(informations['zone']),
      options: parseOptions(),
    );
  }

  /// Builds the offline offices/mass header from primitives already resolved by
  /// `LiturgyState` (which owns the offline calendar + office maps and the
  /// offline_liturgy dependency). Keeps the Roman-numeral and capitalisation
  /// rules here so the offline and online headers render identically.
  ///
  /// - [day] — French weekday, e.g. "vendredi" (becomes the big title).
  /// - [liturgicalYear] — "paire" / "impaire" (the weekday 2-year cycle; offline
  ///   data carries no A/B/C Sunday cycle).
  /// - [psalterWeek] — 1-based breviary week, rendered as a Roman numeral.
  /// - [options] — one per celebrable feast, already built with their colours
  ///   and degrees.
  factory OfficeHeaderInfo.fromOfflineDay({
    String? day,
    String? liturgicalYear,
    int? psalterWeek,
    String? region,
    List<OfficeLiturgyOption> options = const <OfficeLiturgyOption>[],
  }) {
    return OfficeHeaderInfo(
      day: _capitalizeOrNull(day),
      liturgicalYear: _capitalizeOrNull(liturgicalYear),
      psalterWeek: psalterWeek == null ? null : _roman(psalterWeek),
      region: region,
      options: options,
    );
  }

  /// Builds from an offline_liturgy `CelebrationContext`.
  ///
  /// Typed as [dynamic] so this model has no compile dependency on the
  /// offline_liturgy package; callers in the offline office views pass their
  /// `CelebrationContext` directly. Best-effort — offline data does not carry a
  /// weekday label the way the API does, so [day] is left to the caller.
  factory OfficeHeaderInfo.fromOffline(
    dynamic celebrationContext, {
    String? region,
    String? day,
  }) {
    final ctx = celebrationContext;
    final String? title = _asString(ctx?.celebrationTitle);
    final String? color = _asString(ctx?.liturgicalColor);
    final int? week = ctx?.breviaryWeek as int?;
    // CelebrationContext carries the psalter week and the liturgical *season*
    // (liturgicalTime, e.g. "ordinary") but no A/B/C year letter — so the time
    // line shows the week only, never "Année …".
    return OfficeHeaderInfo(
      day: day,
      psalterWeek: week == null ? null : _roman(week),
      region: region,
      options: title == null
          ? const <OfficeLiturgyOption>[]
          : <OfficeLiturgyOption>[
              OfficeLiturgyOption(name: title, colorName: color),
            ],
    );
  }

  static String? _asString(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String? _capitalizeOrNull(String? s) =>
      s == null ? null : _capitalize(s);

  static const _romanNumerals = ['', 'I', 'II', 'III', 'IV'];
  static String _roman(int n) =>
      (n >= 1 && n < _romanNumerals.length) ? _romanNumerals[n] : '$n';
}
