import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/localSolemnitiesState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/base_office_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Among several celebrations, choosing another brings the one made a local
/// solemnity back to its own rank — in every office, and at Vespers, whose
/// list LiturgyState then detects again.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final dataLoader = FileSystemDataLoader();
  final date = DateTime(2027, 11, 3);
  CelebrationContext celebration(String code, int precedence) =>
      CelebrationContext(
        celebrationCode: code,
        officeDescription: code,
        ferialCode: 'ot_31_3',
        date: date,
        precedence: precedence,
        isCelebrable: true,
        dataLoader: dataLoader,
      );
  final celebrations = {
    'ferial': celebration('ot_31_3', 13),
    'martin': celebration('roman/martin_de_porres', 12),
    'hubert': celebration('lyon/hubert', 12),
  };

  for (final detects in [false, true]) {
    testWidgets(
        'choosing another celebration brings the local solemnity back '
        '(${detects ? 'Vespers' : 'Lauds'})', (tester) async {
      final localSolemnities = LocalSolemnitiesState()
        ..raise(celebrations['martin']!);
      final selected = SelectedCelebrationState()..setCelebration('martin');
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<LiturgyState>.value(
              value: _FakeLiturgyState()),
          ChangeNotifierProvider.value(value: localSolemnities),
          ChangeNotifierProvider.value(value: selected),
        ],
        child: MaterialApp(
          home: Scaffold(
              body: _FakeOfficeView(celebrations,
                  detectsLocalSolemnities: detects)),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('shown: martin'), findsOneWidget);

      await tester.tap(find.text('choose hubert'));
      await tester.pumpAndSettle();
      expect(
          localSolemnities.isLocalSolemnity(celebrations['martin']!), isFalse);
      expect(selected.celebrationKey, 'hubert');
      if (!detects) expect(find.text('shown: hubert'), findsOneWidget);
    });
  }
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  bool useImprecatoryVerses = false;
  @override
  bool useTwoYearReadings = false;
  @override
  bool psalmSvgEnabled = false;
  @override
  String psalmSvgSource = '';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOfficeView extends StatefulWidget {
  const _FakeOfficeView(this.celebrations,
      {required this.detectsLocalSolemnities});

  final Map<String, CelebrationContext> celebrations;
  final bool detectsLocalSolemnities;

  @override
  State<_FakeOfficeView> createState() => _FakeOfficeViewState();
}

class _FakeOfficeViewState
    extends BaseOfficeViewState<_FakeOfficeView, String> {
  @override
  Map<String, CelebrationContext> get celebrationList => widget.celebrations;
  @override
  DateTime get date => widget.celebrations.values.first.date;
  @override
  Calendar get calendar => Calendar();
  @override
  String get debugOfficeName => 'fake';
  @override
  bool get detectsLocalSolemnities => widget.detectsLocalSolemnities;
  @override
  bool hasInputChanged(_FakeOfficeView oldWidget) => false;
  @override
  Future<String> exportOffice(CelebrationContext ctx) async =>
      ctx.celebrationCode;

  @override
  Widget buildOfficeDisplay(
    BuildContext context, {
    required String celebrationKey,
    required CelebrationContext definition,
    required String officeData,
    required String? selectedCommon,
    required ValueChanged<String> onCelebrationChanged,
    required ValueChanged<String?> onCommonChanged,
    required void Function(String, int?) onPrecedenceOverridden,
  }) =>
      Column(children: [
        Text('shown: $celebrationKey'),
        for (final key in celebrationList.keys)
          TextButton(
            onPressed: () => onCelebrationChanged(key),
            child: Text('choose $key'),
          ),
      ]);
}
