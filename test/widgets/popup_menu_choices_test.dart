import 'package:aelf_flutter/data/popup_menu_choices.dart';
import 'package:aelf_flutter/models/popup_menu_choice.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart' show VotiveOffice;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The untitled "Aα"/"א" 3-dot menu entry toggles
/// [LiturgyState.useOriginalPsalmLanguage] for every psalm and Old/New
/// Testament canticle at once, replacing what used to be a button next to
/// each text. It only shows up in "mode développé".
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late _FakeLiturgyState liturgyState;
  late List<PopupMenuChoice> choices;

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
              choices = buildPopupMenuChoices(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // No text title (see popup_menu_choices.dart) — the icon is the only
  // untitled entry in the menu, so an empty title identifies it.
  PopupMenuChoice? languagesChoice() {
    for (final choice in choices) {
      if (choice.title == '') return choice;
    }
    return null;
  }

  testWidgets('hidden outside "mode développé"', (tester) async {
    await pump(tester, advancedMode: false);
    expect(languagesChoice(), isNull);
  });

  testWidgets('shown in "mode développé", unchecked by default',
      (tester) async {
    await pump(tester, advancedMode: true);
    final choice = languagesChoice();
    expect(choice, isNotNull);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LiturgyState>.value(value: liturgyState),
        ],
        child: MaterialApp(home: Scaffold(body: choice!.widget!)),
      ),
    );
    await tester.pump();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(
        tester
            .widget<LanguageToggleIcon>(find.byType(LanguageToggleIcon))
            .active,
        isFalse);
  });

  testWidgets('selecting it turns the preference on and stays checked',
      (tester) async {
    await pump(tester, advancedMode: true);
    final choice = languagesChoice()!;

    // Opened through a real pushed route, like the actual 3-dot menu, so
    // the entry's own Navigator.pop() (closing the menu on selection) has
    // something to pop.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LiturgyState>.value(value: liturgyState),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(child: choice.widget!),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(liturgyState.useOriginalPsalmLanguage, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(
        tester
            .widget<LanguageToggleIcon>(find.byType(LanguageToggleIcon))
            .active,
        isTrue);
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
