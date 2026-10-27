import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/localSolemnitiesState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/bible_text_provider.dart';

/// Abstract base for all office view states (Morning, Vespers, Readings, MiddleOfDay).
///
/// Subclasses provide the data source, export function, and display widget;
/// this class owns the loading / error / shake-animation lifecycle.
abstract class BaseOfficeViewState<W extends StatefulWidget, T> extends State<W>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _celebrationKey;
  CelebrationContext? _selectedDefinition;
  T? _officeData;
  String? _selectedCommon;
  String? _errorMessage;
  bool _imprecatoryVerses = false;
  bool _twoYearReadings = false;
  String? _svgSource;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  // Set when a local solemnity makes LiturgyState detect this office again:
  // the shake waits for the new list
  bool _shakeOnNextLoad = false;
  late LiturgyState _liturgyState;

  // --- Abstract interface ---

  Map<String, CelebrationContext> get celebrationList;
  DateTime get date;
  Calendar get calendar;
  String get debugOfficeName;

  /// Whether this office depends on the two-year reading cycle setting
  /// (only the Office of Readings), and must reload when it changes.
  bool get usesTwoYearReadings => false;

  /// Tomorrow's celebrations which may be made a local solemnity from this
  /// office, though not celebrable until then (Vespers: their First Vespers).
  Map<String, CelebrationContext> get eveCandidates => const {};

  /// Whether this office's list itself depends on the local solemnities —
  /// LiturgyState then detects it again (Vespers) — rather than only the
  /// rank its export is given.
  bool get detectsLocalSolemnities => false;

  bool hasInputChanged(W oldWidget);

  Future<T> exportOffice(CelebrationContext ctx);

  Widget buildOfficeDisplay(
    BuildContext context, {
    required String celebrationKey,
    required CelebrationContext definition,
    required T officeData,
    required String? selectedCommon,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
    required void Function(String, int?) onPrecedenceOverridden,
  });

  // --- Lifecycle ---

  @override
  void initState() {
    super.initState();
    _liturgyState = context.read<LiturgyState>();
    _liturgyState.addListener(_onOfficeSettingsChanged);
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _loadOffice();
  }

  @override
  void dispose() {
    _liturgyState.removeListener(_onOfficeSettingsChanged);
    _shakeController.dispose();
    super.dispose();
  }

  void _onOfficeSettingsChanged() {
    final newSource =
        _liturgyState.psalmSvgEnabled ? _liturgyState.psalmSvgSource : null;
    if (newSource != _svgSource ||
        _liturgyState.useImprecatoryVerses != _imprecatoryVerses ||
        (usesTwoYearReadings &&
            _liturgyState.useTwoYearReadings != _twoYearReadings)) {
      _loadOffice();
    }
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (hasInputChanged(oldWidget)) {
      _loadOffice();
    }
  }

  // --- Data loading ---

  Future<void> _loadOffice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firstOption = celebrationList.entries
          .where((entry) => entry.value.isCelebrable)
          .firstOrNull;

      if (firstOption == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = liturgyLabels['no-office']!;
        });
        return;
      }

      // The day's local solemnity, if celebrable, is the office's celebration
      final localSolemnities = context.read<LocalSolemnitiesState>();
      final localSolemnity = celebrationList.entries
          .where((e) =>
              e.value.isCelebrable &&
              localSolemnities.isLocalSolemnity(e.value))
          .firstOrNull;

      final globalKey = context.read<SelectedCelebrationState>().celebrationKey;
      final globalEntry = (globalKey != null)
          ? celebrationList.entries
              .where((e) => e.key == globalKey && e.value.isCelebrable)
              .firstOrNull
          : null;

      // Don't let a lower-priority global entry (e.g. ferial set by MiddleOfDay)
      // override a higher-priority firstOption (e.g. an optional memorial).
      final selectedEntry = localSolemnity ??
          ((globalEntry != null &&
                  (globalEntry.value.precedence ?? 13) <=
                      (firstOption.value.precedence ?? 13))
              ? globalEntry
              : firstOption);
      final autoCommon =
          _defaultCommon(selectedEntry.value, inheritGlobal: true);
      _imprecatoryVerses = _liturgyState.useImprecatoryVerses;
      _twoYearReadings = _liturgyState.useTwoYearReadings;
      _svgSource =
          _liturgyState.psalmSvgEnabled ? _liturgyState.psalmSvgSource : null;

      await _applySelection(selectedEntry.key, selectedEntry.value, autoCommon,
          errorLabel: 'error-office');
      if (_shakeOnNextLoad && mounted) {
        _shakeOnNextLoad = false;
        _shakeController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels['error-office']!}: $e';
        });
      }
    }
  }

  /// Whether [definition], celebrated, always takes a Common: "no common"
  /// isn't offered, so one chosen in another office doesn't apply here —
  /// as for the office of the Dedication or of the Dead.
  @protected
  bool requiresCommon(CelebrationContext definition) =>
      definition.votiveOffice != null;

  /// Common preselected for [definition]: none for a ferial day or a
  /// celebration without commons. Otherwise, when [inheritGlobal], the common
  /// last chosen in another office (including "no common", unless
  /// [requiresCommon]) if it applies here; else the first common of the list.
  String? _defaultCommon(CelebrationContext definition,
      {bool inheritGlobal = false}) {
    final commonList = definition.commonList;
    if (commonList == null || commonList.isEmpty) return null;
    if (!definition.hasProper) return null;
    final globalState = context.read<SelectedCelebrationState>();
    if (inheritGlobal && globalState.commonSet) {
      final globalCommon = globalState.common;
      if (globalCommon == null
          ? !requiresCommon(definition)
          : commonList.contains(globalCommon)) {
        return globalCommon;
      }
    }
    return commonList.first;
  }

  /// Exports the office for [definition] hydrated with [common] (no common
  /// when null) and records this selection. The chip shown and the content
  /// hydrated both come from this single [common] value.
  Future<void> _applySelection(
    String key,
    CelebrationContext definition,
    String? common, {
    String errorLabel = 'error',
  }) async {
    final globalState = context.read<SelectedCelebrationState>();
    final localSolemnities = context.read<LocalSolemnitiesState>();
    try {
      final officeData = await exportOffice(definition.copyWith(
        commonList: common != null ? [common] : [],
        date: date,
        showImprecatoryVerses: _imprecatoryVerses,
        twoYearReadingCycle: _twoYearReadings,
        bibleTextProvider: AppBibleTextProvider.instance,
        precedence: localSolemnities.precedenceOverride(
                definition.date, definition.celebrationCode) ??
            definition.precedence,
        svgSource: _svgSource,
      ));

      if (mounted) {
        setState(() {
          _celebrationKey = key;
          _selectedDefinition = definition;
          _selectedCommon = common;
          _officeData = officeData;
          _isLoading = false;
        });
        globalState.setCelebration(key);
        globalState.setCommon(common);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels[errorLabel]!}: $e';
        });
      }
    }
  }

  Future<void> _onCelebrationChanged(String key) async {
    final definition = celebrationList[key];
    if (definition == null) return;

    setState(() => _isLoading = true);
    await _applySelection(key, definition, _defaultCommon(definition));
  }

  Future<void> _onPrecedenceOverridden(String key, int? newPrecedence) async {
    final definition = celebrationList[key] ?? eveCandidates[key];
    if (definition == null) return;
    final localSolemnities = context.read<LocalSolemnitiesState>();
    if (newPrecedence == null) {
      localSolemnities.lower(definition);
    } else {
      localSolemnities.raise(definition);
    }
    // A shake acknowledges the passage to a local solemnity
    if (detectsLocalSolemnities) {
      // The list LiturgyState detects again selects it
      context.read<SelectedCelebrationState>().setCelebration(key);
      _shakeOnNextLoad = newPrecedence == 4;
      return;
    }
    await _onCelebrationChanged(key);
    if (newPrecedence == 4 && mounted) {
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _onCommonChanged(String? common) async {
    final key = _celebrationKey;
    final definition = _selectedDefinition;
    if (key == null || definition == null) return;

    setState(() => _isLoading = true);
    await _applySelection(key, definition, common);
  }

  /// Exports the current selection again, with the same celebration and
  /// Common — after an option exportOffice reads has changed (the Mass's
  /// reading source).
  @protected
  Future<void> reloadSelection() => _onCommonChanged(_selectedCommon);

  // --- Build ---

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOffice,
              child: Text(liturgyLabels['retry']!),
            ),
          ],
        ),
      );
    }
    final celebrationKey = _celebrationKey;
    final selectedDefinition = _selectedDefinition;
    final officeData = _officeData;
    if (celebrationKey != null &&
        selectedDefinition != null &&
        officeData != null) {
      return buildOfficeDisplay(
        context,
        celebrationKey: celebrationKey,
        definition: selectedDefinition.copyWith(
          showImprecatoryVerses: _imprecatoryVerses,
          precedence: context.read<LocalSolemnitiesState>().precedenceOverride(
                  selectedDefinition.date,
                  selectedDefinition.celebrationCode) ??
              selectedDefinition.precedence,
        ),
        officeData: officeData,
        selectedCommon: _selectedCommon,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
        onPrecedenceOverridden: _onPrecedenceOverridden,
      );
    }
    return Center(child: Text(liturgyLabels['no-data']!));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeAnimation.value, 0),
        child: child,
      ),
      child: _buildContent(context),
    );
  }
}
