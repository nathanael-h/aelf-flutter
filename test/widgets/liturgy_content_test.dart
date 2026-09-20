import 'package:aelf_flutter/utils/text_management.dart';
import 'package:aelf_flutter/widgets/liturgy_content.dart';
import 'package:flutter_test/flutter_test.dart';

/// `extractVerses` splits the online AELF HTML into `verse number -> html`
/// so `LiturgyPartContent` can lay each verse out next to its `BibleVerseId`.
/// A regression here silently breaks the whole online liturgy layout.
void main() {
  group('extractVerses — numbered verses', () {
    test('splits a paragraph on its verse_number spans', () {
      final verses = extractVerses(
        '<p><span class="verse_number">2</span> Écoute mes paroles, Seigneur.'
        '<span class="verse_number">3</span> Entends ma plainte.</p>',
      );
      expect(verses.keys, ['2', '3']);
      expect(verses['2'], 'Écoute mes paroles, Seigneur.');
      expect(verses['3'], 'Entends ma plainte.');
    });

    test('keeps verse order across several paragraphs', () {
      final verses = extractVerses(
        '<p><span class="verse_number">1</span> Premier.</p>'
        '<p><span class="verse_number">2</span> Deuxième.</p>',
      );
      expect(verses.keys.toList(), ['1', '2']);
    });

    test('collapses runs of whitespace inside a verse', () {
      final verses = extractVerses(
          '<p><span class="verse_number">1</span>   Le   Seigneur \n est là.</p>');
      expect(verses['1'], 'Le Seigneur est là.');
    });

    test('non-integer verse ids (1a, 6ab) are preserved as given', () {
      final verses = extractVerses(
        '<p><span class="verse_number">1ab</span> Bénis le Seigneur.'
        '<span class="verse_number">6ac</span> Que tes œuvres sont nombreuses.</p>',
      );
      expect(verses.keys, ['1ab', '6ac']);
    });

    test('inline markup inside a verse is kept as html', () {
      final verses = extractVerses(
        '<p><span class="verse_number">1</span> Dieu, <strong>tu es</strong> mon Dieu.</p>',
      );
      expect(verses['1'], contains('<strong>tu es</strong>'));
    });
  });

  group('extractVerses — unnumbered content', () {
    test('content with no verse_number is returned whole under an empty key',
        () {
      const html = '<p>Dieu, viens à mon aide.</p>';
      final verses = extractVerses(html);
      expect(verses, {'': html});
    });

    test('a leading response before the first verse is kept under " "', () {
      final verses = extractVerses(
        '<p><span class="red-text">℟</span> Alléluia.'
        '<span class="verse_number">1</span> Bénis le Seigneur.</p>',
      );
      expect(verses.keys, containsAll(<String>[' ', '1']));
      expect(verses[' '], contains('Alléluia.'));
      expect(verses['1'], 'Bénis le Seigneur.');
    });
  });

  group('extractVerses — real online payload', () {
    test('survives the correctAelfHTML output it is always fed', () {
      // This is the exact pipeline LiturgyPartContent runs:
      //   extractVerses(correctAelfHTML(content))
      const raw =
          '<p><span class="verse_number">2</span> Dieu, tu es mon Dieu * '
          'je te cherche dès l\'aube.<span class="verse_number">3</span> '
          'R/ Ton amour vaut mieux que la vie.</p>';
      final verses = extractVerses(correctAelfHTML(raw));

      expect(verses.keys, ['2', '3']);
      expect(verses['2'], contains('<span class="red-text">*</span>'));
      expect(verses['3'], contains('℟'));
    });

    test('an office part with no verse numbers renders as one block', () {
      const raw = '<p>Notre Père, qui es aux cieux.</p>';
      final verses = extractVerses(correctAelfHTML(raw));
      expect(verses, hasLength(1));
      expect(verses.values.single, contains('Notre Père'));
    });
  });
}
