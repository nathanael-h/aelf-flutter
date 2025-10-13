String capitalizeFirstLowerElse(String? s) {
  if (s == null) {
    return "";
  } else if (s.isEmpty) {
    return "";
  } else {
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

String capitalizeFirst(String? s) {
  if (s == null) {
    return "";
  } else if (s.isEmpty) {
    return "";
  } else {
    return s[0].toUpperCase() + s.substring(1);
  }
}

String correctAelfHTML(String content) {
  // transform text elements for better displaying and change their color
  return content
      // Move verse and repons characters in the paragraph
      .replaceAll('V/ <p>', '<p>V/ ')
      .replaceAll('R/ <p>', '<p>R/ ')
      // Verse in red, and special character
      .replaceAll('V/', '<span class="red-text">℣</span>')
      // Remove bold for R/
      .replaceAll(
          RegExp(
              r'<strong><span class="verse_number">\W?R/</span>\W?</strong>|<span class="verse_number">R/</span>'),
          '<span class="red-text"> ℟</span>')

      // For repons, replace the class verse_number  OR 'R/' by red-text
      // and use the special character
      .replaceAll(RegExp('<span class="verse_number">R/</span>|R/'),
          '<span class="red-text">℟</span>')
      // Sometimes, the API misses the first <p>
      .replaceFirst(RegExp('^`?<span|^"?<span'), '<p><span')
      // * and + in red
      .replaceAll('*', '<span class="red-text">*</span>')
      .replaceAll('+', '<span class="red-text">+</span>')
      // Replace verse number in the form 'chapter_number.verse_number' by
      // 'chapter_number, <new line> verse_number'
      .replaceAllMapped(RegExp(r'(\d{1,3})(\.)(\d{1,3})'), (Match m) {
    return "${m[1]},<br> ${m[3]}";
  });
}

String removeAllHtmlTags(String htmlText) {
  RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  return htmlText.replaceAll(exp, '');
}

String addAntienneBefore(String? content) {
  if (content != "" && content != null) {
    return '<span class="red-text">Antienne : </span>${removeAllHtmlTags(content)}';
  }
  return "";
}
