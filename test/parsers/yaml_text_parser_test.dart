import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// `YamlTextParser` renders the offline liturgy's markup — and, through the
/// shared `LiturgyPartTitle`, some online-origin widgets too. Its typography
/// substitutions (French thin spaces, curly apostrophes, the ℟ / ℣ signs) are
/// what make offline text look like the online HTML, so they are worth pinning.
void main() {
  List<String> textOf(List<YamlTextParagraph> paragraphs) => paragraphs
      .expand((p) => p.lines)
      .expand((l) => l.segments)
      .map((s) => s.text)
      .toList();

  String flatten(List<YamlTextParagraph> paragraphs) =>
      textOf(paragraphs).join();

  group('structure', () {
    test('empty content yields no paragraphs', () {
      expect(YamlTextParser.parseText(''), isEmpty);
    });

    test('a blank line starts a new paragraph', () {
      final paragraphs = YamlTextParser.parseText('Premier\n\nDeuxième');
      expect(paragraphs, hasLength(2));
      expect(flatten([paragraphs[0]]), contains('Premier'));
      expect(flatten([paragraphs[1]]), contains('Deuxième'));
    });

    test('single newlines split lines inside one paragraph', () {
      final paragraphs = YamlTextParser.parseText('Ligne un\nLigne deux');
      expect(paragraphs, hasLength(1));
      expect(paragraphs.single.lines, hasLength(2));
    });

    test('whitespace-only content yields no paragraphs', () {
      expect(YamlTextParser.parseText('   \n\n   '), isEmpty);
    });
  });

  group('French typography', () {
    test('an apostrophe becomes the typographic one', () {
      expect(flatten(YamlTextParser.parseText("l'Esprit")), 'l’Esprit');
    });

    test('a space before : ! ? ; becomes a narrow no-break space', () {
      // U+202F keeps the punctuation attached at the end of a line.
      expect(
          flatten(YamlTextParser.parseText('Ainsi : voici')), 'Ainsi : voici');
      expect(flatten(YamlTextParser.parseText('Vraiment !')), 'Vraiment !');
      expect(flatten(YamlTextParser.parseText('Pourquoi ?')), 'Pourquoi ?');
      expect(flatten(YamlTextParser.parseText('Donc ;')), 'Donc ;');
    });

    test('R/ and V/ become the liturgical signs', () {
      // At the start of a line the converted sign is then lifted into the
      // line's symbol column, so it leaves the text rather than staying in it.
      expect(
          YamlTextParser.parseText('R/ Amen').single.lines.single.leadingSymbol,
          '℟');
      expect(
          YamlTextParser.parseText('V/ Gloire')
              .single
              .lines
              .single
              .leadingSymbol,
          '℣');
    });

    test('a sign in the middle of a line stays in the text', () {
      expect(flatten(YamlTextParser.parseText('Gloire au Père R/ Amen')),
          contains('℟'));
    });
  });

  group('leading symbols move to their own column', () {
    test('a response sign is lifted out of the text', () {
      final line = YamlTextParser.parseText('℟ Alléluia').single.lines.single;
      expect(line.leadingSymbol, '℟');
      expect(line.segments.map((s) => s.text).join().trim(), 'Alléluia');
    });

    test('a versicle sign is lifted out too', () {
      final line = YamlTextParser.parseText('℣ Gloire').single.lines.single;
      expect(line.leadingSymbol, '℣');
    });

    test('a numbered response keeps its number', () {
      final line = YamlTextParser.parseText('℟1 Alléluia').single.lines.single;
      expect(line.leadingSymbol, '℟1');
    });

    test('an R/ written in ASCII is converted then lifted', () {
      final line = YamlTextParser.parseText('R/ Amen').single.lines.single;
      expect(line.leadingSymbol, '℟');
    });

    test('an asterisk is a leading symbol as well', () {
      final line = YamlTextParser.parseText('* Dieu').single.lines.single;
      expect(line.leadingSymbol, '*');
    });

    test('a line without one has no leading symbol', () {
      final line = YamlTextParser.parseText('Dieu, viens').single.lines.single;
      expect(line.leadingSymbol, isNull);
    });
  });

  group('inline markup', () {
    test('%...% marks a run italic', () {
      final segments = YamlTextParser.parseText('avant %milieu% après')
          .single
          .lines
          .single
          .segments;

      final italic = segments.where((s) => s.isItalic).map((s) => s.text);
      expect(italic.join(), contains('milieu'));
      final roman =
          segments.where((s) => !s.isItalic).map((s) => s.text).join();
      expect(roman, contains('avant'));
      expect(roman, contains('après'));
    });

    test('the markers themselves are consumed', () {
      expect(flatten(YamlTextParser.parseText('%italique%')),
          isNot(contains('%')));
    });

    test('[rubric]...[/rubric] marks a run as a rubric', () {
      final segments =
          YamlTextParser.parseText('texte [rubric]consigne[/rubric] suite')
              .single
              .lines
              .single
              .segments;

      expect(segments.where((s) => s.isRubric).map((s) => s.text).join(),
          contains('consigne'));
      expect(segments.where((s) => !s.isRubric).map((s) => s.text).join(),
          contains('texte'));
    });

    test('^ marks a superscript verse number', () {
      final segments = YamlTextParser.parseText('Dieu ^12 parla')
          .single
          .lines
          .single
          .segments;

      final superscripts =
          segments.where((s) => s.isSuperscript).map((s) => s.text).toList();
      expect(superscripts, ['12']);
    });

    test('a superscript can carry accented letters', () {
      final segments =
          YamlTextParser.parseText('Ps ^2a').single.lines.single.segments;
      expect(segments.where((s) => s.isSuperscript).map((s) => s.text), ['2a']);
    });
  });

  group('right indent', () {
    test('a leading > marks the line as indented and is removed', () {
      final line =
          YamlTextParser.parseText('> suite du verset').single.lines.single;

      expect(line.hasRightIndent, isTrue);
      expect(line.segments.map((s) => s.text).join(), isNot(contains('>')));
      expect(line.segments.map((s) => s.text).join(), contains('suite'));
    });

    test('an ordinary line is not indented', () {
      expect(
          YamlTextParser.parseText('verset').single.lines.single.hasRightIndent,
          isFalse);
    });
  });

  group('robustness', () {
    test('plain prose round-trips unchanged apart from typography', () {
      const input = 'Le Seigneur est mon berger.';
      expect(flatten(YamlTextParser.parseText(input)), input);
    });

    test('unbalanced markup does not throw', () {
      for (final input in ['%unbalanced', '[rubric]sans fin', '^', '>', '℟']) {
        expect(() => YamlTextParser.parseText(input), returnsNormally,
            reason: input);
      }
    });

    test('a realistic offline psalm verse parses into segments', () {
      final paragraphs = YamlTextParser.parseText(
          '℟ Dieu, tu es mon Dieu *\n> je te cherche dès l\'aube.');

      expect(paragraphs, hasLength(1));
      expect(paragraphs.single.lines, hasLength(2));
      expect(paragraphs.single.lines.first.leadingSymbol, '℟');
      expect(paragraphs.single.lines.last.hasRightIndent, isTrue);
      expect(flatten(paragraphs), contains('l’aube'));
    });
  });
}
