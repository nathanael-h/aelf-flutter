import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:flutter_test/flutter_test.dart';

/// The drawer header's sub-title on a ferial day must show the *liturgical*
/// week ("25ème semaine du Temps Ordinaire"), read from the ferial code — not
/// the 1–4 breviary week that drives the psalter and is shown on its own line.
void main() {
  group('LiturgyState.ferialSeasonText', () {
    test('Ordinary Time shows the liturgical week, not the psalter week', () {
      // Week 25 → psalter week 1: it must read 25, never 1.
      expect(LiturgyState.ferialSeasonText('ot', 'ot_25_4'),
          '25ème semaine du Temps Ordinaire');
      expect(LiturgyState.ferialSeasonText('ot', 'ot_2_3'),
          '2ème semaine du Temps Ordinaire');
      expect(LiturgyState.ferialSeasonText('ot', 'ot_34_6'),
          '34ème semaine du Temps Ordinaire');
    });

    test('week 1 takes the feminine ordinal', () {
      expect(LiturgyState.ferialSeasonText('ot', 'ot_1_5'),
          '1ère semaine du Temps Ordinaire');
    });

    test('Advent, Lent and Easter carry their own week', () {
      expect(LiturgyState.ferialSeasonText('advent', 'advent_2_3'),
          '2ème semaine du Temps de l’Avent');
      expect(LiturgyState.ferialSeasonText('lent', 'lent_3_4'),
          '3ème semaine du Carême');
      expect(LiturgyState.ferialSeasonText('easter', 'easter_3_4'),
          '3ème semaine du Temps Pascal');
    });

    test('Easter time is tagged paschaltime but reads as the Easter labels',
        () {
      expect(LiturgyState.ferialSeasonText('paschaltime', 'easter_6_3'),
          '6ème semaine du Temps Pascal');
    });

    test('the dated Advent ferials of 17–24 December keep their week', () {
      expect(LiturgyState.ferialSeasonText('advent', 'advent-18_3_5'),
          '3ème semaine du Temps de l’Avent');
    });

    test('a variant suffix does not hide the week', () {
      expect(
          LiturgyState.ferialSeasonText(
              'easter', 'easter_6_3_before_ascension'),
          '6ème semaine du Temps Pascal');
    });

    test('the days after Ash Wednesday (week 0) show the season alone', () {
      expect(LiturgyState.ferialSeasonText('lent', 'lent_0_4'), 'Carême');
    });

    test('Christmas time shows the season alone, dated or not', () {
      expect(LiturgyState.ferialSeasonText('christmas', 'christmas_1_2'),
          'Temps de Noël');
      expect(
          LiturgyState.ferialSeasonText(
              'christmas', 'christmas-ferial_before_epiphany_4'),
          'Temps de Noël');
    });

    test('a missing or unparseable ferial code falls back to the season', () {
      expect(LiturgyState.ferialSeasonText('ot', null), 'Temps Ordinaire');
      expect(LiturgyState.ferialSeasonText('ot', ''), 'Temps Ordinaire');
      expect(LiturgyState.ferialSeasonText('advent', 'nonsense'),
          'Temps de l’Avent');
    });

    test('an unknown or missing season yields nothing', () {
      expect(LiturgyState.ferialSeasonText(null, 'ot_25_4'), isNull);
      expect(LiturgyState.ferialSeasonText('nowhere', 'ot_25_4'), isNull);
    });
  });

  group('LiturgyState.isPlainFerial', () {
    bool ferial(int? precedence, String code, String ferialCode, String time) =>
        LiturgyState.isPlainFerial(
          precedence: precedence,
          celebrationCode: code,
          ferialCode: ferialCode,
          liturgicalTime: time,
        );

    test('a precedence-13 day is ferial (Ordinary, Easter and Christmas time)',
        () {
      expect(ferial(13, 'ot_25_4', 'ot_25_4', 'ot'), isTrue);
      expect(ferial(13, 'easter_6_3', 'easter_6_3', 'paschaltime'), isTrue);
      expect(ferial(13, 'christmas_2_1', 'christmas_2_1', 'christmas'), isTrue);
    });

    test('no primary celebration yet counts as ferial', () {
      expect(LiturgyState.isPlainFerial(), isTrue);
    });

    test('Lent weekdays and Advent 17–24 (precedence 9) are ferial', () {
      expect(ferial(9, 'lent_2_4', 'lent_2_4', 'lent'), isTrue);
      expect(ferial(9, 'lent_0_4', 'lent_0_4', 'lent'), isTrue);
      expect(ferial(9, 'advent-18_3_5', 'advent-18_3_5', 'advent'), isTrue);
    });

    test('a feast on the day is not a plain ferial', () {
      expect(ferial(9, 'roman/some_feast', 'lent_2_4', 'lent'), isFalse);
      expect(ferial(10, 'roman/some_memorial', 'ot_26_0', 'ot'), isFalse);
    });

    test('Sundays, Ash Wednesday, Holy Week and octaves keep their title', () {
      expect(ferial(6, 'ot_26_0', 'ot_26_0', 'ot'), isFalse);
      expect(ferial(2, 'lent_2_0', 'lent_2_0', 'lent'), isFalse);
      expect(ferial(2, 'lent_0_3', 'lent_0_3', 'lent'), isFalse);
      expect(ferial(2, 'lent_6_2', 'lent_6_2', 'holyweek'), isFalse);
      expect(ferial(2, 'easter_1_2', 'easter_1_2', 'paschaloctave'), isFalse);
      expect(ferial(9, 'christmas_29', 'christmas_29', 'christmasoctave'),
          isFalse);
    });
  });
}
