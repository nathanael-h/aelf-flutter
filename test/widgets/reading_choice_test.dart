import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/localSolemnitiesState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_mass_view.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_readings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_liturgy/assets/libraries/french_liturgy_labels.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A reading offering several choices: its title above them, their number
/// in italics, and the chosen one's own title marked like a psalm of the
/// psalmody — but the Gospel's, which keeps its cross. The Gospel
/// acclamation's verses are all shown, one after another.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final date = DateTime(2027, 10, 18);
  final definition = CelebrationContext(
    celebrationCode: 'ot_29_1',
    officeDescription: 'ot_29_1',
    ferialCode: 'ot_29_1',
    date: date,
    precedence: 13,
    isCelebrable: true,
    dataLoader: FileSystemDataLoader(),
  );

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(800, 20000);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrentZoom()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => SelectedCelebrationState()),
          ChangeNotifierProvider(create: (_) => LocalSolemnitiesState()),
          ChangeNotifierProvider<LiturgyState>.value(
              value: _ScrollLiturgyState()),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pump();
  }

  // The LiturgyPartTitles and LiturgyContentTitles, in their order on screen
  List<String> partTitles(WidgetTester tester) => [
        for (final w in tester
            .widgetList<LiturgyPartTitle>(find.byType(LiturgyPartTitle)))
          if (w.content != null) w.content!,
      ];
  Map<String, bool> contentTitles(WidgetTester tester) => {
        for (final w in tester
            .widgetList<LiturgyContentTitle>(find.byType(LiturgyContentTitle)))
          w.title: w.showBullet,
      };
  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder.first).dy;

  testWidgets('the Office of Readings', (tester) async {
    await pump(
      tester,
      ReadingsOfficeDisplay(
        celebrationKey: 'day',
        readingsDefinition: definition,
        readingsData: Readings(
          biblicalReading: [
            const BiblicalReading(ref: 'Is 1, 1-9', content: 'Vision'),
            const BiblicalReading(ref: 'Is 2, 1-5', content: 'Montagne'),
          ],
          patristicReading: [
            const PatristicReading(title: 'SAINT AUGUSTIN', content: 'Texte'),
          ],
        ),
        selectedCommon: null,
        readingsDefinitions: {'day': definition},
        onCelebrationChanged: (_) {},
        onCommonChanged: (_) {},
        onPrecedenceOverridden: (_, __) {},
        calendar: Calendar(),
        date: date,
      ),
    );

    final biblical = liturgyLabels['biblical_reading']!;
    expect(partTitles(tester).where((t) => t == biblical), hasLength(1));
    expect(find.text('2 choix possibles'), findsOneWidget);
    expect(tester.widget<Text>(find.text('2 choix possibles')).style?.fontStyle,
        FontStyle.italic);
    expect(
        top(
            tester,
            find.byWidgetPredicate(
                (w) => w is LiturgyPartTitle && w.content == biblical)),
        lessThan(top(tester, find.text('2 choix possibles'))));

    final titles = contentTitles(tester);
    expect(titles.entries.singleWhere((e) => e.key.contains('Isaïe')).value,
        isTrue);
    // A single patristic reading: unchanged
    expect(titles['SAINT AUGUSTIN'], isFalse);
    expect(partTitles(tester), contains(liturgyLabels['patristic_reading']));
  });

  testWidgets('the Mass', (tester) async {
    await pump(
      tester,
      MassOfficeDisplay(
        celebrationKey: 'day',
        massDefinition: definition,
        massData: Mass(readingParts: [
          MassReadingPart(partType: 'READING_1', partContents: [
            MassReading(biblicalRef: 'Is 1, 1-9', content: 'Vision'),
            MassReading(biblicalRef: 'Is 2, 1-5', content: 'Montagne'),
          ]),
          MassReadingPart(partType: 'PSALM', partContents: [
            MassPsalm(biblicalRef: 'Ps 22', refAbbr: '22, 1', content: 'a'),
            MassPsalm(biblicalRef: 'Ex 15, 1-2', content: 'b'),
          ]),
          MassReadingPart(partType: 'ALLELUIA', partContents: [
            MassReading(biblicalRef: 'Mt 23, 9', content: 'Un seul Père'),
            MassReading(biblicalRef: 'Mc 1, 17', content: 'Venez à ma suite'),
          ]),
          MassReadingPart(partType: 'GOSPEL', partContents: [
            MassGospel(biblicalRef: 'Jn 1, 1-5', content: 'Au commencement'),
            MassGospel(biblicalRef: 'Jn 2, 1-11', content: 'Cana'),
          ]),
        ]),
        selectedCommon: null,
        massList: {'day': definition},
        onCelebrationChanged: (_) {},
        onCommonChanged: (_) {},
        onPrecedenceOverridden: (_, __) {},
        readingSource: MassReadingSource.values.first,
        onReadingSourceChanged: (_) {},
        calendar: Calendar(),
        date: date,
      ),
    );

    final titles = partTitles(tester);
    final reading = readingsTypeLabels['READING_1']!;
    final gospel = readingsTypeLabels['GOSPEL']!;
    expect(titles.where((t) => t == reading), hasLength(1));
    expect(titles, contains('Psaume ou cantique'));
    expect(titles.where((t) => t == gospel), hasLength(1));
    expect(find.text('2 choix possibles'), findsNWidgets(3));

    final contents = contentTitles(tester);
    expect(contents.entries.singleWhere((e) => e.key.contains('Isaïe')).value,
        isTrue);
    expect(contents['Psaume 22'], isTrue);
    // The Gospel acclamation's verses, one after another
    expect(
        titles.where((t) => t == readingsTypeLabels['ALLELUIA']), hasLength(1));
    expect(contents.keys.where((t) => t.contains('Matthieu')), isEmpty);
    for (final verse in ['Un seul Père', 'Venez à ma suite', 'ou bien']) {
      expect(find.textContaining(verse, findRichText: true), findsOneWidget,
          reason: verse);
    }
    // The Gospel's title above its choices, then the Alléluia
    expect(contents.keys.where((t) => t.contains('Jean')), isEmpty);
    expect(titles.indexOf(gospel), lessThan(titles.indexOf('Alléluia')));
  });
}

class _ScrollLiturgyState extends ChangeNotifier implements LiturgyState {
  @override
  bool get useScrollMode => true;

  @override
  bool get isFullScreen => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
