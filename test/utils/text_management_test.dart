import 'package:aelf_flutter/utils/text_management.dart';
import 'package:flutter_test/flutter_test.dart';

/// `correctAelfHTML` is applied to every online liturgy payload before it is
/// handed to `extractVerses` / `flutter_html` (see `LiturgyPartContent`).
/// It only ever runs on API content, so it is squarely part of the online path
/// the offline work must not disturb.
void main() {
  group('capitalizeFirstLowerElse', () {
    test('upper-cases the first letter and lower-cases the rest', () {
      expect(capitalizeFirstLowerElse('LA FOI D\'ABRAHAM'), "La foi d'abraham");
    });

    test('null and empty degrade to an empty string', () {
      expect(capitalizeFirstLowerElse(null), '');
      expect(capitalizeFirstLowerElse(''), '');
    });
  });

  group('capitalizeFirst', () {
    test('upper-cases the first letter and leaves the rest alone', () {
      expect(capitalizeFirst('dimanche de la Pentecôte'),
          'Dimanche de la Pentecôte');
    });

    test('null and empty degrade to an empty string', () {
      expect(capitalizeFirst(null), '');
      expect(capitalizeFirst(''), '');
    });
  });

  group('removeAllHtmlTags', () {
    test('strips tags but keeps the text', () {
      expect(
        removeAllHtmlTags('<p>Au <strong>matin</strong>, tu écoutes.</p>'),
        'Au matin, tu écoutes.',
      );
    });

    test('leaves tag-free text untouched', () {
      expect(removeAllHtmlTags('Antienne simple'), 'Antienne simple');
    });
  });

  group('addAntienneBefore', () {
    test('prefixes a red "Antienne :" label and strips the markup', () {
      expect(
        addAntienneBefore('<p>Au matin, tu écoutes ma voix.</p>'),
        '<span class="red-text">Antienne : </span>Au matin, tu écoutes ma voix.',
      );
    });

    test('null and empty yield an empty string, so no label is shown', () {
      expect(addAntienneBefore(null), '');
      expect(addAntienneBefore(''), '');
    });
  });

  group('correctAelfHTML — liturgical symbols', () {
    test('V/ becomes the red versicle sign', () {
      expect(
        correctAelfHTML('<p>V/ Gloire au Père</p>'),
        contains('<span class="red-text">℣</span>'),
      );
    });

    test('R/ becomes the red response sign', () {
      expect(
        correctAelfHTML('<p>R/ Amen</p>'),
        contains('<span class="red-text">℟</span>'),
      );
    });

    test('a V/ sitting before the paragraph is pulled inside it', () {
      final out = correctAelfHTML('V/ <p>Gloire au Père</p>');
      expect(out, startsWith('<p><span class="red-text">℣</span>'));
    });

    test('an R/ sitting before the paragraph is pulled inside it', () {
      final out = correctAelfHTML('R/ <p>Amen</p>');
      expect(out, startsWith('<p><span class="red-text">℟</span>'));
    });

    test('a bold verse_number R/ loses its bold and becomes the red sign', () {
      final out = correctAelfHTML(
          '<p><strong><span class="verse_number">R/</span> </strong>Amen</p>');
      expect(out, contains('<span class="red-text"> ℟</span>'));
      expect(out, isNot(contains('<strong>')));
    });

    test('a plain verse_number R/ becomes the red sign', () {
      final out =
          correctAelfHTML('<p><span class="verse_number">R/</span> Amen</p>');
      expect(out, contains('red-text'));
      expect(out, contains('℟'));
      expect(out, isNot(contains('verse_number">R/')));
    });

    test('psalm pointing marks * and + are coloured red', () {
      final out =
          correctAelfHTML('<p>Dieu, tu es mon Dieu * je te cherche +</p>');
      expect(out, contains('<span class="red-text">*</span>'));
      expect(out, contains('<span class="red-text">+</span>'));
    });
  });

  group('correctAelfHTML — structure repair', () {
    test('a missing opening <p> is restored', () {
      final out =
          correctAelfHTML('<span class="verse_number">2</span> Écoute.');
      expect(out, startsWith('<p><span'));
    });

    test('a stray leading quote before <span> is repaired too', () {
      final out =
          correctAelfHTML('"<span class="verse_number">2</span> Écoute.');
      expect(out, startsWith('<p><span'));
    });

    test('content that already opens with <p> is left alone', () {
      final out = correctAelfHTML('<p><span class="x">a</span></p>');
      expect(out, startsWith('<p><span class="x">'));
      expect(out, isNot(startsWith('<p><p>')));
    });
  });

  group('correctAelfHTML — chapter.verse references', () {
    test('a chapter.verse number is split onto a new line', () {
      expect(correctAelfHTML('103.1'), '103,<br> 1');
    });

    test('every occurrence is rewritten', () {
      expect(correctAelfHTML('1.2 et 3.4'), '1,<br> 2 et 3,<br> 4');
    });

    test('a plain integer is untouched', () {
      expect(correctAelfHTML('<p>Psaume 118</p>'), '<p>Psaume 118</p>');
    });
  });

  test('correctAelfHTML leaves ordinary liturgy prose untouched', () {
    const input = '<p>Le Seigneur est mon berger : je ne manque de rien.</p>';
    expect(correctAelfHTML(input), input);
  });
}
