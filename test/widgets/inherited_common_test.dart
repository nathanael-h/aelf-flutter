import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/localSolemnitiesState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/base_office_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Common an office takes from the one last chosen in another office.
///
/// Sunday Vespers, which have no Common, used to record "no common": the
/// First Vespers of the Dedication of the Lateran raised to a solemnity,
/// opened next, then took no Common and came out empty, its proper having
/// no First Vespers. Now a celebration without Commons records nothing, and
/// only a memorial may inherit "no common".
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final dataLoader = FileSystemDataLoader();
  final date = DateTime(2026, 11, 9);
  CelebrationContext celebration(String code, int precedence,
          {List<String>? commons}) =>
      CelebrationContext(
        celebrationCode: code,
        officeDescription: code,
        ferialCode: 'ot_32_1',
        date: date,
        precedence: precedence,
        commonList: commons,
        isCelebrable: true,
        dataLoader: dataLoader,
      );
  final sunday = celebration('ot_32_1', 6);
  final lateran = celebration('roman/dedication_of_the_lateran_basilica', 5,
      commons: ['dedicace_outside']);
  final leo = celebration('roman/leo_i_the_great_pope', 10,
      commons: ['pastors_pope', 'doctors']);

  late SelectedCelebrationState selected;
  late LocalSolemnitiesState localSolemnities;

  /// Shows [celebration] in an office, after "no common" (or [common]) was
  /// chosen elsewhere; returns the Common it was exported with.
  Future<String> commonExported(
      WidgetTester tester, CelebrationContext celebration,
      {bool inheritNoCommon = true, String? common}) async {
    selected = SelectedCelebrationState();
    if (inheritNoCommon || common != null) selected.setCommon(common);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<LiturgyState>.value(value: _FakeLiturgyState()),
        ChangeNotifierProvider.value(value: localSolemnities),
        ChangeNotifierProvider.value(value: selected),
      ],
      child: MaterialApp(
        home: Scaffold(body: _FakeOfficeView({'shown': celebration})),
      ),
    ));
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(find.byKey(const ValueKey('exported')));
    return text.data!;
  }

  setUp(() => localSolemnities = LocalSolemnitiesState());

  testWidgets('a feast does not inherit "no common"', (tester) async {
    expect(await commonExported(tester, lateran), '[dedicace_outside]');
  });

  testWidgets('a memorial raised to a local solemnity does not either',
      (tester) async {
    localSolemnities.raise(leo);
    expect(await commonExported(tester, leo), '[pastors_pope]');
  });

  testWidgets('a memorial still inherits "no common"', (tester) async {
    expect(await commonExported(tester, leo), '[]');
  });

  testWidgets('a feast inherits a Common of its own list', (tester) async {
    final feast = celebration('roman/some_feast', 7,
        commons: ['pastors_pope', 'doctors']);
    expect(
        await commonExported(tester, feast,
            inheritNoCommon: false, common: 'doctors'),
        '[doctors]');
  });

  testWidgets('a celebration without Commons leaves the one chosen elsewhere',
      (tester) async {
    expect(
        await commonExported(tester, sunday,
            inheritNoCommon: false, common: 'doctors'),
        '[]');
    expect(selected.common, 'doctors');
  });

  testWidgets('a celebration with Commons records its own', (tester) async {
    await commonExported(tester, lateran);
    expect(selected.common, 'dedicace_outside');
  });
}

class _FakeLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  bool useImprecatoryVerses = false;
  @override
  bool useTwoYearReadings = false;
  @override
  bool psalmSvgEnabled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOfficeView extends StatefulWidget {
  const _FakeOfficeView(this.celebrations);

  final Map<String, CelebrationContext> celebrations;

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
  bool hasInputChanged(_FakeOfficeView oldWidget) => false;
  @override
  Future<String> exportOffice(CelebrationContext ctx) async =>
      '${ctx.commonList}';

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
      Text(officeData, key: const ValueKey('exported'));
}
