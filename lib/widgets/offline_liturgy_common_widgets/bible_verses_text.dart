import 'package:flutter/material.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/utils/bible_language.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/bible_text_language_variant.dart';

/// Renders [verses] (from the package's `bibleVerses`) as flowing text with
/// each verse's number shown as a small raised digit before it — the
/// original-language convention, unlike the French liturgical translation
/// shown everywhere else in the app, which has none. A segment boundary
/// within the reference (an empty-label verse whose text is the omission
/// mark '~' — see `bibleVerses`) breaks the paragraph, mirroring how
/// `bibleText` joins its own segments.
///
/// Deliberately not built on [YamlTextFromString]: that widget's drop-cap
/// first letter is a French liturgical typographic convention that doesn't
/// apply to a numbered original-language text.
class BibleVersesText extends StatelessWidget {
  final List<BibleVerse> verses;
  final BibleLanguage language;
  final double zoom;
  final TextAlign textAlign;

  const BibleVersesText({
    super.key,
    required this.verses,
    required this.language,
    this.zoom = 100,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context)
        .style
        .merge(bibleVerseStyleFor(language, zoom));
    final numberStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 16.0 * zoom / 100) * 0.6,
      color: Theme.of(context).colorScheme.secondary,
    );

    final spans = <InlineSpan>[];
    for (final verse in verses) {
      if (verse.verse.isEmpty) {
        // The segment-boundary marker ('~') between non-contiguous ranges.
        if (verse.text.isNotEmpty) {
          spans.add(TextSpan(text: ' ${verse.text}\n\n', style: baseStyle));
        }
        continue;
      }
      // Raised above the baseline (not just shrunk: PlaceholderAlignment.top
      // alone sits near the line's leading, not visibly above the text) and
      // glued to the next word — no space, so a line can never break
      // between the number and what follows.
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Transform.translate(
          offset: Offset(0, -(baseStyle.fontSize ?? 16.0 * zoom / 100) * 0.35),
          child: Text(verse.verse, style: numberStyle),
        ),
      ));
      spans.add(TextSpan(text: '${verse.text.trim()} ', style: baseStyle));
    }

    return Text.rich(TextSpan(children: spans), textAlign: textAlign);
  }
}
