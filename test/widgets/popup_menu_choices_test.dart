import 'package:aelf_flutter/data/popup_menu_choices.dart';
import 'package:aelf_flutter/models/popup_menu_choice.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart' show VotiveOffice;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The "Psaumes et Cantiques en langues anciennes" 3-dot menu entry toggles
/// [LiturgyState.useOriginalPsalmLanguage] for every psalm and Old/New
/// Testament canticle at once, replacing what used to be a button next to
/// each text. It only shows up in "mode développé", and highlights like any
/// other selected menu entry (see officeChoice) while active — no separate
/// icon or switch.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late _FakeLiturgyState liturgyState;
  late List<PopupMenuChoice> choices;
  late BuildContext menuContext;

  Future<void> pump(WidgetTester tester, {required bool advancedMode}) async {
    liturgyState = _FakeLiturgyState();
    final featureFlags = FeatureFlagsState();
    await featureFlags.setOfflineLiturgyEnabled(true);
    await featureFlags.setAdvancedModeEnabled(advancedMode);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LiturgyState>.value(value: liturgyState),
          ChangeNotifierProvider.value(value: featureFlags),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              menuContext = context;
              choices = buildPopupMenuChoices(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  PopupMenuChoice? languagesChoice() {
    for (final choice in choices) {
      if (choice.title == 'Psaumes et Cantiques\nen langues anciennes') {
        return choice;
      }
    }
    return null;
  }

  testWidgets('hidden outside "mode développé"', (tester) async {
    await pump(tester, advancedMode: false);
    expect(languagesChoice(), isNull);
  });

  testWidgets('shown in "mode développé", unhighlighted by default',
      (tester) async {
    await pump(tester, advancedMode: true);
    expect(languagesChoice()?.selected, isFalse);
  });

  testWidgets('selecting it turns the preference on and highlights it',
      (tester) async {
    await pump(tester, advancedMode: true);

    languagesChoice()!.onSelected!();
    expect(liturgyState.useOriginalPsalmLanguage, isTrue);

    // The real menu rebuilds its entries (buildPopupMenuChoices) every time
    // it's opened, so re-run it against the same context instead of
    // relying on the already-built Builder to refresh itself.
    choices = buildPopupMenuChoices(menuContext);
    expect(languagesChoice()!.selected, isTrue);

    languagesChoice()!.onSelected!();
    expect(liturgyState.useOriginalPsalmLanguage, isFalse);
  });
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  bool useOriginalPsalmLanguage = false;
  @override
  VotiveOffice? votiveOffice;

  @override
  void updateOriginalPsalmLanguage(bool enabled) {
    if (useOriginalPsalmLanguage == enabled) return;
    useOriginalPsalmLanguage = enabled;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
