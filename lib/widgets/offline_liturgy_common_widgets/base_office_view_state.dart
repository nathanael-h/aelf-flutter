import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/settings.dart';

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
  String? _svgSource;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late LiturgyState _liturgyState;

  // --- Abstract interface ---

  Map<String, CelebrationContext> get celebrationList;
  DateTime get date;
  Calendar get calendar;
  String get debugOfficeName;

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
    _liturgyState.addListener(_onPsalmSettingsChanged);
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
    _liturgyState.removeListener(_onPsalmSettingsChanged);
    _shakeController.dispose();
    super.dispose();
  }

  void _onPsalmSettingsChanged() {
    final newSource =
        _liturgyState.psalmSvgEnabled ? _liturgyState.psalmSvgSource : null;
    if (newSource != _svgSource) {
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

      final globalKey = context.read<SelectedCelebrationState>().celebrationKey;
      final globalEntry = (globalKey != null)
          ? celebrationList.entries
              .where((e) => e.key == globalKey && e.value.isCelebrable)
              .firstOrNull
          : null;

      // Don't let a lower-priority global entry (e.g. ferial set by MiddleOfDay)
      // override a higher-priority firstOption (e.g. an optional memorial).
      final selectedEntry = (globalEntry != null &&
              (globalEntry.value.precedence ?? 13) <=
                  (firstOption.value.precedence ?? 13))
          ? globalEntry
          : firstOption;
      final autoCommon =
          _defaultCommon(selectedEntry.value, inheritGlobal: true);
      _imprecatoryVerses = await getImprecatoryVerses();
      _svgSource =
          _liturgyState.psalmSvgEnabled ? _liturgyState.psalmSvgSource : null;

      await _applySelection(selectedEntry.key, selectedEntry.value, autoCommon,
          errorLabel: 'error-office');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels['error-office']!}: $e';
        });
      }
    }
  }

  /// Common preselected for [definition]: none for a ferial day or a
  /// celebration without commons. Otherwise, when [inheritGlobal], the common
  /// last chosen in another office (including "no common") if it applies here;
  /// else the first common of the list.
  String? _defaultCommon(CelebrationContext definition,
      {bool inheritGlobal = false}) {
    final commonList = definition.commonList;
    if (commonList == null || commonList.isEmpty) return null;
    if (definition.celebrationCode == definition.ferialCode) return null;
    final globalState = context.read<SelectedCelebrationState>();
    if (inheritGlobal && globalState.commonSet) {
      final globalCommon = globalState.common;
      if (globalCommon == null || commonList.contains(globalCommon)) {
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
    try {
      final officeData = await exportOffice(definition.copyWith(
        commonList: common != null ? [common] : [],
        date: date,
        showImprecatoryVerses: _imprecatoryVerses,
        precedence:
            globalState.getPrecedenceOverride(key) ?? definition.precedence,
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
    final state = context.read<SelectedCelebrationState>();
    if (newPrecedence == null) {
      state.removePrecedenceOverride(key);
    } else {
      state.setPrecedenceOverride(key, newPrecedence);
    }
    await _onCelebrationChanged(key);
    if ((newPrecedence == 4 || newPrecedence == 8) && mounted) {
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
          precedence: context
                  .read<SelectedCelebrationState>()
                  .getPrecedenceOverride(celebrationKey) ??
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
