import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
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
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

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
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _loadOffice();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
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

      final globalState = context.read<SelectedCelebrationState>();
      final globalKey = globalState.celebrationKey;
      final globalEntry = (globalKey != null)
          ? celebrationList.entries
              .where((e) => e.key == globalKey && e.value.isCelebrable)
              .firstOrNull
          : null;

      final selectedEntry = globalEntry ?? firstOption;
      _celebrationKey = selectedEntry.key;
      _selectedDefinition = selectedEntry.value;
      _imprecatoryVerses = await getImprecatoryVerses();

      String? autoCommon;
      final commonList = _selectedDefinition!.commonList;
      if (commonList != null && commonList.isNotEmpty) {
        if (_selectedDefinition!.celebrationCode != _selectedDefinition!.ferialCode) {
          if (globalState.commonSet) {
            final globalCommon = globalState.common;
            if (globalCommon == null) {
              autoCommon = null;
            } else if (commonList.contains(globalCommon)) {
              autoCommon = globalCommon;
            } else {
              autoCommon = commonList.first;
            }
          } else {
            autoCommon = commonList.first;
          }
        }
      }
      _selectedCommon = autoCommon;

      final globalPrecedence = globalState.getPrecedenceOverride(_celebrationKey!);
      final celebrationContext = _selectedDefinition!.copyWith(
        commonList: autoCommon != null
            ? [autoCommon]
            : (_selectedDefinition!.commonList ?? []),
        date: date,
        showImprecatoryVerses: _imprecatoryVerses,
        precedence: globalPrecedence ?? _selectedDefinition!.precedence,
      );
      final officeData = await exportOffice(celebrationContext);

      if (mounted) {
        setState(() {
          _officeData = officeData;
          _isLoading = false;
        });
        globalState.setCelebration(_celebrationKey);
        globalState.setCommon(autoCommon);
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

  Future<void> _onCelebrationChanged(String key) async {
    final definition = celebrationList[key];
    if (definition == null) return;

    setState(() => _isLoading = true);

    try {
      String? autoCommon;
      final commonList = definition.commonList;
      if (commonList != null && commonList.isNotEmpty) {
        if (definition.celebrationCode != definition.ferialCode) {
          autoCommon = commonList.first;
        }
      }

      final precedenceOverride =
          context.read<SelectedCelebrationState>().getPrecedenceOverride(key);
      final celebrationContext = definition.copyWith(
        commonList: autoCommon != null ? [autoCommon] : (definition.commonList ?? []),
        date: date,
        showImprecatoryVerses: _imprecatoryVerses,
        precedence: precedenceOverride ?? definition.precedence,
      );
      final officeData = await exportOffice(celebrationContext);

      if (mounted) {
        setState(() {
          _celebrationKey = key;
          _selectedDefinition = definition;
          _selectedCommon = autoCommon;
          _officeData = officeData;
          _isLoading = false;
        });
        context.read<SelectedCelebrationState>().setCelebration(key);
        context.read<SelectedCelebrationState>().setCommon(autoCommon);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels['error']!}: $e';
        });
      }
    }
  }

  Future<void> _onPrecedenceOverridden(String key, int? newPrecedence) async {
    final definition = celebrationList[key];
    debugPrint(
        '[PrecedenceDebug][$debugOfficeName] key=$key | originalPrecedence=${definition?.precedence} | newPrecedence=$newPrecedence | commonList=${definition?.commonList}');
    final state = context.read<SelectedCelebrationState>();
    if (newPrecedence == null) {
      state.removePrecedenceOverride(key);
    } else {
      state.setPrecedenceOverride(key, newPrecedence);
    }
    await _onCelebrationChanged(key);
    if (newPrecedence == 4 && mounted) {
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _onCommonChanged(String? common) async {
    if (_selectedDefinition == null) return;

    setState(() => _isLoading = true);

    try {
      final precedenceOverride = context
          .read<SelectedCelebrationState>()
          .getPrecedenceOverride(_celebrationKey!);
      final celebrationContext = _selectedDefinition!.copyWith(
        commonList: common != null ? [common] : [],
        date: date,
        showImprecatoryVerses: _imprecatoryVerses,
        precedence: precedenceOverride ?? _selectedDefinition!.precedence,
      );
      final officeData = await exportOffice(celebrationContext);

      if (mounted) {
        setState(() {
          _selectedCommon = common;
          _officeData = officeData;
          _isLoading = false;
        });
        context.read<SelectedCelebrationState>().setCommon(common);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '${liturgyLabels['error']!}: $e';
        });
      }
    }
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
    if (celebrationKey != null && selectedDefinition != null && officeData != null) {
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
