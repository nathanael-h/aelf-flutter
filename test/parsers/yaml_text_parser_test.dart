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
          YamlTextParser.responseGlyph);
      expect(
          YamlTextParser.parseText('V/ Gloire')
              .single
              .lines
              .single
              .leadingSymbol,
          YamlTextParser.versicleGlyph);
    });

    test('a sign in the middle of a line stays in the text', () {
      expect(flatten(YamlTextParser.parseText('Gloire au Père R/ Amen')),
          contains(YamlTextParser.responseGlyph));
    });
  });

  group('leading symbols move to their own column', () {
    // R/, V/ (and their numbered variants) are the only authored forms:
    // _applyTypography pre-substitutes them to private-use glyphs rendered
    // through the LiturgicalSymbols font, and only those glyphs are
    // recognized as leading symbols — a bare ℟/℣ typed directly is not
    // (real content always uses the R/, V/ shorthand).
    test('a response sign is lifted out of the text', () {
      final line = YamlTextParser.parseText('R/ Alléluia').single.lines.single;
      expect(line.leadingSymbol, YamlTextParser.responseGlyph);
      expect(line.segments.map((s) => s.text).join().trim(), 'Alléluia');
    });

    test('a versicle sign is lifted out too', () {
      final line = YamlTextParser.parseText('V/ Gloire').single.lines.single;
      expect(line.leadingSymbol, YamlTextParser.versicleGlyph);
    });

    test('a numbered response keeps its number', () {
      final line = YamlTextParser.parseText('R/1 Alléluia').single.lines.single;
      expect(line.leadingSymbol, '${YamlTextParser.responseGlyph}1');
    });

    test('an R/ written in ASCII is converted then lifted', () {
      final line = YamlTextParser.parseText('R/ Amen').single.lines.single;
      expect(line.leadingSymbol, YamlTextParser.responseGlyph);
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

      expect(line.indentLevel, greaterThan(0));
      expect(line.segments.map((s) => s.text).join(), isNot(contains('>')));
      expect(line.segments.map((s) => s.text).join(), contains('suite'));
    });

    test('an ordinary line is not indented', () {
      expect(YamlTextParser.parseText('verset').single.lines.single.indentLevel,
          0);
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
          'R/ Dieu, tu es mon Dieu *\n> je te cherche dès l\'aube.');

      expect(paragraphs, hasLength(1));
      expect(paragraphs.single.lines, hasLength(2));
      expect(paragraphs.single.lines.first.leadingSymbol,
          YamlTextParser.responseGlyph);
      expect(paragraphs.single.lines.last.indentLevel, greaterThan(0));
      expect(flatten(paragraphs), contains('l’aube'));
    });
  });

  group('display style', () {
    test('the classic display keeps the calligraphic R/ and V/', () {
      expect(YamlTextParser.glyphFor(YamlTextParser.responseGlyph),
          YamlTextParser.responseGlyph);
      expect(YamlTextParser.glyphFor(YamlTextParser.versicleGlyph),
          YamlTextParser.versicleGlyph);
    });

    test('the modern display swaps R/ and V/ for their sans-serif forms', () {
      expect(
          YamlTextParser.glyphFor(YamlTextParser.responseGlyph, classic: false),
          YamlTextParser.responseSansGlyph);
      expect(
          YamlTextParser.glyphFor(YamlTextParser.versicleGlyph, classic: false),
          YamlTextParser.versicleSansGlyph);
    });

    test('the mediant and flex marks are the same in both displays', () {
      for (final classic in [true, false]) {
        expect(YamlTextParser.glyphFor('*', classic: classic),
            YamlTextParser.starGlyph);
        expect(YamlTextParser.glyphFor('+', classic: classic),
            YamlTextParser.daggerGlyph);
      }
    });
  });

  group('initial letter', () {
    List<YamlTextSegment> firstLine(String text) =>
        YamlTextParser.withInitialLetter(YamlTextParser.parseText(text))
            .first
            .lines
            .first
            .segments;
    String? initialOf(String text) {
      final initials = firstLine(text).where((s) => s.isInitial);
      return initials.isEmpty ? null : initials.single.text;
    }

    test('the first letter is split off and marked', () {
      final segments = firstLine('Frères, soyez dans la joie.');
      expect(segments.map((s) => s.text), ['F', 'rères, soyez dans la joie.']);
      expect(segments.first.isInitial, isTrue);
      expect(segments.last.isInitial, isFalse);
    });

    test('an opening quote keeps its size, the letter after it is marked', () {
      final segments = firstLine('« Heureux les pauvres »');
      expect(segments.map((s) => s.text).take(2), ['« ', 'H']);
      expect(segments[1].isInitial, isTrue);
    });

    test('a leading verse number is skipped', () {
      expect(initialOf('^1 Au commencement'), 'A');
    });

    String? initialIn(String text) {
      final initials =
          YamlTextParser.withInitialLetter(YamlTextParser.parseText(text))
              .expand((p) => p.lines)
              .expand((l) => l.segments)
              .where((s) => s.isInitial);
      return initials.isEmpty ? null : initials.single.text;
    }

    test('a line holding a rubric is skipped', () {
      expect(
          initialIn('[rubric](Stance)[/rubric]\nReviens, Verbe de Dieu'), 'R');
      expect(initialIn('[rubric]Lecture[/rubric] brève\nFrères'), 'F');
    });

    test(
        'a rubric line followed by a blank line hands over to the next paragraph',
        () {
      expect(initialIn('[rubric](Stance)[/rubric]\n\nSaisis de joie'), 'S');
    });

    test('a leading source in italic parentheses is skipped', () {
      expect(initialIn('%(Enarr in ps. 126, 2-3)%\nSi le Seigneur'), 'S');
    });

    test('a source spread over several lines is skipped as a whole', () {
      expect(
          initialIn('%(Les propos de saint Louis,\n'
              'édit. D. O’Connel, Paris, 1974, pp. 185-191)%\n'
              'Cher fils, je te demande'),
          'C');
    });

    test('text following the source on its closing line takes the initial', () {
      expect(initialIn('%(Source)% Comment proclamer'), 'C');
    });

    test('italic text that is not a source keeps the initial', () {
      expect(initialIn('%Voici% le serviteur'), 'V');
    });

    test('the letter keeps the italic of its run', () {
      final initial = firstLine('%Voici%').firstWhere((s) => s.isInitial);
      expect(initial.isItalic, isTrue);
    });

    test('only one letter is marked, in the first paragraph', () {
      final paragraphs = YamlTextParser.withInitialLetter(
          YamlTextParser.parseText('Premier.\n\nSecond.'));
      final marked = paragraphs
          .expand((p) => p.lines)
          .expand((l) => l.segments)
          .where((s) => s.isInitial);
      expect(marked.map((s) => s.text), ['P']);
    });

    test('a first line without letter is left unchanged', () {
      expect(initialOf('« 12 »'), isNull);
      expect(YamlTextParser.withInitialLetter([]), isEmpty);
    });

    test('the text is unchanged once the segments are joined', () {
      const text = '« Heureux, ^3 vous les pauvres »';
      String join(List<YamlTextParagraph> p) => p
          .expand((p) => p.lines)
          .expand((l) => l.segments)
          .map((s) => s.text)
          .join();
      final parsed = YamlTextParser.parseText(text);
      expect(join(YamlTextParser.withInitialLetter(parsed)), join(parsed));
    });
  });
}
